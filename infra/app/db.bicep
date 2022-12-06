param accountName string
param location string = resourceGroup().location
param tags object = {}
param databaseName string = 'albums'
param collectionName string = databaseName

param containers array = [
  {
    name: collectionName
    id: collectionName
    partitionKey: '/id'
  }
]

param keyVaultName string
param principalIds array = []

module cosmos '../core/database/cosmos/sql/cosmos-sql-db.bicep' = {
  name: 'cosmos-sql'
  params: {
    accountName: accountName
    location: location
    tags: tags
    containers: containers
    databaseName: databaseName
    keyVaultName: keyVaultName
    principalIds: principalIds
  }
}

output accountName string = cosmos.outputs.accountName
output connectionStringKey string = cosmos.outputs.connectionStringKey
output databaseName string = cosmos.outputs.databaseName
output endpoint string = cosmos.outputs.endpoint
output roleDefinitionId string = cosmos.outputs.roleDefinitionId
