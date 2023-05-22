param accountName string
param location string = resourceGroup().location
param tags object = {}

param databaseName string = 'albums'
param collectionName string = 'albums'
param keyVaultName string
param principalId string = ''

// Because databaseName is optional in main.bicep, we make sure the database name is set here.
var defaultDatabaseName = 'albums'
var actualDatabaseName = !empty(databaseName) ? databaseName : defaultDatabaseName

param containers array = [
  {
    name: collectionName
    id: collectionName
    partitionKey: '/id'
  }
]

module cosmos '../core/database/cosmos/sql/cosmos-sql-db.bicep' = {
  name: 'cosmos-sql'
  params: {
    accountName: accountName
    databaseName: actualDatabaseName
    location: location
    containers: containers
    keyVaultName: keyVaultName
    tags: tags
  }
}

output connectionStringKey string = cosmos.outputs.connectionStringKey
output databaseName string = cosmos.outputs.databaseName
output accountName string = cosmos.outputs.accountName
output endpoint string = cosmos.outputs.endpoint
