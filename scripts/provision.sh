#!/usr/bin/env bash

# add 'x' to the set command to see verbose output from each of the statements
set -eu

group_id="level1"
location="westus"
name_prefix="level1"
# shellcheck disable=SC2005
new_name=$(echo "$(mktemp -u ${name_prefix}XXXXX)" | tr '[:upper:]' '[:lower:]') 
cert_name="sp-cert-level1"
sp_name="level1-sp"
vmss_name="level1-vmss"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Login if you haven't already
if [[ -z $(az account list -o tsv 2>/dev/null ) ]]; then
    az login -o table
fi
echo ""

if [[ -z $(az group show -n ${group_id}) ]]; then
    echo "Creating Resource Group named ${group_id}"
    az group create -n ${group_id} -l ${location} 1>/dev/null
else 
    echo "Using Resource Group name ${group_id}"
fi

vault_name=$(az keyvault list -g ${group_id} --query "[?starts_with(name, '${name_prefix}')] | [0].name" -o tsv)
if [[ -z "${vault_name}" ]]; then
    echo "Creating Azure Key Vault ${new_name} in group ${group_id} enabled for use in VMSS deployment"
    az keyvault create -g "${group_id}" -n "${new_name}" --enabled-for-deployment 1>/dev/null
    vault_name="${new_name}"
else
    echo "Using existing Azure Key Vault ${vault_name} in group ${group_id}"
fi

if [[ -z "$(az keyvault certificate show --vault-name "${vault_name}" -n ${cert_name})" ]]; then
    echo "Create the service principal certificate in Key Vault, so the certificate private bits only ever exist in Key Vault and the VMSS"
    az keyvault certificate create --vault-name "${vault_name}" -n ${cert_name} --validity 24 -p "$(az keyvault certificate get-default-policy)" 1>/dev/null
    echo "Create Rails secret which will be used from within the secrets.yml (don't use this secret...)"
    az keyvault secret set --vault-name "${vault_name}" --name 'level1-secret-key-base' \
        --value "1d479fcab5b6d0aaf8689bf5b5ae81724b794f1e60c8d86827566c88096b1adf7c6c0505734cacdfd83ec3bb4090443bc1b8153937a8bdf1c7fafdd13a984993" 1>/dev/null
else
    echo "Using the already provisioned Key Vault certificate ${cert_name}"
fi

cosmosdb_name=$(az cosmosdb list -g ${group_id} --query "[?starts_with(name, '${name_prefix}')] | [0].name" -o tsv)
if [[ -z "${cosmosdb_name}" ]]; then
    echo "Create CosmosDB instance named ${new_name} with MongoDB wire format to be used by Rails Mongoid"
    az cosmosdb create -g ${group_id} -n "${new_name}" --kind MongoDB 1>/dev/null
else
    echo "Using the already provisioned CosmosDB named ${cosmosdb_name}"
fi

if [[ ! -z "$(az ad sp show --id http://${sp_name})" ]]; then
    az ad app delete --id "http://${sp_name}" 1>/dev/null
fi

echo "Generate a service principal for use by the Azure CLI in the provisioned VM to fetch connection strings"
rm -f "${cert_name}.pem"
az keyvault certificate download --vault-name "${vault_name}" -n ${cert_name} -f "${cert_name}.pem" 1>/dev/null
az ad sp create-for-rbac -n ${sp_name} --cert "@${cert_name}.pem"  1>/dev/null

echo "Provide the newly created Azure Active Directory application and service principal access to read Key Vault secrets"
az keyvault set-policy --n "${vault_name}" --object-id "$(az ad sp show --id http://${sp_name} --query "objectId" -o tsv)" --secret-permissions get 1>/dev/null

