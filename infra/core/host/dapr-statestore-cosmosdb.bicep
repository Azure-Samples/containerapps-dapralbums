param cosmos_url string
param cosmos_database_name string
param cosmos_collection_name string
param cosmos_account_name string
param containerAppsEnvName string
param secretStoreName string

resource caEnvironment  'Microsoft.App/managedEnvironments@2022-06-01-preview' existing = {
  name: containerAppsEnvName
}

resource cosmos  'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: cosmos_account_name
}

resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
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
        value: cosmos.listKeys().primaryMasterKey
      }
      {
        name: 'masterKeyKV'
        secretRef: 'storageaccountkey'
      }
    ]
    secretStoreComponent: secretStoreName
    scopes: ['albumapi']
  }
}
