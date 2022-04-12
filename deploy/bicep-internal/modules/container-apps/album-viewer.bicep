param containerAppsEnvName string 
param appName string 
param location string 
@secure()
param registryPassword string

resource caEnvironment 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: containerAppsEnvName
}

// https://github.com/Azure/azure-rest-api-specs/blob/Microsoft.App-2022-01-01-preview/specification/app/resource-manager/Microsoft.App/preview/2022-01-01-preview/ContainerApps.json
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
        targetPort: 3000
        external: true
      }
      dapr: {
        enabled: true
        appId: appName
        appProtocol: 'http'
        appPort: 3000
      }
    }
    template: {
      containers: [
        {
          image: 'dapralbumappacr.azurecr.io/album-viewer:1.0'
          name: appName
        }
      ]
    }
  }
}
