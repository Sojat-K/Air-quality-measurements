param solutionName string
param environmentName string
param dbName string
param containerName string

var cosmosDbName = '${environmentName}-${solutionName}-cosmos'
var cosmosDbLocations = [
  {
    locationName: 'North Europe'
    failoverPriority: 0
    isZoneRedundant: false
  }
]

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: cosmosDbName
  kind: 'GlobalDocumentDB'
  location: cosmosDbLocations[0].locationName
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: cosmosDbLocations
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  parent: cosmosDbAccount
  name: dbName
  properties: {
    resource: {
      id: dbName
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  parent: database
  name: containerName
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          '/deviceId'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
      }
      defaultTtl: 5184000
    }
  }
}

output cosmosDbAccountName string = cosmosDbAccount.name
output cosmosDbAccountApiVersion string = cosmosDbAccount.apiVersion

