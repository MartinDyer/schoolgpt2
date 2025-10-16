targetScope = 'resourceGroup'

param location string
param aiFoundryName string
param aiProjectName string
param raiPolicyName string
@description('Unique custom subdomain required before creating projects')
param customSubDomainName string = 'school-safe-gpt-AI-Foundry-002'

// 1) Parent account with SystemAssigned identity + required props
resource account 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: aiFoundryName
  location: location
  kind: 'AIServices'
  identity: {                        // ✅ REQUIRED
    type: 'SystemAssigned'
  }
  sku: { name: 'S0' }
  properties: {
    publicNetworkAccess: 'Enabled'
    allowProjectManagement: true     // required for projects
    customSubDomainName: customSubDomainName  // must be set before projects
  }
}

// 2) Give the account identity rights to the RG (Contributor is typical)
resource rgContrib 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aiFoundryName, 'rg-contrib')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
    )
    principalId: account.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// 3) Child: Project (will only run after account exists with identity)
resource project 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  name: aiProjectName
  parent: account
  location: location
  properties: {
    displayName: aiProjectName
    description: 'Project provisioned via Bicep.'
  }
}

// 4) (Optional) RAI policy child
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
