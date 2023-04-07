param resourcesPrefix string
param sqlServerAdminLogin string
@secure()
param sqlServerAdminPassword string
param sqlServerFqdn string
param sqlDatabaseName string
param containerRegistryLoginServer string
param containerRegistryName string
param containerRegistryAdminUsername string
param containerRegistryAdminPassword string
param keyVaultName string // for Key Vault integration
param appInsightsInstrumentationKey string
param appInsightsConnectionString string
param appInsightsStagingInstrumentationKey string
param appInsightsStagingConnectionString string
param apiPoiBaseImageTag string
param apiTripsBaseImageTag string
param apiUserJavaBaseImageTag string
param apiUserprofileBaseImageTag string

var location = resourceGroup().location
var varfile = json(loadTextContent('./variables.json'))

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
// AcrPull
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryName
}

// Prepared for Key Vault integration
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/serverfarms?tabs=bicep
resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: '${resourcesPrefix}plan'
  kind: 'linux'
  location: location
  properties: {
    reserved: true
  }
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites?tabs=bicep
resource appServiceTripviewer 'Microsoft.Web/sites@2021-02-01' = {
  name: '${resourcesPrefix}tripviewer'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      acrUseManagedIdentityCreds: true
      linuxFxVersion: 'DOCKER|${containerRegistryLoginServer}/devopsoh/tripviewer:latest'
      appSettings: [
        {
          name: 'BING_MAPS_KEY'
          value: varfile.bingMapsKey
        }
        {
          name: 'USER_ROOT_URL'
          value: 'https://${appServiceApiUserprofile.properties.defaultHostName}'
        }
        {
          name: 'USER_JAVA_ROOT_URL'
          value: 'https://${appServiceApiUserJava.properties.defaultHostName}'
        }
        {
          name: 'TRIPS_ROOT_URL'
          value: 'https://${appServiceApiTrips.properties.defaultHostName}'
        }
        {
          name: 'POI_ROOT_URL'
          value: 'https://${appServiceApiPoi.properties.defaultHostName}'
        }
        {
          name: 'STAGING_USER_ROOT_URL'
          value: 'https://${appServiceApiUserprofileStaging.properties.defaultHostName}'
        }
        {
          name: 'STAGING_USER_JAVA_ROOT_URL'
          value: 'https://${appServiceApiUserJavaStaging.properties.defaultHostName}'
        }
        {
          name: 'STAGING_TRIPS_ROOT_URL'
          value: 'https://${appServiceApiTripsStaging.properties.defaultHostName}'
        }
        {
          name: 'STAGING_POI_ROOT_URL'
          value: 'https://${appServiceApiPoiStaging.properties.defaultHostName}'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryLoginServer}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
      alwaysOn: true
    }
    httpsOnly: true
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites/config-logs?tabs=bicep
resource appServiceTripviewerExtension 'Microsoft.Web/sites/config@2021-02-01' = {
  parent: appServiceTripviewer
  name: 'logs'
  properties: {
    httpLogs: {
      fileSystem: {
        retentionInMb: 50
        retentionInDays: 7
        enabled: true
      }
    }
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep
resource acrPullRoleAssignmentTripviewer 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, containerRegistry.id, 'tripviewer', acrPullRoleDefinitionId)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: appServiceTripviewer.identity.principalId
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites?tabs=bicep
resource appServiceApiPoi 'Microsoft.Web/sites@2021-02-01' = {
  name: '${resourcesPrefix}poi'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryLoginServer}/devopsoh/api-poi:${apiPoiBaseImageTag}'
      healthCheckPath: '/api/healthcheck/poi'
      appSettings: [
        {
          name: 'SQL_USER'
          value: sqlServerAdminLogin
        }
        {
          name: 'SQL_PASSWORD'
          value: sqlServerAdminPassword
          //value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=SQL-PASSWORD)' // for Key Vault integration
        }
        {
          name: 'SQL_SERVER'
          value: sqlServerFqdn
        }
        {
          name: 'SQL_DBNAME'
          value: sqlDatabaseName
        }
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryLoginServer}'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: containerRegistryAdminUsername
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: containerRegistryAdminPassword
          //value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=DOCKER-REGISTRY-SERVER-PASSWORD)' // for Key Vault integration
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
      alwaysOn: true
    }
    httpsOnly: true
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites/config-logs?tabs=bicep
resource appServiceApiPoiExtension 'Microsoft.Web/sites/config@2021-02-01' = {
  parent: appServiceApiPoi
  name: 'logs'
  properties: {
    httpLogs: {
      fileSystem: {
        retentionInMb: 50
        retentionInDays: 7
        enabled: true
      }
    }
  }
}

// Prepared for Key Vault integration
// resource keyVaultAccessPolicyApiPoi 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
//   name: 'add'
//   parent: keyVault
//   properties: {
//     accessPolicies: [
//       {
//         tenantId: appServiceApiPoi.identity.tenantId
//         objectId: appServiceApiPoi.identity.principalId
//         permissions: {
//           secrets: [
//             'get'
//             'list'
//             'set'
//           ]
//         }
//       }
//     ]
//   }
// }

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites/slots?tabs=bicep
resource appServiceApiPoiStaging 'Microsoft.Web/sites/slots@2021-02-01' = {
  parent: appServiceApiPoi
  name: 'staging'
  identity: {
    type: 'SystemAssigned'
  }
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryLoginServer}/devopsoh/api-poi:${apiPoiBaseImageTag}'
      healthCheckPath: '/api/healthcheck/poi'
      appSettings: [
        {
          name: 'SQL_USER'
          value: sqlServerAdminLogin
        }
        {
          name: 'SQL_PASSWORD'
          value: sqlServerAdminPassword
          //value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=SQL-PASSWORD)' // for Key Vault integration
        }
        {
          name: 'SQL_SERVER'
          value: sqlServerFqdn
        }
        {
          name: 'SQL_DBNAME'
          value: sqlDatabaseName
        }
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryLoginServer}'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: containerRegistryAdminUsername
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: containerRegistryAdminPassword
          //value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=DOCKER-REGISTRY-SERVER-PASSWORD)' // for Key Vault integration
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsStagingInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsStagingConnectionString
        }
      ]
      alwaysOn: true
    }
    httpsOnly: true
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites/config-logs?tabs=bicep
resource appServiceApiPoiStagingExtension 'Microsoft.Web/sites/slots/config@2021-02-01' = {
  parent: appServiceApiPoiStaging
  name: 'logs'
  properties: {
    httpLogs: {
      fileSystem: {
        retentionInMb: 50
        retentionInDays: 7
        enabled: true
      }
    }
  }
}

