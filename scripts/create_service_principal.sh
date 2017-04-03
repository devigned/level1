#!/usr/bin/env bash

set -eux

group_id="level1"
location="westus"
keyvault_name_prefix="level1"
keyvault_name=$(echo $(mktemp -u ${keyvault_name_prefix}XXXXX) | tr '[:upper:]' '[:lower:]')
cert_name="sp-cert-level1"

# Login if you haven't already
if [[ -z $(az account list -o tsv 2>/dev/null ) ]]; then
    az login -o table
fi
echo ""

# JSON output from the following command:
#{
#  "appId": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
#  "displayName": "some-display-name",
#  "fileWithCertAndPrivateKey": "/Users/user/tmpzlqjnv65.pem",
#  "name": "http://azure-cli-2017-04-03-15-30-52",
#  "password": null,
#  "tenant": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
#}
service_principal=$(az ad sp create-for-rbac --create-cert)
cert_file=$(echo $service_principal | jq .fileWithCertAndPrivateKey -r)

existing_name=$(az keyvault list -g ${group_id} --query "[?starts_with(name, ${keyvault_name_prefix})] | [0].name" -o tsv)
if [[ -z existing_name ]]; then
    echo "Creating Resource group named ${group_id}"
    az group create -n ${group_id} -l ${location} 1>/dev/null

    echo "Creating Azure Key Vault ${keyvault_name} in group ${group_id}"
    az keyvault create -g ${group_id} -n ${keyvault_name} 1>/dev/null
    existing_name=keyvault_name
else
    echo "Using existing Azure Key Vault ${existing_name} in group ${group_id}"
fi

