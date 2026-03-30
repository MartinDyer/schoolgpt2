targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environment string = 'production'
param schoolName string = 'SchoolGPT'
param logAnalyticsWorkspaceName string
param appInsightsName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
  }
  tags: {
    Environment: environment
    School: schoolName
    Project: 'SchoolGPT'
    Purpose: 'Centralized Logging'
    ManagedBy: 'Bicep'
    Component: 'Monitoring'
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    RetentionInDays: 90
  }
  tags: {
    Environment: environment
    School: schoolName
    Project: 'SchoolGPT'
    Purpose: 'Application Monitoring'
    ManagedBy: 'Bicep'
    Component: 'Monitoring'
  }
}

output appInsightsName string = applicationInsights.name
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
