targetScope = 'resourceGroup'

@description('Azure region for the resource group and all resources.')
param location string = 'uksouth'

@description('Environment name used in tags and generated names.')
param environment string = 'production'

@description('School name used in tags and generated names.')
param schoolName string = 'SchoolGPT'

@description('Optional short prefix used when generating names. Letters and numbers are safest.')
param namePrefix string = 'schoolgpt'

@description('Azure tenant ID used by Key Vault and optional SQL Entra admin configuration.')
param azureTenantId string

@description('Object ID that should receive Key Vault admin access.')
param keyVaultAdminObjectId string

@description('Override for the App Service plan name. Leave empty to generate.')
param appServicePlanName string = ''

@description('Override for the web app name. Leave empty to generate a globally unique name.')
param webAppName string = ''

@description('Override for the Application Insights name. Leave empty to generate.')
param appInsightsName string = ''

@description('Override for the Log Analytics workspace name. Leave empty to generate.')
param logAnalyticsWorkspaceName string = ''

@description('Override for the Key Vault name. Leave empty to generate a globally unique name.')
param keyVaultName string = ''

@description('Override for the SQL Server name. Leave empty to generate a globally unique name.')
param sqlServerName string = ''

@description('SQL database name.')
param sqlDatabaseName string = 'schoolgptdb'

@description('SQL administrator username.')
param sqlAdminLogin string = 'sqladminuser'

@secure()
@description('Optional SQL administrator password. Leave empty to auto-generate.')
param sqlAdminPassword string = ''

@description('SQL database SKU, for example Basic, S0, or S1.')
param sqlSkuName string = 'S1'

@description('App Service plan SKU, for example B1, B2, S1, or P1v3.')
param appServiceSku string = 'B2'

@description('Deploy Azure AI Foundry resources in the same deployment.')
param deployAiFoundry bool = true

@description('Override for the AI Foundry account name. Leave empty to generate a globally unique name.')
param aiFoundryName string = ''

@description('Optional custom subdomain for AI Foundry. Leave empty to derive from the AI Foundry name.')
param aiFoundryCustomSubdomain string = ''

@description('Model deployment name exposed to the app.')
param aiDeploymentName string = 'gpt-4o'

@description('Azure OpenAI model name to deploy.')
param aiModelName string = 'gpt-4o'

@description('Azure OpenAI model version to deploy.')
param aiModelVersion string = '2024-11-20'

@description('Deployment SKU for the Azure OpenAI model deployment.')
param aiDeploymentSkuName string = 'GlobalStandard'

@description('Capacity for the Azure OpenAI deployment.')
param aiDeploymentCapacity int = 1

@description('Optional RAI policy name. Leave empty to skip custom RAI policy creation.')
param raiPolicyName string = 'schoolgpt-default-rai'

@description('API version exposed to the Node app.')
param azureOpenAiApiVersion string = '2025-01-01-preview'

@description('Create the OpenAI user role assignment for the web app managed identity automatically.')
param autoGrantAiAccess bool = true

@description('Optional endpoint for an existing AI Foundry resource. Required when deployAiFoundry is false.')
param existingAiFoundryEndpoint string = ''

@description('Optional resource name for an existing AI Foundry resource. Required when deployAiFoundry is false and autoGrantAiAccess is true.')
param existingAiFoundryResourceName string = ''

@description('Optional SQL Entra admin login UPN.')
param sqlAzureAdAdminLogin string = ''

@description('Optional SQL Entra admin object ID.')
param sqlAzureAdAdminObjectId string = ''

var normalizedPrefix = toLower(replace(replace(replace(namePrefix, ' ', ''), '-', ''), '_', ''))
var safePrefix = empty(normalizedPrefix) ? 'schoolgpt' : normalizedPrefix
var uniqueSuffix = toLower(uniqueString(subscription().id, resourceGroup().id))
var compactPrefix = take('${safePrefix}${uniqueSuffix}', 18)
var generatedAppServicePlanName = empty(appServicePlanName) ? '${take(safePrefix, 20)}-asp' : appServicePlanName
var generatedWebAppName = empty(webAppName) ? take('${compactPrefix}app', 60) : webAppName
var generatedAppInsightsName = empty(appInsightsName) ? '${take(safePrefix, 18)}-appi' : appInsightsName
var generatedLogAnalyticsWorkspaceName = empty(logAnalyticsWorkspaceName) ? '${take(safePrefix, 18)}-log' : logAnalyticsWorkspaceName
var generatedKeyVaultName = empty(keyVaultName) ? take('${compactPrefix}kv', 24) : keyVaultName
var generatedSqlServerName = empty(sqlServerName) ? take('${compactPrefix}sql', 63) : sqlServerName
var generatedAiFoundryName = empty(aiFoundryName) ? take('${compactPrefix}ai', 64) : aiFoundryName
var effectiveAiCustomSubdomain = empty(aiFoundryCustomSubdomain) ? generatedAiFoundryName : aiFoundryCustomSubdomain
var sqlPassword = empty(sqlAdminPassword) ? 'Sql!${take(uniqueString(subscription().id, resourceGroup().id, generatedSqlServerName, sqlDatabaseName), 16)}Aa1' : sqlAdminPassword

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: generatedLogAnalyticsWorkspaceName
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
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: generatedAppInsightsName
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
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: generatedKeyVaultName
  location: location
  properties: {
    tenantId: azureTenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: false
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableRbacAuthorization: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    accessPolicies: [
      {
        tenantId: azureTenantId
        objectId: keyVaultAdminObjectId
        permissions: {
          secrets: [
            'get'
            'set'
            'list'
            'delete'
            'backup'
            'restore'
            'purge'
          ]
          keys: [
            'get'
            'list'
            'create'
            'delete'
            'update'
            'purge'
          ]
        }
      }
    ]
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    Environment: environment
    School: schoolName
    Project: 'SchoolGPT'
    Purpose: 'Secure Configuration Storage'
    ManagedBy: 'Bicep'
  }
}

