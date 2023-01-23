param vaultName string
param managedIdentityName string
param location string
param tags object = {}

// the managed identity to use throughout
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


output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output managedIdentityClientlId string = managedIdentity.properties.clientId
output keyVaultName string = keyVault.outputs.name
output keyVaultEndpoint string = keyVault.outputs.endpoint
