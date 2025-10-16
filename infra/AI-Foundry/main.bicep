targetScope = 'resourceGroup'


param location string
param aiFoundryName string
param aiProjectName string
param raiPolicyName string
@description('Unique subdomain. Only set on first creation.')
param customSubDomainName string

// 1) Create the AI Foundry with SystemAssigned identity
resource aiFoundry 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: aiFoundryName
  location: location
  kind: 'AIServices'
  sku: { name: 'S0' }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    allowProjectManagement: true
    // NOTE: only include this on first-ever creation; do NOT change later
    customSubDomainName: customSubDomainName
  }
}

// 2) (Optional but common) grant the Foundry’s identity Contributor on the RG
resource rgContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aiFoundryName, 'rg-contrib')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
    )
    principalId: aiFoundry.identity.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    aiFoundry
  ]
}

// 3) Create the Project (must depend on the account)
resource project 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  name: '${aiFoundryName}/${aiProjectName}'
  location: location
  properties: {
    displayName: aiProjectName
    description: 'Project provisioned via Bicep.'
  }
  dependsOn: [
    aiFoundry
  ]
}

// 4) (Optional) RAI policy under the account
resource rai 'Microsoft.CognitiveServices/accounts/raiPolicies@2024-10-01' = {
  name: '${aiFoundryName}/${raiPolicyName}'
  properties: {
    basePolicyName: 'Microsoft.Default'
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
  dependsOn: [
    aiFoundry
  ]
}
