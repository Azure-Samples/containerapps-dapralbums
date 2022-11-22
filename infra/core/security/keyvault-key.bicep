param environmentName string
param location string = resourceGroup().location

param keyName string
param keyVaultName string = ''

var abbrs = loadJsonContent('../../abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

resource key 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  name: keyName
  parent: keyVault
  properties: {
    kty: 'RSA'
    keySize: 2048
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
}
