param env string
param location string = resourceGroup().location
param secretStoreName string = 'secretstore'
param cosmosAccountName string = ''
param cosmosDatabaseName string = 'albums'
param cosmosCollectionName string = 'albums'

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

// /// Give the API the role to access Cosmos
// module apiCosmosSqlRoleAssign './core/database/cosmos/sql/cosmos-sql-role-assign.bicep' = {
//   name: 'api-cosmos-access'
//   params: {
//     accountName: cosmos.outputs.accountName
//     roleDefinitionId: cosmos.outputs.roleDefinitionId
//     principalId: containerApps.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID
//   }
// }

// / Cosmos DB for when we shift to using it for Dapr state management
module cosmos './app/db.bicep' = {
  name: 'cosmos'
  params: {
    accountName: !empty(cosmosAccountName) ? cosmosAccountName : '${abbrs.documentDBDatabaseAccounts}${resourceToken}'
    databaseName: cosmosDatabaseName
    collectionName: cosmosCollectionName
    location: location
    keyVaultName: keyVault.outputs.keyVaultName
  }
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
    secretValue: cosmos.outputs.connectionStringKey
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
module daprStateStore './core/host/dapr-statestore-cosmosdb.bicep' = {
  name: '${deployment().name}--dapr-statestore'
  params: {
    containerAppsEnvName: containerApps.outputs.containerAppsEnvironmentName
    cosmos_database_name: cosmosDatabaseName
    cosmos_collection_name: cosmosCollectionName
    cosmos_url: cosmos.outputs.endpoint
    secretStoreName: secretStoreName
    cosmos_account_name: cosmos.outputs.accountName
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
