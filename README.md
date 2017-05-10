# Level 1: Deploy Azure Rails and Ember Todo App

As part of a blog series on deploying a Rails applications on Azure with increasing levels of DevOps maturity. 
See: todo:add_link

This Todo app runs an ember frontend which depends on a Rails backend. It illustrates the scripted level of 
DevOps maturity (Level 1).

## Required Tools
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [jq](https://stedolan.github.io/jq/)
- Ruby / Rails
- Node.js

## [Rails](./api-ruby)
- [Mongoid](https://github.com/mongodb/mongoid)
- Rails API Stack
- Active Model Serializers for JSONAPI serialization

### Routes
- /api/v1/todo_lists
- /api/v1/todo_items

## [Ember](./api-ruby/todo-ember)
- Standard

## Azure Functionality Used:
- Azure CLI
- Azure Virtual Machines
  - Key Vault Secrets
  - Custom Script Extension
- Azure Document DB
- Azure Key Vault
- Azure Active Directory Service Principal
- (optional) Azure Scale Sets

## How to run this sample
- Clone the repo and `cd` into the root of the repo
- Run `./scripts/provision`. This will build all of the Azure infrastructure.
  - change `set -eu` in `./scripts/provision` to `set -eux` if you'd like see verbose / debug script output.
- From the root of the repo, `cd api-ruby`.
- Run `bundle exec cap production deploy:initial`. This will deploy the Ember / Rails Todo application to your Azure infrastructure.
- Run `echo http://$(az network public-ip show -g level1 -n level1-vmss --query 'dnsSettings.fqdn' -o tsv)` to get th