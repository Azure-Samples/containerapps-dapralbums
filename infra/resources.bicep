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

// subnets for the container apps environment
var containerAppsSubnet = {
  name: 'ContainerAppsSubnet'
  properties: {
    addressPrefix: '10.0.0.0/23'
  }
}

var subnets = [
  containerAppsSubnet
]

// virtual network for the environment
module vnet './core/network/vnet.bicep' = {
  name: '${deployment().name}vnet'
  params: {
    location: location
    vnetName: '${abbrs.networkVirtualNetworks}${resourceToken}'
    vnetPrefix: '10.0.0.0/16'
    subnets: subnets
  }
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
    vnetInfrastructureSubnetId: '${vnet.outputs.vnetId}/subnets/${containerAppsSubnet.name}'
  }
  dependsOn: [
    storage
    cosmos
    vnet
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

output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerApps.outputs.containerRegistryEndpoint
output AZURE_CONTAINER_REGISTRY_NAME string = containerApps.outputs.containerRegistryName
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.keyVaultEndpoint
