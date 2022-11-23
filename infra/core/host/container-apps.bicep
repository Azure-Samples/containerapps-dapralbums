param environmentName string
param location string = resourceGroup().location

param containerAppsEnvironmentName string = ''
param containerAppsGroupName string = 'app'
param containerRegistryName string = ''
param containerRegistrySku object = { name: 'Standard' }
param logAnalyticsWorkspaceName string = ''
param daprAIInstrumentationKey string = ''

module containerAppsEnvironment 'container-apps-environment.bicep' = {
  name: '${containerAppsGroupName}-container-apps-environment'
  params: {
    environmentName: environmentName
    location: location
    containerAppsEnvironmentName: containerAppsEnvironmentName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    daprAIInstrumentationKey: daprAIInstrumentationKey
  }
}

module containerRegistry 'container-registry.bicep' = {
  name: '${containerAppsGroupName}-container-registry'
  params: {
    environmentName: environmentName
    location: location
    containerRegistryName: containerRegistryName
    sku: containerRegistrySku
  }
}

output containerAppsEnvironmentName string = containerAppsEnvironment.outputs.containerAppsEnvironmentName
output containerRegistryEndpoint string = containerRegistry.outputs.containerRegistryEndpoint
output containerRegistryName string = containerRegistry.outputs.containerRegistryName
