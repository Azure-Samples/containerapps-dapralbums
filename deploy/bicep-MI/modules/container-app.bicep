param containerAppsEnvName string 
param appName string 
param location string 
@secure()
param registryPassword string
param registryUsername string
param registryServer string
param httpPort int
param containerImage string 

resource caEnvironment 'Microsoft.App/managedEnvironments@2022-06-01-preview' existing = {
  name: containerAppsEnvName
}

resource containerApp 'Microsoft.App/containerApps@2022-06-01-preview' ={
  name: appName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
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
          server: registryServer
          username: registryUsername
          passwordSecretRef: 'registrypassword'
        }
      ]
      ingress: {
        targetPort: httpPort
        external: true
      }
      dapr: {
        enabled: true
        appId: appName
        appProtocol: 'http'
        appPort: httpPort
      }
    }
    template: {
      containers: [
        {
          image: containerImage
          name: appName
        }
      ]
    }
  }
}

output containerAppIdentity string = containerApp.identity.principalId