if [[ -z "$(az network public-ip show -g ${group_id} -n ${vmss_name} --query "dnsSettings.fqdn" -o tsv)" ]]; then
    secret=$(az keyvault secret list-versions --vault-name "${vault_name}" -n ${cert_name} --query "[?attributes.enabled].id" -o tsv)
    vm_secret=$(az vm format-secret -s "${secret}")
    echo "Creating three instance VM Scale Set with provisioned Key Vault secret (certificate use for service principal auth)"
    tenant="$(az account show --query 'tenantId' -o tsv)"
    fingerprint="$(az keyvault certificate show --vault-name "${vault_name}" -n ${cert_name} --query "x509ThumbprintHex" -o tsv)"
    sed -- "s/{{ tenant }}/${tenant}/g;s/{{ username }}/http:\/\/${sp_name}/g;s/{{ fingerprint }}/${fingerprint}/g" scripts/cloud-config-template.yml > "${DIR}/cloud-config.yml"
    az vmss create -g ${group_id} -n ${vmss_name} --instance-count 3 --admin-username deploy --image UbuntuLTS --secrets "$vm_secret" \
        --custom-data "${DIR}/cloud-config.yml" --public-ip-address-dns-name "${new_name}" --public-ip-address ${vmss_name} --lb ${vmss_name} 1>/dev/null

    echo "Creating load balancer health probe for HTTP traffic on the root of the web application"
    az network lb probe create -g ${group_id} -n root-http-probe --lb-name ${vmss_name} --port 80 --protocol Http --path / 1>/dev/null

    echo "Creating load balancer rule to route HTTP traffic from the frontend IP on port 80 to the backend pool on port 80"
    frontend_ip_confg_name=$(az network lb show -g ${group_id} -n ${vmss_name} --query "frontendIpConfigurations[0].name" -o tsv)
    backend_pool_name=$(az network lb show -g ${group_id} -n ${vmss_name} --query "backendAddressPools[0].name" -o tsv)
    az network lb rule create -g ${group_id} --lb-name ${vmss_name} -n http-traffic-rule --protocol Tcp \
        --frontend-ip-name "${frontend_ip_confg_name}" --frontend-port 80 --backend-pool-name "${backend_pool_name}" --backend-port 80
else
    echo "Using existing VM Scale Set ${vmss_name} in group ${group_id}, which has already been provisioned with a Key Vault secret (certificate use for service principal auth)"
fi

if [[ -z "$(az cdn endpoint list -g ${group_id} --profile-name ${group_id} --query "[?starts_with(name, '${name_prefix}')] | [0].name" -o tsv)" ]]; then
    echo "Create CDN profile named ${group_id} and endpoint named ${new_name} which will provide edge content nodes using Akamai (Verizon is also supported)"
    az cdn profile create -g ${group_id} -n ${group_id} 1>/dev/null
    vmss_fqdn=$(az network public-ip show -g ${group_id} -n ${vmss_name} --query "dnsSettings.fqdn" -o tsv)
    az cdn endpoint create -g "${group_id}" -n "${new_name}" --profile-name "${group_id}" --origin "${vmss_fqdn}" 1>/dev/null
    cdn_name=${new_name}
else
    cdn_name=$(az cdn endpoint list -g ${group_id} --profile-name ${group_id} --query "[?starts_with(name, '${name_prefix}')] | [0].name" -o tsv)
    echo "Using the already provisioned CDN profile named ${group_id} and endpoint named ${cdn_name}"
fi

echo "-------------"
echo "Scale set is publically exposed on 80 via FQDN: $(az network public-ip show -g ${group_id} -n ${vmss_name} --query "dnsSettings.fqdn" -o tsv)"
echo "CDN is fronting the load balanced Scale Set via $(az cdn endpoint show -g "${group_id}" -n "${cdn_name}" --profile-name "${group_id}" --query "hostName" -o tsv)"
echo "You can SSH into the VM Scale Set instances via the following IP and port combinations:"
for conn_string in $(az vmss list-instance-connection-info -g ${group_id} -n ${vmss_name} -o tsv); do echo "ssh deploy@$(echo "${conn_string}" | sed -- s/:/' -p '/g)"; done
echo "-------------"