// Prepared for Key Vault integration
// resource keyVaultAccessPolicyApiPoiStaging 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
//   name: 'add'
//   parent: keyVault
//   properties: {
//     accessPolicies: [
//       {
//         tenantId: appServiceApiPoiStaging.identity.tenantId
//         objectId: appServiceApiPoiStaging.identity.principalId
//         permissions: {
//           secrets: [
//             'get'
//             'list'
//             'set'
//           ]
//         }
//       }
//     ]
//   }
// }

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites?tabs=bicep
resource appServiceApiTrips 'Microsoft.Web/sites@2021-02-01' = {
  name: '${resourcesPrefix}trips'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryLoginServer}/devopsoh/api-trips:${apiTripsBaseImageTag}'
      healthCheckPath: '/api/healthcheck/trips'
      appSettings: [
        {
          name: 'SQL_USER'
          value: sqlServerAdminLogin
        }
        {
          name: 'SQL_PASSWORD'
          value: sqlServerAdminPassword
        }
        {
          name: 'SQL_SERVER'
          value: sqlServerFqdn
        }
        {
          name: 'SQL_DBNAME'
          value: sqlDatabaseName
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryLoginServer}'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: containerRegistryAdminUsername
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: containerRegistryAdminPassword
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
      alwaysOn: true
    }
    httpsOnly: true
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites/config-logs?tabs=bicep
resource appServiceApiTripsExtension 'Microsoft.Web/sites/config@2021-02-01' = {
  parent: appServiceApiTrips
  name: 'logs'
  properties: {
    httpLogs: {
      fileSystem: {
        retentionInMb: 50
        retentionInDays: 7
        enabled: true
      }
    }
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites/slots?tabs=bicep
resource appServiceApiTripsStaging 'Microsoft.Web/sites/slots@2021-02-01' = {
  parent: appServiceApiTrips
  name: 'staging'
  identity: {
    type: 'SystemAssigned'
  }
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryLoginServer}/devopsoh/api-trips:${apiTripsBaseImageTag}'
      healthCheckPath: '/api/healthcheck/trips'
      appSettings: [
        {
          name: 'SQL_USER'
          value: sqlServerAdminLogin
        }
        {
          name: 'SQL_PASSWORD'
          value: sqlServerAdminPassword
        }
        {
          name: 'SQL_SERVER'
          value: sqlServerFqdn
        }
        {
          name: 'SQL_DBNAME'
          value: sqlDatabaseName
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryLoginServer}'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: containerRegistryAdminUsername
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: containerRegistryAdminPassword
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsStagingInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsStagingConnectionString
        }
      ]
      alwaysOn: true
    }
    httpsOnly: true
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites/config-logs?tabs=bicep
resource appServiceApiTripsStagingExtension 'Microsoft.Web/sites/slots/config@2021-02-01' = {
  parent: appServiceApiTripsStaging
  name: 'logs'
  properties: {
    httpLogs: {
      fileSystem: {
        retentionInMb: 50
        retentionInDays: 7
        enabled: true
      }
    }
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites?tabs=bicep
resource appServiceApiUserJava 'Microsoft.Web/sites@2021-02-01' = {
  name: '${resourcesPrefix}userjava'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryLoginServer}/devopsoh/api-user-java:${apiUserJavaBaseImageTag}'
      healthCheckPath: '/api/healthcheck/user-java'
      appSettings: [
        {
          name: 'SQL_USER'
          value: sqlServerAdminLogin
        }
        {
          name: 'SQL_PASSWORD'
          value: sqlServerAdminPassword
        }
        {
          name: 'SQL_SERVER'
          value: sqlServerFqdn
        }
        {
          name: 'SQL_DBNAME'
          value: sqlDatabaseName
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryLoginServer}'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: containerRegistryAdminUsername
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: containerRegistryAdminPassword
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
      alwaysOn: true
    }
    httpsOnly: true
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites/config-logs?tabs=bicep
resource appServiceApiUserJavaExtension 'Microsoft.Web/sites/config@2021-02-01' = {
  parent: appServiceApiUserJava
  name: 'logs'
  properties: {
    httpLogs: {
      fileSystem: {
        retentionInMb: 50
        retentionInDays: 7
        enabled: true
      }
    }
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites/slots?tabs=bicep
resource appServiceApiUserJavaStaging 'Microsoft.Web/sites/slots@2021-02-01' = {
  parent: appServiceApiUserJava
  name: 'staging'
  identity: {
    type: 'SystemAssigned'
  }
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryLoginServer}/devopsoh/api-user-java:${apiUserJavaBaseImageTag}'
      healthCheckPath: '/api/healthcheck/user-java'
      appSettings: [
        {
          name: 'SQL_USER'
          value: sqlServerAdminLogin
        }
        {
          name: 'SQL_PASSWORD'
          value: sqlServerAdminPassword
        }
        {
          name: 'SQL_SERVER'
          value: sqlServerFqdn
        }
        {
          name: 'SQL_DBNAME'
          value: sqlDatabaseName
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryLoginServer}'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: containerRegistryAdminUsername
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: containerRegistryAdminPassword
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsStagingInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsStagingConnectionString
        }
      ]
      alwaysOn: true
    }
    httpsOnly: true
  }
}


// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites/config-logs?tabs=bicep
resource appServiceApiUserJavaStagingExtension 'Microsoft.Web/sites/slots/config@2021-02-01' = {
  parent: appServiceApiUserJavaStaging
  name: 'logs'
  properties: {
    httpLogs: {
      fileSystem: {
        retentionInMb: 50
        retentionInDays: 7
        enabled: true
      }
    }
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites?tabs=bicep
resource appServiceApiUserprofile 'Microsoft.Web/sites@2021-02-01' = {
  name: '${resourcesPrefix}userprofile'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryLoginServer}/devopsoh/api-userprofile:${apiUserprofileBaseImageTag}'
      healthCheckPath: '/api/healthcheck/user'
      appSettings: [
        {
          name: 'SQL_USER'
          value: sqlServerAdminLogin
        }
        {
          name: 'SQL_PASSWORD'
          value: sqlServerAdminPassword
        }
        {
          name: 'SQL_SERVER'
          value: sqlServerFqdn
        }
        {
          name: 'SQL_DBNAME'
          value: sqlDatabaseName
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryLoginServer}'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: containerRegistryAdminUsername
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: containerRegistryAdminPassword
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
      alwaysOn: true
    }
    httpsOnly: true
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites/config-logs?tabs=bicep
resource appServiceApiUserprofileExtension 'Microsoft.Web/sites/config@2021-02-01' = {
  parent: appServiceApiUserprofile
  name: 'logs'
  properties: {
    httpLogs: {
      fileSystem: {
        retentionInMb: 50
        retentionInDays: 7
        enabled: true
      }
    }
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites/slots?tabs=bicep
resource appServiceApiUserprofileStaging 'Microsoft.Web/sites/slots@2021-02-01' = {
  parent: appServiceApiUserprofile
  name: 'staging'
  identity: {
    type: 'SystemAssigned'
  }
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryLoginServer}/devopsoh/api-userprofile:${apiUserprofileBaseImageTag}'
      healthCheckPath: '/api/healthcheck/user'
      appSettings: [
        {
          name: 'SQL_USER'
          value: sqlServerAdminLogin
        }
        {
          name: 'SQL_PASSWORD'
          value: sqlServerAdminPassword
        }
        {
          name: 'SQL_SERVER'
          value: sqlServerFqdn
        }
        {
          name: 'SQL_DBNAME'
          value: sqlDatabaseName
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryLoginServer}'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: containerRegistryAdminUsername
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: containerRegistryAdminPassword
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsStagingInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsStagingConnectionString
        }
      ]
      alwaysOn: true
    }
    httpsOnly: true
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites/config-logs?tabs=bicep
resource appServiceApiUserprofileStagingExtension 'Microsoft.Web/sites/slots/config@2021-02-01' = {
  parent: appServiceApiUserprofileStaging
  name: 'logs'
  properties: {
    httpLogs: {
      fileSystem: {
        retentionInMb: 50
        retentionInDays: 7
        enabled: true
      }
    }
  }
}

output appServiceApiPoiHostname string = appServiceApiPoi.properties.defaultHostName
output appServiceApiTripsHostname string = appServiceApiTrips.properties.defaultHostName
output appServiceApiUserJavaHostname string = appServiceApiUserJava.properties.defaultHostName
output appServiceApiUserprofileHostname string = appServiceApiUserprofile.properties.defaultHostName
