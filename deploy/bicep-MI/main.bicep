param location string = resourceGroup().location
param uniqueSeed string = '${subscription().subscriptionId}-${resourceGroup().name}'
param uniqueSuffix string = 'da-${uniqueString(uniqueSeed)}'
param containerAppsEnvName string = 'env-${uniqueSuffix}'
param logAnalyticsWorkspaceName string = 'log-${uniqueSuffix}'
param appInsightsName string = 'appinsights-${uniqueSuffix}'
param apiImage string
param viewerImage string
param localRedis string = 'dapr-albums-test-redis'

@secure()
param registryPassword string
param registryServer string
param registryUsername string

// Log analytics and App Insights for visibility 
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

// Container Apps environment 
resource containerAppsEnv 'Microsoft.App/managedEnvironments@2022-06-01-preview' = {
  name: containerAppsEnvName
  location: location
  properties: {
    daprAIInstrumentationKey:appInsights.properties.InstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

module daprStateStore 'modules/dapr-statestore.bicep' = {
  name: '${deployment().name}--dapr-statestore'
  dependsOn:[
    redisTestCapp
    containerAppsEnv
  ]
  params: {
    containerAppsEnvName : containerAppsEnvName
    redisAppName: localRedis
}
}

module albumViewerCapp 'modules/container-app.bicep' = {
  name: '${deployment().name}--album-viewer'
  dependsOn: [
    containerAppsEnv
    albumServiceCapp
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    appName: 'album-viewer'
    registryPassword: registryPassword
    registryUsername: registryUsername
    containerImage: viewerImage
    targetPort: 3000
    registryServer: registryServer
    transport: 'http'
  }
}

module albumServiceCapp 'modules/container-app.bicep' = {
  name: '${deployment().name}--album-api'
  dependsOn: [
    containerAppsEnv
    redisTestCapp
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    appName: 'album-api'
    registryPassword: registryPassword
    registryUsername: registryUsername
    containerImage: apiImage
    targetPort: 80
    registryServer: registryServer
    transport: 'http'
  }
}

module redisTestCapp 'modules/container-app.bicep' = {
  name: '${deployment().name}--album-api'
  dependsOn: [
    containerAppsEnv
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    appName: localRedis
    containerImage: 'docker.io/redis:7.0'
    targetPort: 6379
    registryServer: registryServer
    transport: 'tcp'
    usePrivateRegistry: false
    daprEnabled: false
  }
}

output env array=[
  'Environment name: ${containerAppsEnv.name}'
]
