param location string
param aiFoundryName string
param aiProjectName string
param raiPolicyName string

// Do NOT redeclare the account for PUT; reference it as existing
resource account 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: aiFoundryName
}

// Role assignment (still fine)
resource rgContrib 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aiFoundryName, 'rg-contrib')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalId: reference(account.id, '2025-06-01', 'full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Children — safe, because parent is "existing"
resource project 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  name: aiProjectName
  parent: account
  location: location
  properties: {
    displayName: aiProjectName
    description: 'Project provisioned via Bicep.'
  }
}

resource rai 'Microsoft.CognitiveServices/accounts/raiPolicies@2024-10-01' = {
  name: raiPolicyName
  parent: account
  properties: {
    basePolicyName: 'Microsoft.Default' // only if your region requires it
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
