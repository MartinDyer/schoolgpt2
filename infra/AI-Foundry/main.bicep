targetScope = 'resourceGroup'

@description('Azure region for all resources')
param location string = 'UKSouth'

@description('Name of the Azure AI Foundry (Cognitive Services) account')
param aiFoundryName string = 'school-safe-gpt-${uniqueString(resourceGroup().id)}'

@description('Name of the Foundry project to create under the account')
param aiProjectName string = 'school-safe-gpt-project'

@description('Name of the RAI/content filter policy to create')
param raiPolicyName string = 'high-filter'

@allowed([
  'AIServices'
])
@description('Account kind for Azure AI Foundry (multi-service) resources')
param accountKind string = 'AIServices'

@description('SKU name for the Cognitive Services account')
@allowed([ 'S0' ])
param skuName string = 'S0'

/* -------- Azure AI Foundry (account) -------- */
module aiAccountModule './aiAccount.bicep' = {
  name: 'aiAccountDeployment'
  // NOTE: no `scope:` here — we're at RG scope already
  params: {
    aiFoundryName: aiFoundryName
    location: location
    accountKind: accountKind
    skuName: skuName
  }
}

/* -------- Reference the account as an existing parent -------- */
resource aiAccount 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  name: aiFoundryName
}

/* -------- Foundry Project (child of account) -------- */
resource project 'Microsoft.CognitiveServices/accounts/projects@2024-10-01' = {
  name: aiProjectName
  parent: aiAccount
  location: location
  properties: {
    displayName: aiProjectName
    description: 'Project provisioned via Bicep with high-severity content filtering policy available.'
  }
}

/* -------- RAI Policy (child of account) -------- */
resource raiPolicy 'Microsoft.CognitiveServices/accounts/raiPolicies@2024-10-01' = {
  name: raiPolicyName
  parent: aiAccount
  properties: {
    basePolicyName: raiPolicyName
    mode: 'Blocking'
    contentFilters: [
      { name: 'Hate',      severityThreshold: 'High', source: 'Prompt',     enabled: true, blocking: true }
      { name: 'Hate',      severityThreshold: 'High', source: 'Completion', enabled: true, blocking: true }
      { name: 'Sexual',    severityThreshold: 'High', source: 'Prompt',     enabled: true, blocking: true }
      { name: 'Sexual',    severityThreshold: 'High', source: 'Completion', enabled: true, blocking: true }
      { name: 'Violence',  severityThreshold: 'High', source: 'Prompt',     enabled: true, blocking: true }
      { name: 'Violence',  severityThreshold: 'High', source: 'Completion', enabled: true, blocking: true }
      { name: 'SelfHarm',  severityThreshold: 'High', source: 'Prompt',     enabled: true, blocking: true }
      { name: 'SelfHarm',  severityThreshold: 'High', source: 'Completion', enabled: true, blocking: true }
    ]
  }
}

output aiAccountId string = aiAccount.id
output projectId string   = project.id
output raiPolicyId string = raiPolicy.id
output raiPolicyNameOut string = raiPolicyName
