param cosmos_url string
param cosmos_database_name string
param cosmos_collection_name string
param containerAppsEnvName string
param containerRegistryName string
param secretStoreName string
param vaultName string
param managedIdentityName string
param location string
param logAnalyticsWorkspaceName string
param principalId string
param scopes array = []


// Container apps host (including container registry)
module containerApps '../core/host/container-apps.bicep' = {
  name: 'container-apps'
  params: {
    name: 'app'
    containerAppsEnvironmentName: containerAppsEnvName
    containerRegistryName: containerRegistryName
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

// Get App Env resource instance to parent Dapr component config under it
resource caEnvironment  'Microsoft.App/managedEnvironments@2022-06-01-preview' existing = {
  name: containerAppsEnvName
}

// the managed identity to use throughout
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: managedIdentityName
  location: location
}

resource daprComponentSecretStore 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  parent: caEnvironment
  name: secretStoreName
  properties: {
    componentType: 'secretstores.azure.keyvault'
    version: 'v1'
    ignoreErrors: false
    initTimeout: '5s'
    metadata: [
      {
        name: 'vaultName'
        value: vaultName
      }
      {
        name: 'azureClientId'
        value: principalId
      }
    ]
    scopes: ['albumapi']
  }
}

// Dapr component configuration for shared environment, scoped to appropriate APIs
resource daprComponentStateStore 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  parent: caEnvironment
  name: 'statestore'
  properties: {
    componentType: 'state.azure.cosmosdb'
    version: 'v1'
    ignoreErrors: false
    initTimeout: '5s'
    metadata: [
      {
        name: 'url'
        value: cosmos_url
      }
      {
        name: 'database'
        value: cosmos_database_name
      }
      {
        name: 'collection'
        value: cosmos_collection_name
      }
      {
        name: 'masterKey'
        secretRef: 'AZURE-COSMOS-CONNECTION-STRING'
      }
    ]
    secretStoreComponent: secretStoreName
    scopes: ['albumapi']
  }
}

output environmentName string = containerApps.outputs.environmentName
output registryLoginServer string = containerApps.outputs.registryLoginServer
output registryName string = containerApps.outputs.registryName
output managedIdentityPrincipalId string = managedIdentity.properties.principalId

