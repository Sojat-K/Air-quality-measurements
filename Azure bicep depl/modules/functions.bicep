param storageAccountName string
param csvDataLakeWriterName string
param location string
param storageAccountId string
param storageAccountApiVersion string
param measurementInsertName string
param cosmosDatabaseAccountName string
param appInsightsName string
param hostingPlanName string
param busName string
param serviceBusAuthRuleName string
param serviceBusAuthRuleApiVersion string
param cosmosDatabaseAccountApiVersion string
param queueName string
param dbName string
param containerName string
param blobContainerName string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    capacity: 0
    tier: 'dynamic'
  }
  kind: 'functionapp'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}

resource csvDataLakeWriter 'Microsoft.Web/sites@2022-03-01' = {
  name: csvDataLakeWriterName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: hostingPlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountId, storageAccountApiVersion).keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountId, storageAccountApiVersion).keys[0].value}'
        }
        {
          name: 'WritingTimer'
          value: '0 0 * * * *'
        }
        {
          name: 'CosmosDB_Connection'
          value: listConnectionStrings(resourceId('Microsoft.DocumentDB/databaseAccounts', cosmosDatabaseAccountName), cosmosDatabaseAccountApiVersion).connectionStrings[0].connectionString
        }
        {
          name: 'dbName'
          value: dbName
        }
        {
          name: 'containerName'
          value: containerName
        }
        {
          name: 'blobContainerName'
          value: blobContainerName
        }
      ]
    }
  }
}

resource measurementInsert 'Microsoft.Web/sites@2022-03-01' = {
  name: measurementInsertName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: hostingPlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountId, storageAccountApiVersion).keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountId, storageAccountApiVersion).keys[0].value}'
        }
        {
          name: 'QueueConnectionString'
          value: listKeys(resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', busName, serviceBusAuthRuleName), serviceBusAuthRuleApiVersion).primaryConnectionString
        }
        {
          name: 'CosmosDBConnection'
          value: listConnectionStrings(resourceId('Microsoft.DocumentDB/databaseAccounts', cosmosDatabaseAccountName), '2020-04-01').connectionStrings[0].connectionString
        }
        {
          name: 'queueName'
          value: queueName
        }
        {
          name: 'dbName'
          value: dbName
        }
        {
          name: 'containerName'
          value: containerName
        }
      ]
    }
  }
}
