targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environment string = 'production'
param schoolName string = 'SchoolGPT'
param sqlServerName string
param sqlDatabaseName string = 'schoolgptdb'
param sqlAdminLogin string = 'sqladminuser'

@secure()
param sqlAdminPassword string

param sqlSkuName string = 'S1'
param sqlAzureAdAdminLogin string = ''
param sqlAzureAdAdminObjectId string = ''
param azureTenantId string = ''

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    Environment: environment
    School: schoolName
    Project: 'SchoolGPT'
    Purpose: 'SQL Server'
    ManagedBy: 'Bicep'
    Component: 'Data'
  }
}

resource sqlAzureAdAdmin 'Microsoft.Sql/servers/administrators@2023-08-01-preview' = if (!empty(sqlAzureAdAdminLogin) && !empty(sqlAzureAdAdminObjectId) && !empty(azureTenantId)) {
  name: 'ActiveDirectory'
  parent: sqlServer
  properties: {
    administratorType: 'ActiveDirectory'
    login: sqlAzureAdAdminLogin
    sid: sqlAzureAdAdminObjectId
    tenantId: azureTenantId
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  name: sqlDatabaseName
  parent: sqlServer
  location: location
  sku: {
    name: sqlSkuName
  }
  properties: {
    maxSizeBytes: 2147483648
  }
  tags: {
    Environment: environment
    School: schoolName
    Project: 'SchoolGPT'
    Purpose: 'Application Database'
    ManagedBy: 'Bicep'
    Component: 'Data'
  }
}

resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  name: 'AllowAzureServices'
  parent: sqlServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDatabase.name
