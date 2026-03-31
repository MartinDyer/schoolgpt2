# SchoolGPT Bicep Setup Guide

## Goal

Use this guide when setting up the Bicep deployment path for a new repo, new developer, or new Azure subscription.

## 1. GitHub Repository Secrets

Add these secrets under `Settings -> Secrets and variables -> Actions`.

### Required

1. `AZURE_CREDENTIALS`
2. `AZURE_TENANT_ID`
3. `KEY_VAULT_ADMIN_OBJECT_ID`

### Recommended

1. `SQL_ADMIN_PASSWORD`

## 2. Azure Credentials JSON

`AZURE_CREDENTIALS` must contain:

```json
{
  "clientId": "...",
  "clientSecret": "...",
  "subscriptionId": "...",
  "tenantId": "..."
}
```

## 3. Key Vault Admin Object ID

This must be an Entra object ID.

If you want to use the deployment service principal itself, get the object ID using:

```bash
az ad sp show --id "<clientId>" --query id -o tsv
```

Do not use:

1. tenant ID
2. subscription ID
3. application `clientId`

## 4. Required Azure Permissions

The deployment principal should be able to manage:

1. resource groups
2. App Service
3. Azure SQL
4. Key Vault
5. Application Insights and Log Analytics
6. Cognitive Services / AI Foundry
7. role assignments

## 5. Entra App Registration For Frontend Sign-In

The frontend build uses the Vite auth values currently stored in `app/Frontend/.env`.

At minimum, make sure the matching Entra app registration contains the deployed site URL as a redirect URI.

Example:

```text
https://schoolgpttbeb39dapp.azurewebsites.net
```

Without this, sign-in will fail with redirect URI mismatch.

## 6. Recommended First Run Order

1. `B02 - Deploy Infrastructure (Bicep)`
2. `B03 - Deploy Full App (Bicep)`

## 7. Safe Destroy

Use `B04 - Destroy Bicep Environment` only for dedicated environments where the resource group contains only SchoolGPT resources.
