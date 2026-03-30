# SchoolGPT Bicep Deployment Guide

## Goal

This Bicep path reproduces the Terraform deployment in a separate workstream so the project can move to Azure-native infrastructure deployment without deleting the old Terraform implementation.

## Pipeline Entry Points

### 1. Deploy AI Foundry only

Use workflow `B01 - Deploy AI Foundry (Bicep)` when you want to create or update the Azure AI Foundry account and model deployment independently.

### 2. Deploy infrastructure

Use workflow `B02 - Deploy Infrastructure (Bicep)` when you want to provision the full hosting stack:

- resource group
- App Service plan
- Linux web app
- Log Analytics workspace
- Application Insights
- Key Vault
- Azure SQL server and database
- optional AI Foundry and role assignment

### 3. One-click full deployment

Use workflow `B03 - Deploy Full App (Bicep)` to:

1. deploy infrastructure with Bicep
2. build the frontend and backend
3. publish the packaged Node app to Azure Web App

## Required GitHub Secrets

- `AZURE_CREDENTIALS`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_TENANT_ID`
- `KEY_VAULT_ADMIN_OBJECT_ID`

## Important Parameters

- `resource_group_name`: target resource group for the school deployment. The workflow creates it before running the Bicep deployment.
- `school_name`: used in tags and generated naming
- `name_prefix`: short safe prefix for generated names
- `deploy_ai_foundry`: `true` to provision AI Foundry inside Bicep, `false` to use an existing resource
- `existing_ai_foundry_endpoint`: required when reusing an existing AI Foundry account
- `existing_ai_foundry_resource_name`: required for automatic role assignment against an existing AI Foundry account

## Outputs Used By Pipelines

- `resourceGroupName`
- `webAppName`
- `frontendUrl`
- `azureOpenAiEndpoint`
- `azureOpenAiDeployment`
- `webAppPrincipalId`

## Known Azure/Bicep Notes

1. AI Foundry naming is global. Reused names or custom subdomains will fail.
2. App Service plan quotas vary per subscription and region. Basic and Standard SKUs may be blocked even when Premium is available.
3. AI model deployment availability is region-specific. If `gpt-4o` is not available in the selected region, change the model or region.
4. SQL server and Key Vault names are also globally unique. Use a short prefix in pipelines.
5. Role assignment propagation for the web app managed identity may take a couple of minutes after deployment.
6. When you point the app at an existing AI Foundry account, automatic role assignment is not attempted by this Bicep path. Grant `Cognitive Services OpenAI User` manually if needed.
