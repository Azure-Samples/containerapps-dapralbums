// Key Vault bootstap for further challenges - not used in the beginning.
param resourcesPrefix string
param location string = resourceGroup().location
param sqlServerAdminLogin string
param sqlServerId string
@secure()
param sqlServerAdminPassword string
@secure()
param containerRegistryAdminPassword string

// https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults?tabs=bicep
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: '${resourcesPrefix}kv'
  location: location
  
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId

    accessPolicies: []
    softDeleteRetentionInDays: 7
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets?tabs=bicep
resource sqlPassword 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  parent: keyVault
  name: 'SQL-PASSWORD'
  tags: {
    CredentialId:       sqlServerAdminLogin
    ProviderAddress:    sqlServerId
    ValidityPeriodDays: '60'
  }
  properties: {
    attributes: {
      enabled: true
      //exp: '' // needs to be int - timestamp in seconds
    }
    value: sqlServerAdminPassword
  }
}

resource dockerRegistryServerPassword 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  parent: keyVault
  name: 'DOCKER-REGISTRY-SERVER-PASSWORD'
  
  properties: {
    value: containerRegistryAdminPassword
  }
}

output name string = keyVault.name
