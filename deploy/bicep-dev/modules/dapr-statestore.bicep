param redisAppName string 
param redisPort int
param containerAppsEnvName string

resource caEnvironment  'Microsoft.App/managedEnvironments@2022-06-01-preview' existing = {
  name: containerAppsEnvName
}

resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  parent: caEnvironment
  name: 'statestore'
  properties: {
    componentType: 'state.redis'
    version: 'v1'
    ignoreErrors: false
    initTimeout: '5s'
    metadata: [
      {
        name: 'redisHost'
        value: '${redisAppName}:${redisPort}'
      }
    ]
    scopes: ['album-api']
  }
}
