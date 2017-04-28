#!/usr/bin/env bash

set -eux

group_id="level1"
location="westus"
name_prefix="level1"
new_name=$(echo $(mktemp -u ${name_prefix}XXXXX) | tr '[:upper:]' '[:lower:]')
cert_name="sp-cert-level1"
sp_name="level1-sp"
vm_name="level1-vm"
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
    echo "Creating Azure Key Vault ${new_name} in group ${group_id} enabled for use in VM deployment"
    az keyvault create -g ${group_id} -n ${new_name} --enabled-for-deployment 1>/dev/null
    vault_name="${new_name}"
else
    echo "Using existing Azure Key Vault ${vault_name} in group ${group_id}"
fi

if [[ -z "$(az keyvault certificate show --vault-name ${vault_name} -n ${cert_name})" ]]; then
    echo "Create the service principal certificate in Key Vault, so the certificate private bits only ever exist in Key Vault and the VM"
    az keyvault certificate create --vault-name ${vault_name} -n ${cert_name} --validity 24 -p "$(az keyvault certificate get-default-policy)" 1>/dev/null
    echo "Create Rails secret which will be used from within the secrets.yml (don't use this secret...)"
    az keyvault secret set --vault-name ${vault_name} --name 'level1-secret-key-base' --value "1d479fcab5b6d0aaf8689bf5b5ae81724b794f1e60c8d86827566c88096b1adf7c6c0505734cacdfd83ec3bb4090443bc1b8153937a8bdf1c7fafdd13a984993"
else
    echo "Using the already provisioned Key Vault certificate ${cert_name}"
fi

docdb_name=$(az documentdb list -g ${group_id} --query "[?starts_with(name, '${name_prefix}')] | [0].name" -o tsv)
if [[ -z "${docdb_name}" ]]; then
    echo "Create DocDB instance named ${new_name} with MongoDB wire format to be used by Rails Mongoid"
    az documentdb create -g ${group_id} -n ${new_name} --kind MongoDB 1>/dev/null
else
    echo "Using the already provisioned DocDB named ${docdb_name}"
fi

if [[ ! -z "$(az ad sp show --id http://${sp_name})" ]]; then
    az ad app delete --id "http://${sp_name}" 1>/dev/null
fi

echo "Generate a service principal for use by the Azure CLI in the provisioned VM to fetch connection strings"
rm -f "${cert_name}.pem"
az keyvault certificate download --vault-name ${vault_name} -n ${cert_name} -f "${cert_name}.pem" 1>/dev/null
az ad sp create-for-rbac -n ${sp_name} --cert "@${cert_name}.pem"  1>/dev/null

echo "Provide the newly created Azure Active Directory application and service principal access to read Key Vault secrets"
az keyvault set-policy --n ${vault_name} --object-id "$(az ad sp show --id http://level1-sp --query "objectId" -o tsv)" --secret-permissions get 1>/dev/null

if [[ "$(az vm show -g ${group_id} -n ${vm_name} --query "provisioningState=='Success'")" == 'false' ]]; then
    secret=$(az keyvault secret list-versions --vault-name ${vault_name} -n ${cert_name} --query "[?attributes.enabled].id" -o tsv)
    vm_secret=$(az vm format-secret -s "${secret}")
    echo "Creating VM with provisioned Key Vault secret (certificate use for service principal auth)"
    tenant="$(az account show --query 'tenantId' -o tsv)"
    fingerprint="$(az keyvault certificate show --vault-name ${vault_name} -n ${cert_name} --query "x509ThumbprintHex" -o tsv)"
    sed -- "s/{{ tenant }}/${tenant}/g;s/{{ username }}/http:\/\/${sp_name}/g;s/{{ fingerprint }}/${fingerprint}/g" scripts/cloud-config-template.yml > "${DIR}/cloud-config.yml"
    az vm create -g ${group_id} -n ${vm_name} --admin-username deploy --image UbuntuLTS --secrets "$vm_secret" --custom-data "${DIR}/cloud-config.yml" 1>/dev/null
    az vm open-port -g ${group_id} -n ${vm_name} --port 80 1>/dev/null
else
    echo "Using existing VM ${vm_name} in group ${group_id}, which has already been provisioned with a Key Vault secret (certificate use for service principal auth)"
fi


echo "SSH into the VM: ssh deploy@$(az vm show -d -g level1 -n level1-vm --query 'publicIps' -o tsv)"





