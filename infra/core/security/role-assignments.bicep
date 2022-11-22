param principalId string
param principalType string = 'ServicePrincipal'
param resourceGroupName string = resourceGroup().name
param roles array

resource role_assignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for role in roles: {
  name: guid(subscription().id, principalId, role.id, role.name, resourceGroupName)
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', role.id)
  }
}]
