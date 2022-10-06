param containerAppsEnvName string 
param appName string 
param location string 
@secure()
param registryPassword string
param registryUsername string
param registryServer string
param targetPort int
param useIdentity bool = false
param identity string = 'none'
param containerImage string 
param transport string 


resource caEnvironment 'Microsoft.App/managedEnvironments@2022-06-01-preview' existing = {
  name: containerAppsEnvName
}

resource containerApp 'Microsoft.App/containerApps@2022-06-01-preview' ={
  name: appName
  location: location
  identity:  useIdentity ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity}' : {}
    }    
  }: null 
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
        targetPort: targetPort
        external: true
        transport: transport
      }
      dapr: {
        enabled: true
        appId: appName
        appProtocol: 'http'
        appPort: targetPort
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
