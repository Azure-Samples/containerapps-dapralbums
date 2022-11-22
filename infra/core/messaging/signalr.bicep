param environmentName string
param location string = resourceGroup().location

var abbrs = loadJsonContent('../../abbreviations.json')
var tags = { 'azd-env-name': environmentName }
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

resource signalr 'Microsoft.SignalRService/signalR@2022-02-01' = {
  name: '${abbrs.signalRServiceSignalR}${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Premium_P1'
    tier: 'Premium'
    capacity: 2
  }
  properties: {
    features: [
      {
        flag: 'ServiceMode'
        value: 'Default'
      }
      {
        flag: 'EnableConnectivityLogs'
        value: 'True'
      }
    ]
    cors: {
      allowedOrigins: [
        '*'
      ]
    }
  }
}
