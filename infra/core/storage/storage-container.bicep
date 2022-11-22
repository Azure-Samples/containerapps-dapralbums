param environmentName string
param location string = resourceGroup().location

param blobServicesName string = 'default'
param containerName string
param publicAccess string = 'Blob'
param storageName string = ''

var abbrs = loadJsonContent('../../abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: containerName
  parent: storageBlobServices
  properties: {
    publicAccess: publicAccess
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: !empty(storageName) ? storageName : '${abbrs.storageStorageAccounts}${resourceToken}'
}

resource storageBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' existing = {
  name: blobServicesName
  parent: storage
}
