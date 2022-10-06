param cappPrivateDnsZoneName string
param location string = 'global'
param registrationEnabled bool = true 
param vnetName string
param staticIP string

resource vnet 'Microsoft.Network/virtualNetworks@2020-08-01' existing = {
  name: vnetName
}

resource cappPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: cappPrivateDnsZoneName
  location: location
}

resource cappPrivateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: cappPrivateDnsZone
  name: !empty(vnet.id) ? split(vnet.id, '/')[8] : 'null'
  location: location
  properties: {
    registrationEnabled: registrationEnabled
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource record 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: cappPrivateDnsZone
  name: '*'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: staticIP
      }
    ]
  }
}
