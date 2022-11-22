param environmentName string
param location string = resourceGroup().location


param enabledForDeployment bool = true
param enabledForTemplateDeployment bool = true
param enabledForDiskEncryption bool = true
param enableRbacAuthorization bool = false
param keyVaultName string = ''
param permissions object = { secrets: [ 'get', 'list' ] }
param principalId string = ''

var abbrs = loadJsonContent('../../abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enableRbacAuthorization: enableRbacAuthorization
    accessPolicies: !empty(principalId) ? [
      {
        objectId: principalId
        permissions: permissions
        tenantId: subscription().tenantId
      }
    ] : []
  }
}

output keyVaultEndpoint string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
