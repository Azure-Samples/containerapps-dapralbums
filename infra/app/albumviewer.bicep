param environmentName string
param location string = resourceGroup().location
param containerAppsEnvironmentName string = ''
param containerRegistryName string = ''
param imageName string = ''
param serviceName string = 'albumviewer'

var abbrs = loadJsonContent('../abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// the managed identity to use throughout
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
}

module albumviewer '../core/host/container-app.bicep' = {
  name: serviceName
  params: {
    environmentName: environmentName
    location: location
    name: '${environmentName}${serviceName}'
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    containerMemory: '0.5Gi'
    containerCpuCoreCount: '0.25'
    imageName: !empty(imageName) ? imageName : 'nginx:latest'
    serviceName: serviceName
    external: true
    targetPort: 3000
    isDaprEnabled: true
    daprApp: 'albumviewer'
    useIdentity: true
    identity: managedIdentity.id
  }
}

output ALBUMVIEWER_IDENTITY_PRINCIPAL_ID string = albumviewer.outputs.identityPrincipalId
output ALBUMVIEWER_NAME string = albumviewer.outputs.name
output ALBUMVIEWER_URI string = albumviewer.outputs.uri
