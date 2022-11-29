param environmentName string
param location string = resourceGroup().location
param containerAppsEnvironmentName string = ''
param containerRegistryName string = ''
param serviceName string = 'albumapi'

var abbrs = loadJsonContent('../abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// the managed identity to use throughout
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
}

module albumapi '../core/host/container-app.bicep' = {
  name: serviceName
  params: {
    environmentName: environmentName
    location: location
    name: '${environmentName}${serviceName}'
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    containerMemory: '0.5Gi'
    containerCpuCoreCount: '0.25'
    imageName: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
    serviceName: serviceName
    external: true
    targetPort: 80
    isDaprEnabled: true
    daprApp: 'albumapi'
    useIdentity: true
    identity: managedIdentity.id
  }
}

output ALBUMAPI_IDENTITY_PRINCIPAL_ID string = albumapi.outputs.identityPrincipalId
output ALBUMAPI_NAME string = albumapi.outputs.name
output ALBUMAPI_URI string = albumapi.outputs.uri
