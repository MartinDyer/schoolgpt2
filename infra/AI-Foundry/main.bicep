targetScope = 'resourceGroup'

param location string
param aiFoundryName string
param aiProjectName string
param raiPolicyName string
@description('Optional: base policy name if your region requires one')
param basePolicyName string = ''

// 1) Parent account: AIServices + managed identity + project management
resource account 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: aiFoundryName
  location: location
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'           // ✅ REQUIRED
  }
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    allowProjectManagement: true     // ✅ REQUIRED to create projects
  }
}

// 2) Give the account’s managed identity permissions (Contributor on RG)
@allowed([
  'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
])
param contributorRoleId string = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource rgContrib 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aiFoundryName, 'rg-contrib')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalId: account.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// 3) Project (child)
resource project 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  name: aiProjectName
  parent: account
  location: location
  properties: {
    displayName: aiProjectName
    description: 'Project provisioned via Bicep.'
  }
  // parent: account ensures correct dependency order
}

// 4) RAI policy (child). Include basePolicyName only if your region requires it.
resource rai 'Microsoft.CognitiveServices/accounts/raiPolicies@2024-10-01' = {
  name: raiPolicyName
  parent: account
  properties: {
    mode: 'Blocking'
    if (!empty(basePolicyName)) basePolicyName: basePolicyName
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
