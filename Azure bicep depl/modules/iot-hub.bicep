param iotHubName string
param location string
param busName string
param queueName string
param serviceBusQueueAuthRuleName string
param serviceBusQueueAuthRuleApiVersion string

resource iotHub 'Microsoft.Devices/IotHubs@2021-07-02' = {
  name: iotHubName
  location: location
  sku: {
    name: 'S1'
    capacity: 1
  }
  identity: {
    type: 'None'
  }
  properties: {
     eventHubEndpoints: {
      events: {
        retentionTimeInDays: 1
        partitionCount: 4
      }
     }
     routing: {
      endpoints: {
        serviceBusQueues: [
          {
            name: 'telemetry-to-function'
            connectionString: listKeys(resourceId('Microsoft.ServiceBus/namespaces/queues/authorizationRules', busName, queueName, serviceBusQueueAuthRuleName), serviceBusQueueAuthRuleApiVersion).primaryConnectionString
          }
        ]
      }
      enrichments: [
        {
          key: 'Add_deviceId'
          value: '$deviceId'
          endpointNames: [
            'telemetry-to-function'
          ]
        }
      ]
      routes: [
        {
          name: 'telemetry_to_default'
          source: 'DeviceMessages'
          condition: 'true'
          endpointNames: [
            'events'
          ]
          isEnabled: true
        }
        {
          name: 'telemetry_to_queue'
          source: 'DeviceMessages'
          condition: 'true'
          endpointNames: [
            'telemetry-to-function'
          ]
          isEnabled: true
        }
      ]
      fallbackRoute: {
        source: 'DeviceMessages'
        isEnabled: true
        endpointNames: [
          'events'
        ]
      }
     }
     messagingEndpoints: {
      fileNotifications: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
     }
     enableFileUploadNotifications: false
     cloudToDevice: {
      maxDeliveryCount: 10
      defaultTtlAsIso8601: 'PT1H'
      feedback: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
      }
     }
     features: 'None'
     disableLocalAuth: false
     enableDataResidency: false
     allowedFqdnList: []
  }
}
