Steps to deploy (in a nutshell):

1. Login and set your default subscription (https://docs.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli)

2. Create your resource group 'az group create --location "West Europe" --name testGroup'

3. Create a deployment into said resource group with: 'az deployment group create --template-file iaq-deployment.bicep --resource-group testGroup'
