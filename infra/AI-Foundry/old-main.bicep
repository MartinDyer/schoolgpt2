targetScope = 'resourceGroup'

@description('Azure resource group for all resources')
param rg string = 'School-Safe-GPT-RG-001'

@description('Azure region for all resources')
param location string = 'UKSouth'

@description('Name of the Azure AI Foundry (Cognitive Services) account')
param aiFoundryName string = 'school-safe-gpt-AI-Foundry'

@description('Name of the Foundry project to create under the account')
param aiProjectName string = 'school-safe-gpt-project'

@description('Name of the RAI/content filter policy to create')
param raiPolicyName string = 'high-filter'

@allowed([ 'AIServices' ])
param accountKind string = 'AIServices'

@allowed([ 'S0' ])
param skuName string = 'S0'

/* -------- Target resource group (create if needed) -------- */
// resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
//   name: resourceGroupName
//   location: location
// }

/* -------- Azure AI Foundry (account) -------- */
module aiAccountModule './aiaccount.bicep' = {
  name: 'aiAccountDeployment'
  scope: resourceGroup(rg)
  params: {
    aiFoundryName: aiFoundryName
    location: location
    accountKind: accountKind
    skuName: skuName
  }
}

/* -------- Reference the account as an existing parent -------- */
resource aiAccount 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  scope: resourceGroup(rg)
  name: aiFoundryName
}

/* -------- Foundry Project (child of account) -------- */
resource project 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  name: aiProjectName
  location: location
  properties: {
    displayName: aiProjectName
    description: 'Project provisioned via Bicep with high-severity content filtering policy available.'
  }
}

/* -------- RAI Policy (child of account) -------- */
resource raiPolicy 'Microsoft.CognitiveServices/accounts/raiPolicies@2024-10-01' = {
  name: raiPolicyName
  properties: {
    basePolicyName: raiPolicyName
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

output aiAccountId string = aiAccount.id
output projectId string   = project.id
output raiPolicyId string = raiPolicy.id
output raiPolicyNameOut string = raiPolicyName
