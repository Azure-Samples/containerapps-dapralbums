// -------------------------------------
// after
// -------------------------------------

targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string

var abbrs = loadJsonContent('./abbreviations.json')
var tags = { 'azd-env-name': environmentName }

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module resources 'resources.bicep' = {
  name: 'resources'
  scope: rg
  params: {
    env: environmentName
    location: location
  }
}

output APPLICATIONINSIGHTS_CONNECTION_STRING string = resources.outputs.APPLICATIONINSIGHTS_CONNECTION_STRING
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = resources.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output AZURE_CONTAINER_REGISTRY_NAME string = resources.outputs.AZURE_CONTAINER_REGISTRY_NAME
output AZURE_KEY_VAULT_ENDPOINT string = resources.outputs.AZURE_KEY_VAULT_ENDPOINT
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId

// module albumviewerCapp 'modules/container-app.bicep' = {
//   name: '${deployment().name}--albumviewer'
//   dependsOn: [
//     containerAppsEnv
//     albumServiceCapp
//   ]
//   params: {
//     location: location
//     containerAppsEnvName: containerAppsEnvName
//     appName: 'albumviewer'
//     registryPassword: registryPassword
//     registryUsername: registryUsername
//     containerImage: viewerImage
//     targetPort: 3000
//     registryServer: registryServer
//     identity: managedIdentity.id
//     transport: 'http'
//     useIdentity: true
//   }
// }

// module albumServiceCapp 'modules/container-app.bicep' = {
//   name: '${deployment().name}--albumapi'
//   dependsOn: [
//     containerAppsEnv
//   ]
//   params: {
//     location: location
//     containerAppsEnvName: containerAppsEnvName
//     appName: 'albumapi'
//     registryPassword: registryPassword
//     registryUsername: registryUsername
//     containerImage: apiImage
//     targetPort: 80
//     registryServer: registryServer
//     identity: managedIdentity.id
//     transport: 'http'
//     useIdentity: true
//   }
// }
