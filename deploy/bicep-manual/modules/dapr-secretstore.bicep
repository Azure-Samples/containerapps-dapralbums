param containerAppsEnvName string
param tenantId string
param vaultName string
param clientId string
@secure()
param clientSecret string


resource caEnvironment  'Microsoft.App/managedEnvironments@2022-06-01-preview' existing = {
  name: containerAppsEnvName
}

resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  parent: caEnvironment
  name: 'secretstore'
  properties: {
    componentType: 'secretstores.azure.keyvault'
    version: 'v1'
    ignoreErrors: false
    initTimeout: '5s'
    secrets: [
      {
        name: 'azureclientsecret'
        value: clientSecret
      }
    ]
    metadata: [
      {
        name: 'vaultName'
        value: vaultName
      }
      {
        name: 'azureTenantId'
        value: tenantId
      }
      {
        name: 'azureClientId'
        value: clientId
      }  
      {
        name: 'azureClientSecret'
        secretRef: 'azureclientsecret'
      }
    ]
    scopes: ['album-api']
  }
}
