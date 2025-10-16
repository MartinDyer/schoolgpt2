targetScope = 'resourceGroup'

@description('Region')
param location string

@description('Cognitive Services account (Azure AI Foundry) name')
param aiFoundryName string

@description('Project name')
param aiProjectName string

@description('RAI policy name')
param raiPolicyName string

// Parent account
resource account 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: aiFoundryName
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

// Child: Project (note: parent + short name)
resource project 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  name: aiProjectName
  parent: account
  // some child types inherit location; if required, keep it:
  location: location
  properties: {
    displayName: aiProjectName
    description: 'Project provisioned via Bicep.'
  }
}

// Child: RAI policy
resource rai 'Microsoft.CognitiveServices/accounts/raiPolicies@2024-10-01' = {
  name: raiPolicyName
  parent: account
  properties: {
    //basePolicyName: 'Default' // usually a known base; avoid echoing the custom name
    mode: 'Blocking'
    contentFilters: [
      { name: 'Hate',     severityThreshold: 'High', source: 'Prompt',     enabled: true, blocking: true }
      { name: 'Hate',     severityThreshold: 'High', source: 'Completion', enabled: true, blocking: true }
      { name: 'Sexual',   severityThreshold: 'High', source: 'Prompt',     enabled: true, blocking: true }
      { name: 'Sexual',   severityThreshold: 'High', source: 'Completion', enabled: true, blocking: true }
      { name: 'Violence', severityThreshold: 'High', source: 'Prompt',     enabled: true, blocking: true }
      { name: 'Violence', severityThreshold: 'High', source: 'Completion', enabled: true, blocking: true }
      { name: 'SelfHarm', severityThreshold: 'High', source: 'Prompt',     enabled: true, blocking: true }
      { name: 'SelfHarm', severityThreshold: 'High', source: 'Completion', enabled: true, blocking: true }
    ]
  }
}

output aiAccountId string = account.id
output projectId  string = project.id
output raiPolicyId string = rai.id
