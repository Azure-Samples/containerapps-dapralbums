param containerAppsEnvName string
param logAnalyticsWorkspaceName string = 'logs-${containerAppsEnvName}'
param appInsightsName string = 'appins-${containerAppsEnvName}'
param location string = resourceGroup().location
param isInternal bool = true
param infraSubnet string
param appSubnet string 

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId:logAnalyticsWorkspace.id
  }
}

// https://github.com/Azure/azure-rest-api-specs/blob/Microsoft.App-2022-01-01-preview/specification/app/resource-manager/Microsoft.App/preview/2022-01-01-preview/ManagedEnvironments.json
resource environment 'Microsoft.App/managedEnvironments@2022-01-01-preview' = {
  name: containerAppsEnvName
  location: location
  properties: {
    daprAIInstrumentationKey:appInsights.properties.InstrumentationKey
    vnetConfiguration: { 
        internal: isInternal
        infrastructureSubnetId: infraSubnet
        runtimeSubnetId: appSubnet
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

output cappsEnvId string = environment.id
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output defaultDomain string = environment.properties.defaultDomain
output staticIP string = environment.properties.staticIp 
