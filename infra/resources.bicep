param env string
param location string = resourceGroup().location
param secretStoreName string = 'secretstore'

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, env, location))

// the managed identity to use throughout
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
  location: location
}

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    environmentName: env
    location: location
  }
}

// key vault
module keyVault './core/security/keyvault.bicep' = {
  name: '${abbrs.keyVaultVaults}${resourceToken}'
  params: {
    environmentName: env
    location: location
    principalId: managedIdentity.properties.principalId
    permissions: {
      secrets: [
        'get'
        'list'
      ]
    }
  }
}

// Backing storage for Azure functions backend API
module storage './core/storage/storage-account.bicep' = {
  name: '${abbrs.storageStorageAccounts}${resourceToken}'
  params: {
    environmentName: env
    location: location
    allowBlobPublicAccess: true
    managedIdentity: false
  }
}

// Cosmos DB for when we shift to using it for Dapr storage
module cosmos './core/database/cosmos/cosmos-account.bicep' = {
  name: '${abbrs.documentDBDatabaseAccounts}${resourceToken}'
  params: {
    kind: 'GlobalDocumentDB'
    environmentName: env
    keyVaultName: keyVault.name
    location: location
  }
  dependsOn: [
    keyVault
  ]
}

// Blob storage container
module blobContainer './core/storage/storage-container.bicep' = {
  name: 'storagecontainer'
  params: {
    environmentName: env
    location: location
    storageName: storage.outputs.name
    containerName: 'albums'
  }
  dependsOn: [
    storage
  ]
}

// key vault secret
module keyVaultSecret './core/security/keyvault-secret.bicep' = {
  name: 'storageaccountkey'
  params: {
    environmentName: env
    secretName: 'storageaccountkey'
    secretValue: storage.outputs.key
    location: location    
  }
  dependsOn: [
    keyVault
    storage
  ]
}

// Container apps host (including container registry)
module containerApps './core/host/container-apps.bicep' = {
  name: '${abbrs.appManagedEnvironments}${resourceToken}'
  params: {
    environmentName: env
    location: location
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
    containerRegistrySku: { name: 'Basic' }
    daprAIInstrumentationKey: monitoring.outputs.applicationInsightsInstrumentationKey
  }
  dependsOn: [
    storage
    cosmos
  ]
}

// Dapr secret store
module daprSecretStore './core/host/dapr-secretstore.bicep' = {
  name: '${deployment().name}--dapr-secretstore'
  params: {
    containerAppsEnvName: containerApps.outputs.containerAppsEnvironmentName
    vaultName: keyVault.name
    identityClientId: managedIdentity.properties.clientId
    secretStoreName: secretStoreName
  }
  dependsOn: [
    cosmos
    containerApps
    keyVaultSecret
  ]
}

// Dapr state store
module daprStateStore './core/host/dapr-statestore.bicep' = {
  name: '${deployment().name}--dapr-statestore'
  params: {
    containerAppsEnvName: containerApps.outputs.containerAppsEnvironmentName
    storage_account_name: storage.name
    storage_container_name: blobContainer.name
    secretStoreName: secretStoreName
  }
  dependsOn: [
    storage
    blobContainer
    cosmos
    containerApps
  ]
}

// Remove this to create the "real" container app with the API image
module albumapi './core/host/container-app.bicep' = {
  name: 'albumapi'
  params: {
    environmentName: env
    location: location
    name: '${env}albumapi'
    containerAppsEnvironmentName: containerApps.outputs.containerAppsEnvironmentName
    containerRegistryName: containerApps.outputs.containerRegistryName
    containerMemory: '0.5Gi'
    containerCpuCoreCount: '0.25'
    imageName: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
    serviceName: 'albumapi'
    external: true
    targetPort: 80
    isDaprEnabled: true
    daprApp: 'albumapi'
    useIdentity: true
    identity: managedIdentity.id
  }
}

output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerApps.outputs.containerRegistryEndpoint
output AZURE_CONTAINER_REGISTRY_NAME string = containerApps.outputs.containerRegistryName
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.keyVaultEndpoint
