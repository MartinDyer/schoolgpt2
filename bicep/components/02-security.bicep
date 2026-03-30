targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environment string = 'production'
param schoolName string = 'SchoolGPT'
param azureTenantId string
param keyVaultName string
param keyVaultAdminObjectId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: azureTenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: false
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableRbacAuthorization: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    accessPolicies: [
      {
        tenantId: azureTenantId
        objectId: keyVaultAdminObjectId
        permissions: {
          secrets: [
            'get'
            'set'
            'list'
            'delete'
            'backup'
            'restore'
            'purge'
          ]
          keys: [
            'get'
            'list'
            'create'
            'delete'
            'update'
            'purge'
          ]
        }
      }
    ]
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    Environment: environment
    School: schoolName
    Project: 'SchoolGPT'
    Purpose: 'Secure Configuration Storage'
    ManagedBy: 'Bicep'
    Component: 'Security'
  }
}

output keyVaultName string = keyVault.name
