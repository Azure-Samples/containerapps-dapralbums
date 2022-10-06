param containerAppsEnvName string 
param appName string 
param location string 
@secure()
param registryPassword string = ''
param registryUsername string = ''
param registryServer string = ''
param targetPort int
param containerImage string 
param transport string 
param usePrivateRegistry bool = false
param daprEnabled bool = false



resource caEnvironment 'Microsoft.App/managedEnvironments@2022-06-01-preview' existing = {
  name: containerAppsEnvName
}

resource containerApp 'Microsoft.App/containerApps@2022-06-01-preview' ={
  name: appName
  location: location
  properties:{
    managedEnvironmentId: caEnvironment.id
    configuration: {
      secrets: usePrivateRegistry ? [
        {
          name: 'registrypassword'
          value: registryPassword
        }
      ]: null 
      registries: usePrivateRegistry ? [
        {
          server: registryServer
          username: registryUsername
          passwordSecretRef: 'registrypassword'
        }
      ]: null
      ingress: {
        targetPort: targetPort
        external: true
        transport: transport
      }
      dapr: daprEnabled ? {
        enabled: true
        appId: appName
        appProtocol: 'http'
        appPort: targetPort
      }: null
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
