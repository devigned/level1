# Todo JSONAPI

This Rails application provides a JSONAPI todo list and todo item implementation backed
by MongoDB and in Azure, DocumentDB via MongoDB bindings.


## To Run Locally
- `bundle install`
- `bundle exec rails server`

## To Provision an Azure Environment
- `bundle exec rake provision`

## To Deploy to Azure (must provision first)
- `bundle exec rake deploy`