resource servicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: generatedAppServicePlanName
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
  }
}

resource aiFoundry 'Microsoft.CognitiveServices/accounts@2024-10-01' = if (deployAiFoundry) {
  name: generatedAiFoundryName
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: effectiveAiCustomSubdomain
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    Environment: environment
    School: schoolName
    Project: 'SchoolGPT'
    Purpose: 'Azure AI Foundry'
    ManagedBy: 'Bicep'
  }
}

resource raiPolicy 'Microsoft.CognitiveServices/accounts/raiPolicies@2024-10-01' = if (deployAiFoundry && !empty(raiPolicyName)) {
  name: raiPolicyName
  parent: aiFoundry
  properties: {
    basePolicyName: 'Microsoft.Default'
    mode: 'Blocking'
    contentFilters: [
      {
        name: 'Hate'
        severityThreshold: 'High'
        source: 'Prompt'
        enabled: true
        blocking: true
      }
      {
        name: 'Hate'
        severityThreshold: 'High'
        source: 'Completion'
        enabled: true
        blocking: true
      }
      {
        name: 'Sexual'
        severityThreshold: 'High'
        source: 'Prompt'
        enabled: true
        blocking: true
      }
      {
        name: 'Sexual'
        severityThreshold: 'High'
        source: 'Completion'
        enabled: true
        blocking: true
      }
      {
        name: 'Violence'
        severityThreshold: 'High'
        source: 'Prompt'
        enabled: true
        blocking: true
      }
      {
        name: 'Violence'
        severityThreshold: 'High'
        source: 'Completion'
        enabled: true
        blocking: true
      }
      {
        name: 'SelfHarm'
        severityThreshold: 'High'
        source: 'Prompt'
        enabled: true
        blocking: true
      }
      {
        name: 'SelfHarm'
        severityThreshold: 'High'
        source: 'Completion'
        enabled: true
        blocking: true
      }
    ]
  }
}

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = if (deployAiFoundry) {
  name: aiDeploymentName
  parent: aiFoundry
  sku: {
    name: aiDeploymentSkuName
    capacity: aiDeploymentCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: aiModelName
      version: aiModelVersion
    }
    raiPolicyName: empty(raiPolicyName) ? null : raiPolicyName
  }
}

var effectiveAiEndpoint = deployAiFoundry ? aiFoundry!.properties.endpoint : existingAiFoundryEndpoint
var effectiveAiFoundryName = deployAiFoundry ? generatedAiFoundryName : existingAiFoundryResourceName

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: generatedWebAppName
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
      appSettings: [
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'NODE_ENV'
          value: 'production'
        }
        {
          name: 'PORT'
          value: '8080'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'AZURE_OPENAI_ENDPOINT'
          value: effectiveAiEndpoint
        }
        {
          name: 'AZURE_OPENAI_DEPLOYMENT'
          value: aiDeploymentName
        }
        {
          name: 'AZURE_OPENAI_API_VERSION'
          value: azureOpenAiApiVersion
        }
      ]
    }
  }
  tags: {
    Environment: environment
    School: schoolName
    Project: 'SchoolGPT'
    Purpose: 'AI Chat Application'
    TargetAudience: 'Students Under 16'
    ManagedBy: 'Bicep'
  }
}

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: generatedSqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlPassword
    version: '12.0'
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    Environment: environment
    School: schoolName
    Project: 'SchoolGPT'
    Purpose: 'SQL Server'
    ManagedBy: 'Bicep'
  }
}

resource sqlAzureAdAdmin 'Microsoft.Sql/servers/administrators@2023-08-01-preview' = if (!empty(sqlAzureAdAdminLogin) && !empty(sqlAzureAdAdminObjectId)) {
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

var sqlConnectionString = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabaseName};Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'

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
  dependsOn: [
    sqlDatabase
  ]
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
    value: sqlPassword
  }
}

resource deployedAiFoundry 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = if (deployAiFoundry && autoGrantAiAccess) {
  name: generatedAiFoundryName
}

resource deployedAiUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployAiFoundry && autoGrantAiAccess && !empty(effectiveAiFoundryName)) {
  name: guid(resourceGroup().id, webApp.id, effectiveAiFoundryName, 'openai-user')
  scope: deployedAiFoundry
  properties: {
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
  }
}

output resourceGroupName string = resourceGroup().name
output webAppName string = generatedWebAppName
output frontendUrl string = 'https://${webApp.properties.defaultHostName}'
output keyVaultName string = generatedKeyVaultName
output sqlServerName string = generatedSqlServerName
output sqlDatabaseName string = sqlDatabaseName
output azureOpenAiEndpoint string = effectiveAiEndpoint
output azureOpenAiDeployment string = aiDeploymentName
output webAppPrincipalId string = webApp.identity.principalId
