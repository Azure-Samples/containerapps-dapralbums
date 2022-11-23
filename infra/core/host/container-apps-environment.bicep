param environmentName string
param location string = resourceGroup().location

param containerAppsEnvironmentName string = ''
param logAnalyticsWorkspaceName string = ''
param daprAIInstrumentationKey string = ''
param vnetInfrastructureSubnetId string = ''
param vnetIsInternal bool = false

var abbrs = loadJsonContent('../../abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: !empty(containerAppsEnvironmentName) ? containerAppsEnvironmentName : '${abbrs.appManagedEnvironments}${resourceToken}'
  location: location
  tags: tags
  properties: {
    daprAIInstrumentationKey: !empty(daprAIInstrumentationKey) ? daprAIInstrumentationKey : null
    vnetConfiguration: empty(vnetInfrastructureSubnetId) ? null : {
      internal: vnetIsInternal
      infrastructureSubnetId: vnetInfrastructureSubnetId
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  name: logAnalyticsWorkspaceName
}

output containerAppsEnvironmentName string = containerAppsEnvironment.name
