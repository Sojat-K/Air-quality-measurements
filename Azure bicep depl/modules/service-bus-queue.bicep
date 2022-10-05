param location string
param serviceBusName string
param serviceBusAuthRuleName string
param queueName string
param queueAuthRuleName string

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: serviceBusName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    minimumTlsVersion: '1.0'
    publicNetworkAccess: 'Enabled'
    zoneRedundant: false
  }
}

resource serviceBusAuthRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-01-01-preview' = {
  parent: serviceBus
  name: serviceBusAuthRuleName
  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  name: queueName
  parent: serviceBus
  properties: {
    maxDeliveryCount: 10
    enablePartitioning: false
    enableExpress: false
    maxMessageSizeInKilobytes: 256
    maxSizeInMegabytes: 1024
  }
}

resource serviceBusQueueAuthRule 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2022-01-01-preview' = {
  name: queueAuthRuleName
  parent: serviceBusQueue
  properties: {
    rights: [
      'Send'
    ]
  }
}

output queueName string = serviceBusQueue.name
output BusName string = serviceBus.name
output serviceBusQueueAuthApiVersion string = serviceBusQueueAuthRule.apiVersion
output serviceBusQueueAuthName string = serviceBusQueueAuthRule.name
output serviceBusAuthApiVersion string = serviceBusAuthRule.apiVersion
output serviceBusAuthName string = serviceBusAuthRule.name

