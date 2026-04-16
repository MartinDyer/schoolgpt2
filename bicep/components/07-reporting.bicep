targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environmentName string = 'production'
param schoolName string = 'SchoolGPT'
param reportingStorageAccountName string
param reportingPlanName string
param reportingFunctionAppName string
param appInsightsName string
param reportingPlanSku string = 'B1'

@secure()
param sqlConnectionString string

param schoolTimezone string = 'Europe/London'
param reportingApiBase string = ''

@secure()
param reportingApiKey string = ''

param dslEmail string
param summaryEmails string = ''
param leadershipEmails string = ''
param teacherSummaryEmails string = ''
param enableCsvExport bool = true
param csvExportThreshold int = 10
param emailProvider string = 'azure_communication_services'

@secure()
param emailProviderApiKey string = ''

@secure()
param acsConnectionString string = ''

param emailFrom string = 'noreply@schoolgpt.local'
param dslReportSchedule string = '0 0 7 * * *'
param usageReportSchedule string = '0 0 8 * * *'
param keywordReportSchedule string = '0 0 7 * * 1'
param leadershipReportSchedule string = '0 0 9 * * 1'
param teacherSummarySchedule string = '0 30 8 * * 1-5'
param retentionReportSchedule string = '0 0 3 * * 0'
param reportingInitialWatermark string = '2026-01-01T00:00:00Z'
param keywordWatchTerms string = 'self-harm,violence,abuse'
param dslMinSeverity string = 'medium'
param reportingAuditRetentionDays int = 90

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: reportingStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: {
    Environment: environmentName
    School: schoolName
    Project: 'SchoolGPT'
    Component: 'Reporting-Storage'
    ManagedBy: 'Bicep'
  }
}

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: reportingPlanName
  location: location
  sku: {
    name: reportingPlanSku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
  tags: {
    Environment: environmentName
    School: schoolName
    Project: 'SchoolGPT'
    Component: 'Reporting-Plan'
    ManagedBy: 'Bicep'
  }
}

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: reportingFunctionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'Python|3.11'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'false'
        }
        {
          name: 'ENABLE_ORYX_BUILD'
          value: 'false'
        }
        {
          name: 'SQL_CONNECTION_STRING'
          value: sqlConnectionString
        }
        {
          name: 'SCHOOL_NAME'
          value: schoolName
        }
        {
          name: 'SCHOOL_TIMEZONE'
          value: schoolTimezone
        }
        {
          name: 'REPORTING_API_BASE'
          value: reportingApiBase
        }
        {
          name: 'REPORTING_API_KEY'
          value: reportingApiKey
        }
        {
          name: 'DSL_EMAIL'
          value: dslEmail
        }
        {
          name: 'SUMMARY_EMAILS'
          value: summaryEmails
        }
        {
          name: 'LEADERSHIP_EMAILS'
          value: leadershipEmails
        }
        {
          name: 'TEACHER_SUMMARY_EMAILS'
          value: teacherSummaryEmails
        }
        {
          name: 'ENABLE_CSV_EXPORT'
          value: string(enableCsvExport)
        }
        {
          name: 'CSV_EXPORT_THRESHOLD'
          value: string(csvExportThreshold)
        }
        {
          name: 'EMAIL_PROVIDER'
          value: emailProvider
        }
        {
          name: 'EMAIL_PROVIDER_API_KEY'
          value: emailProviderApiKey
        }
        {
          name: 'ACS_CONNECTION_STRING'
          value: acsConnectionString
        }
        {
          name: 'EMAIL_FROM'
          value: emailFrom
        }
        {
          name: 'DSL_REPORT_SCHEDULE'
          value: dslReportSchedule
        }
        {
          name: 'USAGE_REPORT_SCHEDULE'
          value: usageReportSchedule
        }
        {
          name: 'KEYWORD_REPORT_SCHEDULE'
          value: keywordReportSchedule
        }
        {
          name: 'LEADERSHIP_REPORT_SCHEDULE'
          value: leadershipReportSchedule
        }
        {
          name: 'TEACHER_SUMMARY_SCHEDULE'
          value: teacherSummarySchedule
        }
        {
          name: 'RETENTION_REPORT_SCHEDULE'
          value: retentionReportSchedule
        }
        {
          name: 'REPORTING_INITIAL_WATERMARK'
          value: reportingInitialWatermark
        }
        {
          name: 'KEYWORD_WATCH_TERMS'
          value: keywordWatchTerms
        }
        {
          name: 'DSL_MIN_SEVERITY'
          value: dslMinSeverity
        }
        {
          name: 'REPORTING_AUDIT_RETENTION_DAYS'
          value: string(reportingAuditRetentionDays)
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
      ]
    }
  }
  tags: {
    Environment: environmentName
    School: schoolName
    Project: 'SchoolGPT'
    Component: 'Reporting-Function'
    ManagedBy: 'Bicep'
    Purpose: 'Safeguarding Reporting'
  }
}

output reportingFunctionAppName string = functionApp.name
output reportingFunctionPrincipalId string = functionApp.identity.principalId
output reportingStorageAccountName string = storageAccount.name
