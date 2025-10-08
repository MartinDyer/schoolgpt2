param aiFoundryName string
param location string
param accountKind string
param skuName string

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

output name string = aiAccount.name
output id string = aiAccount.id
