@description('Specifies the role definition ID used in the role assignment.')
param roleDefinitionID string

@description('Specifies the principal ID assigned to the role.')
param principalId string

@description('Specifies the resource ID the access policy will apply to.')
param resourceID string

var roleAssignmentName= guid(principalId, roleDefinitionID, resourceID)
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: roleAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionID)
    principalId: principalId
  }
}
