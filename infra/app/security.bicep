param vaultName string
param managedIdentityName string
param location string
param tags object = {}
param principalId string = ''

// user assigned managed identity to use throughout
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: managedIdentityName
  location: location
}

// Store secrets in a keyvault
module keyVault '../core/security/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    name: vaultName
    location: location
    tags: tags
    principalId: managedIdentity.properties.principalId
  }
}

// Grant list and get access to the user assigned managed identity
module keyVaultAccessUserAssigned '../core/security/keyvault-access.bicep' = {
  name: 'keyvaultAccessUserAssigned'
  params: {
    principalId: managedIdentity.properties.principalId
    keyVaultName: keyVault.outputs.name
    permissions: { secrets: [ 'get', 'list' ] }
  }
}

// Grant list and get access to the current principal running this module
module keyVaultAccessCurrentPrincipal '../core/security/keyvault-access.bicep' = {
  name: 'keyvaultAccessCurrentPrincipal'
  params: {
    principalId: principalId
    keyVaultName: keyVault.outputs.name
    permissions: { secrets: [ 'get', 'list' ] }
  }
}


output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output managedIdentityClientlId string = managedIdentity.properties.clientId
output managedIdentityId string = managedIdentity.id
output managedIdentityName string = managedIdentity.name
output keyVaultName string = keyVault.outputs.name
output keyVaultEndpoint string = keyVault.outputs.endpoint
