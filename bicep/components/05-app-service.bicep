targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environment string = 'production'
param schoolName string = 'SchoolGPT'
param appServicePlanName string
param appServiceSku string = 'B2'
param webAppName string

resource servicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServiceSku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
  tags: {
    Environment: environment
    School: schoolName
    Project: 'SchoolGPT'
    Purpose: 'App Hosting'
    ManagedBy: 'Bicep'
    Component: 'App-Service'
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: servicePlan.id
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      linuxFxVersion: 'NODE|20-lts'
    }
  }
  tags: {
    Environment: environment
    School: schoolName
    Project: 'SchoolGPT'
    Purpose: 'AI Chat Application'
    TargetAudience: 'Students Under 16'
    ManagedBy: 'Bicep'
    Component: 'App-Service'
  }
}

output webAppName string = webApp.name
output frontendUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppPrincipalId string = webApp.identity.principalId
