param cosmos_url string
param cosmos_database_name string
param cosmos_collection_name string
param containerAppsEnvName string
param containerRegistryName string
param secretStoreName string
param vaultName string
param location string
param logAnalyticsWorkspaceName string
param applicationInsightsName string
param apiIdentityName string
param scopes array = ['albumapi']
param tags object = {}


// Container apps host (including container registry)
module containerApps '../core/host/container-apps.bicep' = {
  name: 'container-apps'
  params: {
    name: 'app'
    location: location
    tags: tags
    containerAppsEnvironmentName: containerAppsEnvName
    containerRegistryName: containerRegistryName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
  }
}

// Define user assigned managed identity here to be used in Dapr component config
resource apiIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: apiIdentityName
  location: location
}

// Give the API access to KeyVault
module apiKeyVaultAccess '../core/security/keyvault-access.bicep' = {
  name: 'api-keyvault-access'
  params: {
    keyVaultName: vaultName
    principalId: apiIdentity.properties.principalId
  }
}

// Get App Env resource instance to parent Dapr component config under it
resource caEnvironment  'Microsoft.App/managedEnvironments@2022-06-01-preview' existing = {
  name: containerAppsEnvName
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
        value: apiIdentity.properties.clientId
      }
    ]
    scopes: scopes
  }
  dependsOn: [
    containerApps
  ]
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
        secretRef: 'AZURE-COSMOS-MASTER-KEY'
      }
    ]
    secretStoreComponent: secretStoreName
    scopes: scopes
  }
  dependsOn: [
    containerApps
  ]
}

output environmentName string = containerApps.outputs.environmentName
output registryLoginServer string = containerApps.outputs.registryLoginServer
output registryName string = containerApps.outputs.registryName
output defaultDomain string = containerApps.outputs.defaultDomain
output apiIdentityName string = apiIdentity.name
