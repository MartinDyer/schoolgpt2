targetScope = 'resourceGroup'

param webAppName string
param appInsightsName string
param keyVaultName string
param sqlServerName string
param sqlDatabaseName string
param sqlAdminLogin string = 'sqladminuser'

@secure()
param sqlAdminPassword string

param aiDeploymentName string = 'gpt-4o'
param azureOpenAiApiVersion string = '2025-01-01-preview'
param deployAiFoundry bool = true
param aiFoundryName string = ''
param existingAiFoundryEndpoint string = ''
param autoGrantAiAccess bool = true

resource webApp 'Microsoft.Web/sites@2023-12-01' existing = {
  name: webAppName
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' existing = {
  name: sqlServerName
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' existing = {
  name: sqlDatabaseName
  parent: sqlServer
}

resource aiFoundry 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = if (deployAiFoundry && autoGrantAiAccess) {
  name: aiFoundryName
}

var sqlConnectionString = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabase.name};Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
var effectiveAiEndpoint = deployAiFoundry ? aiFoundry!.properties.endpoint : existingAiFoundryEndpoint

resource webAppAppSettings 'Microsoft.Web/sites/config@2023-12-01' = {
  name: 'appsettings'
  parent: webApp
  properties: {
    SCM_DO_BUILD_DURING_DEPLOYMENT: 'true'
    NODE_ENV: 'production'
    PORT: '8080'
    WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
    APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsights.properties.InstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
    SQL_CONNECTION_STRING: sqlConnectionString
    AZURE_OPENAI_ENDPOINT: effectiveAiEndpoint
    AZURE_OPENAI_DEPLOYMENT: aiDeploymentName
    AZURE_OPENAI_API_VERSION: azureOpenAiApiVersion
  }
}

resource sqlConnectionSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'sql-connection-string'
  parent: keyVault
  properties: {
    value: sqlConnectionString
  }
}

resource sqlPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'sql-admin-password'
  parent: keyVault
  properties: {
    value: sqlAdminPassword
  }
}

resource aiUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployAiFoundry && autoGrantAiAccess && !empty(aiFoundryName)) {
  name: guid(resourceGroup().id, webApp.id, aiFoundryName, 'openai-user')
  scope: aiFoundry
  properties: {
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
  }
}

output webAppName string = webApp.name
output azureOpenAiEndpoint string = effectiveAiEndpoint
