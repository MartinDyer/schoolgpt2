targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environment string = 'production'
param schoolName string = 'SchoolGPT'
param aiFoundryName string
param aiFoundryCustomSubdomain string
param aiDeploymentName string = 'gpt-4o'
param aiModelName string = 'gpt-4o'
param aiModelVersion string = '2024-11-20'
param aiDeploymentSkuName string = 'GlobalStandard'
param aiDeploymentCapacity int = 1
param raiPolicyName string = 'schoolgpt-default-rai'

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
    School: schoolName
    Project: 'SchoolGPT'
    Purpose: 'Azure AI Foundry'
    ManagedBy: 'Bicep'
    Component: 'AI-Foundry'
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

output aiFoundryName string = aiFoundry.name
output azureOpenAiEndpoint string = aiFoundry.properties.endpoint
output azureOpenAiDeployment string = aiDeploymentName
