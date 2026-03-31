# SchoolGPT Bicep Deployment Guide

## Purpose

This guide explains how the SchoolGPT Bicep workstream is structured, how to configure it, how to deploy it through GitHub Actions, what to check after deployment, and how to destroy the environment safely.

## What This Bicep Path Deploys

The Bicep deployment is split into component files and the pipeline runs them in order.

Deployment order:

1. monitoring
2. security
3. data
4. AI Foundry
5. app service
6. app config and secrets

Component files:

1. `bicep/components/01-monitoring.bicep`
2. `bicep/components/02-security.bicep`
3. `bicep/components/03-data.bicep`
4. `bicep/components/04-ai-foundry.bicep`
5. `bicep/components/05-app-service.bicep`
6. `bicep/components/06-app-config.bicep`

## Workflows

### `B01 - Deploy AI Foundry (Bicep)`

Use this when you only want to create or update the AI Foundry account and model deployment.

### `B02 - Deploy Infrastructure (Bicep)`

Use this when you want to deploy or update the full infrastructure stack without building and publishing the application package.

### `B03 - Deploy Full App (Bicep)`

Use this when you want the full tested flow:

1. deploy infrastructure
2. build the frontend and backend
3. package the backend app
4. publish to Azure Web App

### `B04 - Destroy Bicep Environment`

Use this to delete the resource group and all resources inside it.

## Required GitHub Secrets

### Required

1. `AZURE_CREDENTIALS`
2. `AZURE_TENANT_ID`
3. `KEY_VAULT_ADMIN_OBJECT_ID`

### Recommended

1. `SQL_ADMIN_PASSWORD`

### Existing optional secrets already in the repo

These are not required by the Bicep workflows themselves but may still exist for other deployment paths.

1. `AZURE_WEBAPP_PUBLISH_PROFILE`
2. `ACR_LOGIN_SERVER`

## Meaning Of Each Secret

### `AZURE_CREDENTIALS`

JSON used by `azure/login@v2` to authenticate.

Expected structure:

```json
{
  "clientId": "...",
  "clientSecret": "...",
  "subscriptionId": "...",
  "tenantId": "..."
}
```

### `AZURE_TENANT_ID`

The Entra tenant ID used for Key Vault and optional SQL Entra admin configuration.

### `KEY_VAULT_ADMIN_OBJECT_ID`

The Entra object ID that should receive Key Vault access policy permissions.

Important:

1. this must be an object ID GUID
2. this is not the same as `clientId`
3. if you use the deployment service principal, use the service principal object ID, not the app registration ID

### `SQL_ADMIN_PASSWORD`

If this secret exists, the workflows use it for Azure SQL.
If it does not exist, the workflow generates a deterministic password per environment.

## Azure Prerequisites

Before running the workflows, confirm the Azure service principal in `AZURE_CREDENTIALS` can:

1. create and delete resource groups
2. create App Service plans and web apps
3. create Key Vaults and set secrets
4. create Azure SQL servers and databases
5. create Log Analytics and Application Insights
6. create Cognitive Services / AI Foundry resources
7. create role assignments

## Frontend Auth Prerequisites

The frontend currently uses checked-in Vite auth values from `app/Frontend/.env` during the GitHub build unless you change the build strategy.

Current auth values in the repo include:

1. `VITE_AZURE_CLIENT_ID`
2. `VITE_AZURE_TENANT_ID`

The frontend MSAL config defaults the redirect URI to `window.location.origin`.

That means after each deployment you must ensure the Entra app registration contains the deployed web app URL as a redirect URI.

Example deployed URL:

```text
https://schoolgpttbeb39dapp.azurewebsites.net
```

If you skip this, sign-in fails with `AADSTS50011` redirect URI mismatch.

## First-Time Setup Checklist

1. add the GitHub secrets listed above
2. confirm the service principal has the required Azure permissions
3. decide the Azure region and environment name
4. choose a short `name_prefix` using only letters and numbers
5. confirm the chosen region supports your Azure OpenAI model deployment
6. make sure the Entra app registration redirect URIs will include the final deployed app URL

## Recommended Deployment Order

### 1. Test AI Foundry only if needed

Run `B01 - Deploy AI Foundry (Bicep)` if you want to validate only the AI stack.

