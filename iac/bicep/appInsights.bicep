param resourcesPrefix string
var location = resourceGroup().location

// https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/components?tabs=bicep
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${resourcesPrefix}appi'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource appInsightsStaging 'Microsoft.Insights/components@2020-02-02' = {
  name: '${resourcesPrefix}appistaging'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output appInsightsStagingInstrumentationKey string = appInsightsStaging.properties.InstrumentationKey
output appInsightsStagingConnectionString string = appInsightsStaging.properties.ConnectionString
