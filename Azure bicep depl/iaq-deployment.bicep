@description('The name of the environment. This must be either dev or prod, with dev set as default. Currently it has no other implications outside of naming resources.')
@allowed([
  'dev'
  'prod'
])
param environmentName string = 'dev'

@description('The Azure region into which the resources should be deployed. Defaults to West Europe')
param location string = 'West Europe'

@description('Same name is used for creating the database and for functions that use it as configuration.')
param containerName string = 'measurements'

@description('Same name is used for creating the database and for functions that use it as configuration.')
param dbName string = 'indoor_airquality'

@description('Name for the storage account container, which will house the .csv-files')
param blobContainerName string = 'measurements'

@description('The unique name of the solution. This is used to ensure that resource names are unique.')
var solutionName = 'iaq${uniqueString(resourceGroup().id)}'

var storageAccountName = '${environmentName}${solutionName}'
var serviceBusName = '${environmentName}-${solutionName}-bus'
var serviceBusAuthRuleName = 'RootManageSharedAccessKey'
var serviceBusQueueName = 'bus-queue'
var serviceBusQueueAuthRuleName = 'iothubroutes_IAQ'
var hostingPlanName = 'iaq${uniqueString(resourceGroup().id)}-hosting'
var appInsightsName = 'iaq${uniqueString(resourceGroup().id)}-appInsights'
var iotHubName = 'iaq${uniqueString(resourceGroup().id)}-iot-hub'

module storageAccount 'modules/storage-account.bicep' = {
  name: 'storageAccount-depl'
  params: {
    location: location
    storageAccountName: storageAccountName
    containerName: blobContainerName
  }
}

module cosmosDb 'modules/cosmosdb.bicep' = {
  name: 'cosmosDb-depl'
  params: {
    solutionName: solutionName
    environmentName: environmentName
    containerName: containerName
    dbName: dbName
  }
}

module queue 'modules/service-bus-queue.bicep' = {
  name: 'queue-depl'
  params: {
    location: location
    queueAuthRuleName: serviceBusQueueAuthRuleName
    queueName: serviceBusQueueName
    serviceBusAuthRuleName: serviceBusAuthRuleName
    serviceBusName: serviceBusName
  }
}

module functions 'modules/functions.bicep' = {
  name: 'funcs-depl'
  params: {
    cosmosDatabaseAccountName: cosmosDb.outputs.cosmosDbAccountName
    csvDataLakeWriterName: '${environmentName}-${solutionName}-csvWriter'
    location: location
    measurementInsertName: '${environmentName}-${solutionName}-inserter'
    storageAccountApiVersion: storageAccount.outputs.storageAccountApi
    storageAccountId: storageAccount.outputs.storageAccountId
    storageAccountName: storageAccount.outputs.storageAccountName
    appInsightsName: appInsightsName
    hostingPlanName: hostingPlanName
    busName: queue.outputs.BusName
    serviceBusAuthRuleApiVersion: queue.outputs.serviceBusAuthApiVersion
    serviceBusAuthRuleName: queue.outputs.serviceBusAuthName
    cosmosDatabaseAccountApiVersion: cosmosDb.outputs.cosmosDbAccountApiVersion
    blobContainerName: blobContainerName
    containerName: containerName
    dbName: dbName
    queueName: queue.outputs.queueName
  }
}

module iotHub 'modules/iot-hub.bicep' = {
  name: 'iotHub-depl'
  params: {
    iotHubName: iotHubName 
    location: location
    busName: queue.outputs.BusName
    serviceBusQueueAuthRuleName: queue.outputs.serviceBusQueueAuthName
    serviceBusQueueAuthRuleApiVersion: queue.outputs.serviceBusQueueAuthApiVersion
    queueName: queue.outputs.queueName
  }
}
