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

## [Ember](./todo-ember)
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