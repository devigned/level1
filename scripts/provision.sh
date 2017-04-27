#!/usr/bin/env bash

set -eux

group_id="level1"
location="westus"
keyvault_name_prefix="level1"
keyvault_name=$(echo $(mktemp -u ${keyvault_name_prefix}XXXXX) | tr '[:upper:]' '[:lower:]')
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

existing_name=$(az keyvault list --query "[?starts_with(name, '${keyvault_name_prefix}') && resourceGroup == '${group_id}'] | [0].name" -o tsv)
if [[ -z "${existing_name}" ]]; then
    echo "Creating Azure Key Vault ${keyvault_name} in group ${group_id} enabled for use in VM deployment"
    az keyvault create -g ${group_id} -n ${keyvault_name} --enabled-for-deployment 1>/dev/null
    existing_name="${keyvault_name}"
else
    echo "Using existing Azure Key Vault ${existing_name} in group ${group_id}"
fi

if [[ -z "$(az keyvault certificate show --vault-name ${existing_name} -n ${cert_name})" ]]; then
    echo "Create the service principal certificate in Key Vault, so the certificate private bits only ever exist in Key Vault and the VM"
    az keyvault certificate create --vault-name ${existing_name} -n ${cert_name} --validity 24 -p "$(az keyvault certificate get-default-policy)" 1>/dev/null
else
    echo "Using the already provisioned Key Vault certificate ${cert_name}"
fi

if [[ ! -z "$(az ad sp show --id http://${sp_name})" ]]; then
    az ad app delete --id "http://${sp_name}" 1>/dev/null
fi

echo "Generate a service principal for use by the Azure CLI in the provisioned VM to fetch connection strings"
rm -f "${cert_name}.pem"
az keyvault certificate download --vault-name ${existing_name} -n ${cert_name} -f "${cert_name}.pem" 1>/dev/null
az ad sp create-for-rbac -n ${sp_name} --cert "@${cert_name}.pem"  1>/dev/null

if [[ "$(az vm show -g ${group_id} -n ${vm_name} --query "provisioningState=='Success'")" == 'false' ]]; then
    secret=$(az keyvault secret list-versions --vault-name ${existing_name} -n ${cert_name} --query "[?attributes.enabled].id" -o tsv)
    vm_secret=$(az vm format-secret -s "${secret}")
    echo "Creating VM with provisioned Key Vault secret (certificate use for service principal auth)"
    tenant="$(az account show --query 'tenantId' -o tsv)"
    fingerprint="$(az keyvault certificate show --vault-name ${existing_name} -n ${cert_name} --query "x509ThumbprintHex" -o tsv)"
    sed -- "s/{{ tenant }}/${tenant}/g;s/{{ username }}/http:\/\/${sp_name}/g;s/{{ fingerprint }}/${fingerprint}/g" scripts/cloud-config-template.yml > "${DIR}/cloud-config.yml"
    az vm create -g ${group_id} -n ${vm_name} --admin-username deploy --image UbuntuLTS --secrets "$vm_secret" --custom-data "${DIR}/cloud-config.yml" 1>/dev/null
    az vm open-port -g ${group_id} -n ${vm_name} --port 80 1>/dev/null
else
    echo "Using existing VM ${vm_name} in group ${group_id}, which has already been provisioned with a Key Vault secret (certificate use for service principal auth)"
fi


echo "SSH into the VM: ssh deploy@$(az vm show -d -g level1 -n level1-vm --query 'publicIps' -o tsv)"





