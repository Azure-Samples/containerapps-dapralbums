param containerAppsEnvName string 
param appName string 
param location string 
@secure()
param registryPassword string 

resource caEnvironment  'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: containerAppsEnvName
}

resource containerApp 'Microsoft.App/containerApps@2022-01-01-preview' ={
  name: appName
  location: location
  properties:{
    managedEnvironmentId: caEnvironment.id
    configuration: {
      secrets: [
        {
          name: 'registrypassword'
          value: registryPassword
        }
      ]
      registries: [
        {
          server: 'dapralbumappacr.azurecr.io'
          username: 'dapralbumappacr'
          passwordSecretRef: 'registrypassword'
        }
      ]
      ingress: {
        targetPort: 80
        external: true
      }
      dapr: {
        enabled: true
        appId: appName
        appProtocol: 'http'
        appPort: 80
      }
    }
    template: {
      containers: [
        {
          image: 'dapralbumappacr.azurecr.io/album-api:1.0'
          name: appName
        }
      ]
    }
  }
}
