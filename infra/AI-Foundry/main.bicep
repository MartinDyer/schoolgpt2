@description('Azure region for all resources')
param location string = 'UKSouth'

@description('Name of the Azure AI Foundry (Cognitive Services) account')
param aiFoundryName string = 'School-Safe-GPT-${uniqueString(resourceGroup().id)}'

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
@allowed([
  'S0'
])
param skuName string = 'S0'

/* ------------------------------
   Azure AI Foundry (account)
---------------------------------*/
resource aiAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: aiFoundryName
  location: location
  kind: accountKind
  sku: {
    name: skuName
  }
  properties: {
    // Set optional flags as needed.
    // disableLocalAuth: true
    publicNetworkAccess: 'Enabled' // or 'Disabled' if using Private Link
  }
}

/* ------------------------------
   Foundry Project (child of account)
---------------------------------*/
resource project 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  name: '${aiAccount.name}/${aiProjectName}'
  location: location
  properties: {
    displayName: aiProjectName
    description: 'Project provisioned via Bicep with high-severity content filtering policy available.'
  }
}

/* ------------------------------
   RAI Policy (Content Filters)
   Applies HIGH severity filtering to both Prompt & Completion
   Categories: Hate, Sexual, Violence, SelfHarm
   Mode: Blocking (enforce synchronous blocking)
---------------------------------*/
resource raiPolicy 'Microsoft.CognitiveServices/accounts/raiPolicies@2025-06-01' = {
  name: '${aiAccount.name}/${raiPolicyName}'
  properties: {
    basePolicyName: raiPolicyName
    mode: 'Blocking' // or 'Asynchronous_filter' per org preference
    contentFilters: [
      // Hate
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

      // Sexual
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

      // Violence
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

      // Self-harm
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

    // Optional: attach custom blocklists later, e.g. for specific phrases.
    // customBlocklists: [
    //   {
    //     blocklistName: 'my-phrases'
    //     source: 'Prompt'
    //     blocking: true
    //   }
    // ]
  }
}

/* ------------------------------
   (Optional) Example: attach the policy when you deploy a model
   Uncomment & parameterize if you want to deploy a model now.
   Resource type supports `properties.raiPolicyName`.
   Docs: Microsoft.CognitiveServices/accounts/deployments
---------------------------------*/
// @description('Name of an example deployment (uncomment to use)')
// param deploymentName string = 'gpt-4o-mini'
//
// resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
//   name: '${aiAccount.name}/${deploymentName}'
//   sku: {
//     name: 'GlobalStandard' // depends on model & region
//     capacity: 1
//   }
//   properties: {
//     model: {
//       name: 'gpt-4o-mini'  // ensure availability in your region
//       publisher: 'OpenAI'
//       format: 'OpenAI'
//       version: 'latest'
//     }
//     raiPolicyName: raiPolicyName
//   }
// }

/* ------------------------------
   Outputs
---------------------------------*/
output aiAccountId string = aiAccount.id
output projectId string = project.id
output raiPolicyId string = raiPolicy.id
output raiPolicyNameOut string = raiPolicyName
