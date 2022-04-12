param storageAccountName string
param blobContainerName string
param location string
param storagePEBlob string 
param subnetId string 
param blobPrivateDnsZoneName string
param vnetId string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
    properties: {
      networkAcls: {
        bypass: 'None'
        defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
  }
  sku: {
    name: 'Standard_LRS'
  }
}


resource blobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-01-01' = {
  name: blobPrivateDnsZoneName
  location: 'global'
}
resource blobPrivateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: blobPrivateDnsZone
  name: !empty(vnetId) ? split(vnetId, '/')[8] : 'null'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource storagePrivateEndpointBlob 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: storagePEBlob
  location: location
  properties: {
    privateLinkServiceConnections: [
      { 
        name: storagePEBlob
        properties: {
          groupIds: [
            'blob'
          ]
          privateLinkServiceId: storageAccount.id
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}
resource privateEndpointDns 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: 'blob-PrivateDnsZoneGroup'
  parent: storagePrivateEndpointBlob
  properties:{
    privateDnsZoneConfigs: [
      {
        name: blobPrivateDnsZoneName
        properties:{
          privateDnsZoneId: blobPrivateDnsZone.id
        }
      }
    ]
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  parent: blobService
  name: blobContainerName
}

output storageId string = storageAccount.id
