param location string = resourceGroup().location
param uniqueSeed string = '${subscription().subscriptionId}-${resourceGroup().name}'
param uniqueSuffix string = 'da-${uniqueString(uniqueSeed)}'
param containerAppsEnvName string = 'env-${uniqueSuffix}'
param logAnalyticsWorkspaceName string = 'log-${uniqueSuffix}'
param appInsightsName string = 'appinsights-${uniqueSuffix}'
param storageAccountName string = 'storage${replace(uniqueSuffix, '-', '')}'
param storagePEBlob string = 'pe-${storageAccountName}'
param blobContainerName string = 'albums'
param acrName string = 'acr${replace(uniqueSuffix, '-', '')}'
param adminUserEnabled bool = true
param vm string = 'vm-${uniqueString(uniqueSeed)}'
param vmAdminUser string = 'azureuser'
param adminPublicKey string 
param vnetName string = 'vnet-${uniqueSuffix}'
param vnetPrefix string = '10.110.0.0/16'
param isInternal bool = true
param registryPassword string 


var blobPrivateDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'

// BYO VNet  
var infraSubnet = {
  name: 'InfraSubnet'
  properties: {
    addressPrefix: '10.110.0.0/21'
    privateEndpointNetworkPolicies: 'Disabled'
  }
}
var appSubnet = {
  name: 'AppSubnet'
  properties: {
    addressPrefix: '10.110.8.0/21'
    privateEndpointNetworkPolicies: 'Disabled'
  }
}
var vmSubnet = {
  name: 'VMSubnet'
  properties: {
    addressPrefix: '10.110.16.0/22'
    privateEndpointNetworkPolicies: 'Disabled'
  }
}
var peSubnet = {
  name: 'peSubnet'
  properties: {
    addressPrefix: '10.110.255.192/27'
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

var allSubnets = [
  infraSubnet
  vmSubnet
  appSubnet
  peSubnet
]


module vnetModule 'modules/vnet.bicep' = {
  name: '${deployment().name}--vnet'
  params: {
    location: location
    vnetName: vnetName
    subnets: allSubnets
    vnetPrefix: vnetPrefix
  }
}

module containerRegistry 'modules/container-registry.bicep' = {
  name: '${deployment().name}--acr'
  params: {
    acrName: acrName
    location:location
    adminUserEnabled:adminUserEnabled
  }
}

module storageModule 'modules/storage.bicep' = {
  name: '${deployment().name}--storage'
  dependsOn: [
    vnetModule
  ]
  params: {
    storageAccountName: storageAccountName
    blobContainerName: blobContainerName
    location: location
    blobPrivateDnsZoneName: blobPrivateDnsZoneName
    storagePEBlob: storagePEBlob
    subnetId: '${vnetModule.outputs.vnetId}/subnets/${infraSubnet.name}'
    vnetId: vnetModule.outputs.vnetId
  }
}

module containerAppsEnvModule 'modules/ca-environment.bicep' = {
  name: '${deployment().name}--containerAppsEnv'
  dependsOn: [
    vnetModule
  ]
  params: {
    isInternal: isInternal 
    location: location
    containerAppsEnvName: containerAppsEnvName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    appInsightsName: appInsightsName
    appSubnet: '${vnetModule.outputs.vnetId}/subnets/${appSubnet.name}'
    infraSubnet: '${vnetModule.outputs.vnetId}/subnets/${infraSubnet.name}'
  }
}

module daprComponentsModule 'modules/dapr-components.bicep' = {
  name: '${deployment().name}--dapr-components'
  dependsOn:[
    storageModule
    vnetModule
    containerAppsEnvModule
  ]
  params: {
    containerAppsEnvName : containerAppsEnvName
    storage_account_name: storageAccountName
    storage_container_name: blobContainerName
}
}

module privateDNSModule 'modules/private-dns.bicep' = {
  name: '${deployment().name}--private-dns'
  dependsOn:[
    vnetModule
    containerAppsEnvModule
  ]
  params: {
    location: 'global'
    cappPrivateDnsZoneName: containerAppsEnvModule.outputs.defaultDomain
    staticIP: containerAppsEnvModule.outputs.staticIP
    vnetName: vnetName
  }
}

module virtualMachineModule 'modules/vm.bicep' = {
  name: 'jumpboxvm'
  dependsOn:[
    vnetModule                  
  ]
  params: {
    vm : vm 
    location: location
    subnetId: '${vnetModule.outputs.vnetId}/subnets/${vmSubnet.name}'
    adminUsername: vmAdminUser
    adminSshKey: adminPublicKey
  }
}

module albumServiceModule 'modules/container-apps/album-api.bicep' = {
  name: '${deployment().name}--album-api'
  dependsOn: [
    containerAppsEnvModule
    storageModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    appName: 'album-api'
    registryPassword: registryPassword
  }
}

module albumViewerModule 'modules/container-apps/album-viewer.bicep' = {
  name: '${deployment().name}--album-viewer'
  dependsOn: [
    containerAppsEnvModule
    albumServiceModule
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    appName: 'album-viewer'
    registryPassword: registryPassword
  }
}

output urls array = [
  'Album-viewer: https://album-viewer.${containerAppsEnvModule.outputs.defaultDomain}'
  'Album-api: https://album-api.${containerAppsEnvModule.outputs.defaultDomain}/albums'
  'VM FQDN: ${virtualMachineModule.outputs.fqdn}'
]
