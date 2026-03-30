targetScope = 'resourceGroup'

@description('Azure region for the AI Foundry resource group and resources.')
param location string = 'uksouth'

@description('AI Foundry account name.')
param aiFoundryName string

@description('Custom subdomain used by the AI Foundry account.')
param aiFoundryCustomSubdomain string

@description('Model deployment name exposed to the app.')
param aiDeploymentName string = 'gpt-4o'

@description('Azure OpenAI model name to deploy.')
param aiModelName string = 'gpt-4o'

@description('Azure OpenAI model version to deploy.')
param aiModelVersion string = '2024-11-20'

@description('Deployment SKU for the Azure OpenAI deployment.')
param aiDeploymentSkuName string = 'GlobalStandard'

@description('Capacity for the Azure OpenAI deployment.')
param aiDeploymentCapacity int = 1

@description('Optional RAI policy name. Leave empty to skip custom policy creation.')
param raiPolicyName string = 'schoolgpt-default-rai'

@description('Environment name used in tags.')
param environment string = 'production'

@description('School name used in tags.')
param schoolName string = 'SchoolGPT'

resource aiFoundry 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: aiFoundryName
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: aiFoundryCustomSubdomain
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    Environment: environment
    Project: 'SchoolGPT'
    School: schoolName
    ManagedBy: 'Bicep'
    Workstream: 'AI-Foundry'
  }
}

resource raiPolicy 'Microsoft.CognitiveServices/accounts/raiPolicies@2024-10-01' = if (!empty(raiPolicyName)) {
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

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
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

output resourceGroupName string = resourceGroup().name
output aiFoundryName string = aiFoundry.name
output azureOpenAiEndpoint string = aiFoundry.properties.endpoint
output azureOpenAiDeployment string = aiDeploymentName
output raiPolicyName string = empty(raiPolicyName) ? '' : raiPolicyName
