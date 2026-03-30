# SchoolGPT Bicep Deployment Guide

## Goal

This Bicep path reproduces the Terraform deployment in a separate workstream so the project can move to Azure-native infrastructure deployment without deleting the old Terraform implementation.

## Structure

The deployment is split into component files and the pipeline calls them one by one instead of using one large deployment file.

Deployment order:

1. monitoring
2. security
3. data
4. AI Foundry
5. app service
6. app config and secrets

## Pipeline Entry Points

### 1. Deploy AI Foundry only

Use workflow `B01 - Deploy AI Foundry (Bicep)` when you only want to create or update the AI Foundry account and model deployment.

### 2. Deploy infrastructure

Use workflow `B02 - Deploy Infrastructure (Bicep)` when you want to provision the full hosting stack component-by-component.

### 3. One-click full deployment

Use workflow `B03 - Deploy Full App (Bicep)` to:

1. deploy infrastructure components with Bicep
2. build the frontend and backend
3. publish the packaged Node app to Azure Web App

## Required GitHub Secrets

- `AZURE_CREDENTIALS`
- `AZURE_TENANT_ID`
- `KEY_VAULT_ADMIN_OBJECT_ID`
- `SQL_ADMIN_PASSWORD` optional but recommended

## Important Parameters

- `resource_group_name`: target resource group for the school deployment. The workflow creates it before running the Bicep steps.
- `school_name`: used in tags
- `name_prefix`: short safe prefix for generated names
- `deploy_ai_foundry`: `true` to provision AI Foundry in the pipeline, `false` to use an existing endpoint
- `existing_ai_foundry_endpoint`: required when reusing an existing AI Foundry account

## Known Azure Notes

1. AI Foundry naming is global. Reused names or custom subdomains will fail.
2. App Service plan quotas vary per subscription and region. Basic and Standard SKUs may be blocked even when Premium is available.
3. AI model deployment availability is region-specific. If `gpt-4o` is not available in the selected region, change the model or region.
4. SQL server and Key Vault names are globally unique, so the workflow generates safe deterministic names from the resource group and prefix.
5. Role assignment propagation for the web app managed identity may take a couple of minutes after deployment.
6. When you point the app at an existing AI Foundry account, grant `Cognitive Services OpenAI User` manually if needed.
