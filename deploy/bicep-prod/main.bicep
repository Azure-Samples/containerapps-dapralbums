param location string = resourceGroup().location
param uniqueSeed string = '${subscription().subscriptionId}-${resourceGroup().name}'
param uniqueSuffix string = 'da-${uniqueString(uniqueSeed)}'
param containerAppsEnvName string = 'env-${uniqueSuffix}'
param logAnalyticsWorkspaceName string = 'log-${uniqueSuffix}'
param appInsightsName string = 'appinsights-${uniqueSuffix}'
param storageAccountName string = 'storage${replace(uniqueSuffix, '-', '')}'
param blobContainerName string = 'albums'
param managedIdentityName string = 'dapr-albums-mi'
param apiImage string
param viewerImage string
param secretStoreName string = 'secretstore'

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@secure()
param registryPassword string
param registryServer string
param registryUsername string
param vnetName string = 'vnet-${uniqueSuffix}'
param vnetPrefix string = '10.0.0.0/16'

@description('The name of the key vault to be created.')
param vaultName string = 'kv-${uniqueSuffix}'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: managedIdentityName
  location: location
}

var containerAppsSubnet = {
  name: 'ContainerAppsSubnet'
  properties: {
    addressPrefix: '10.0.0.0/23'
  }
}

var subnets = [
  containerAppsSubnet
]


// Deploy an Azure Virtual Network 
module vnetModule 'modules/vnet.bicep' = {
  name: '${deployment().name}--vnet'
  params: {
    location: location
    vnetName: vnetName
    vnetPrefix: vnetPrefix
    subnets: subnets
  }
}

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: vaultName
  location: location
  properties: {
    tenantId:  tenantId
    accessPolicies: [
      {
        objectId: managedIdentity.properties.principalId
        tenantId: tenantId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
    sku: {
      name: 'premium'
      family: 'A'
    }
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: kv
  name: 'storageaccountkey'
  properties: {
    value: listKeys(resourceId('Microsoft.Storage/storageAccounts/', storageAccountName), '2021-09-01').keys[0].value
  }
  dependsOn: [
    storageAccount
  ]
}

// Log analytics and App Insights for visibility 
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId:logAnalyticsWorkspace.id
  }
}


// Container Apps environment 
resource containerAppsEnv 'Microsoft.App/managedEnvironments@2022-06-01-preview' = {
  name: containerAppsEnvName
  location: location
  sku: {
    name: 'Consumption'
  }
  properties: {
    daprAIInstrumentationKey:appInsights.properties.InstrumentationKey
    vnetConfiguration: {
      internal: false
      infrastructureSubnetId: '${vnetModule.outputs.vnetId}/subnets/${containerAppsSubnet.name}'
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
  dependsOn:[
    vnetModule
  ]
}

// Storage Account to act as state store 
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  parent: blobService
  name: blobContainerName
}

module daprStateStore 'modules/dapr-statestore.bicep' = {
  name: '${deployment().name}--dapr-statestore'
  dependsOn:[
    storageAccount
    containerAppsEnv
  ]
  params: {
    containerAppsEnvName : containerAppsEnvName
    storage_account_name: storageAccountName
    storage_container_name: blobContainerName
    secretStoreName: secretStoreName
}
}

module daprSecretStore 'modules/dapr-secretstore.bicep' = {
  name: '${deployment().name}--dapr-secretstore'
  dependsOn:[
    storageAccount
    containerAppsEnv
  ]
  params: {
    containerAppsEnvName : containerAppsEnvName
    vaultName: vaultName
    identityClientId: managedIdentity.properties.clientId
    secretStoreName : secretStoreName
}
}

module albumViewerCapp 'modules/container-app.bicep' = {
  name: '${deployment().name}--album-viewer'
  dependsOn: [
    containerAppsEnv
    albumServiceCapp
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    appName: 'album-viewer'
    registryPassword: registryPassword
    registryUsername: registryUsername
    containerImage: viewerImage
    targetPort: 3000
    registryServer: registryServer
    identity: managedIdentity.id
    transport: 'http'
    useIdentity: true
  }
}

module albumServiceCapp 'modules/container-app.bicep' = {
  name: '${deployment().name}--album-api'
  dependsOn: [
    containerAppsEnv
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    appName: 'album-api'
    registryPassword: registryPassword
    registryUsername: registryUsername
    containerImage: apiImage
    targetPort: 80
    registryServer: registryServer
    identity: managedIdentity.id
    transport: 'http'
    useIdentity: true
  }
}

output env array=[
  'Environment name: ${containerAppsEnv.name}'
  'Storage account name: ${storageAccount.name}'
  'Storage container name: ${blobContainer.name}'
]