### 2. Deploy infrastructure

Run `B02 - Deploy Infrastructure (Bicep)` to validate the full infrastructure without packaging the application.

### 3. Deploy the full app

Run `B03 - Deploy Full App (Bicep)` after infrastructure is known-good.

## Recommended Inputs For A First Test

Use values like these for a first end-to-end test:

1. `resource_group_name`: `schoolgpt-production-rg`
2. `location`: `uksouth`
3. `school_name`: `Example School`
4. `environment`: `production`
5. `name_prefix`: `schoolgptt`
6. `deploy_ai_foundry`: `true`
7. `existing_ai_foundry_endpoint`: leave empty
8. `ai_deployment_name`: `gpt-4o`
9. `ai_model_name`: `gpt-4o`
10. `ai_model_version`: `2024-11-20`
11. `app_service_sku`: `B2`
12. `sql_sku_name`: `S1`

## What The Infrastructure Workflow Actually Does

### Name generation

The workflows generate deterministic resource names from:

1. `resource_group_name`
2. `name_prefix`

This keeps reruns stable and avoids new names on every deployment.

### Resource group

The workflow creates the target resource group before running any component deployment.

### Monitoring

Deploys:

1. Log Analytics workspace
2. Application Insights

### Security

Deploys:

1. Key Vault
2. access policy for the configured object ID

### Data

Deploys:

1. Azure SQL server
2. Azure SQL database
3. firewall rule allowing Azure services

### AI Foundry

Deploys:

1. AI Foundry account
2. RAI policy
3. model deployment

### App Service

Deploys:

1. Linux App Service plan
2. Linux Web App with system-assigned managed identity

### App Config

Deploys:

1. web app app settings
2. SQL connection string secret in Key Vault
3. SQL admin password secret in Key Vault
4. `Cognitive Services OpenAI User` role assignment for the web app identity when AI Foundry is deployed in the same environment

## Post-Deployment Checks

After `B03` completes, check the following:

1. the web app URL loads successfully
2. Entra sign-in works
3. the deployed app URL is present in the Entra app registration redirect URIs
4. chat requests succeed against AI Foundry
5. Azure SQL tables are created on first application startup if the app reaches the database successfully

## Common Issues And Fixes

### Key Vault access policy object ID is invalid

Cause:

The configured `KEY_VAULT_ADMIN_OBJECT_ID` is not an Entra object ID.

Fix:

Use the correct service principal object ID or user object ID.

### AI Foundry name or subdomain already exists

Cause:

AI Foundry naming is global.

Fix:

Change the prefix or resource group name so the generated AI Foundry name changes.

### Azure OpenAI model is not available in the region

Cause:

Model availability differs by region.

Fix:

Use a supported region or a supported model/version.

### App Service SKU quota issues

Cause:

The subscription or region does not allow the requested SKU.

Fix:

Change `app_service_sku` or request a quota increase.

### Sign-in redirect URI mismatch

Cause:

The deployed web app URL is missing from the Entra app registration.

Fix:

Add the deployed URL to the app registration redirect URIs.

### Existing AI Foundry endpoint mode

If `deploy_ai_foundry` is `false`, set `existing_ai_foundry_endpoint` and ensure the web app identity has access to that external AI Foundry account.

## Destroying The Environment

Use `B04 - Destroy Bicep Environment`.

Inputs:

1. `resource_group_name`: the resource group to delete
2. `location`: only used to target the same Azure context cleanly
3. `confirm_destroy`: must be exactly `DELETE`
4. `wait_for_completion`: choose whether the workflow waits for deletion to finish

This workflow deletes the entire resource group, so it removes:

1. monitoring resources
2. Key Vault
3. SQL resources
4. AI Foundry
5. App Service
6. all child resources inside that resource group

Do not use this workflow on a shared resource group.

## Suggested Team Usage

For day-to-day use:

1. use `B02` for infrastructure changes
2. use `B03` for a full app deployment after frontend or backend code changes
3. use `B01` for isolated AI Foundry work
4. use `B04` only for teardown of dedicated environments

## Status

This Bicep path has been tested successfully end-to-end in GitHub Actions, including:

1. infrastructure deployment
2. AI Foundry deployment
3. full app deployment
4. sign-in after app registration redirect URI correction
