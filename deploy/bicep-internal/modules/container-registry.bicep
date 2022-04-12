param acrName string 
param location string
param adminUserEnabled bool

resource acr 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: adminUserEnabled
  }
}
