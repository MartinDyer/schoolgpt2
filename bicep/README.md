# SchoolGPT Bicep Deployment

This folder is the native Bicep workstream that sits alongside the existing Terraform code.

## What It Covers

- full SchoolGPT infrastructure in native Bicep
- Azure AI Foundry account and model deployment in native Bicep
- step-by-step GitHub Actions workflows that call one Bicep file per component

## Component Files

- `components/01-monitoring.bicep`
- `components/02-security.bicep`
- `components/03-data.bicep`
- `components/04-ai-foundry.bicep`
- `components/05-app-service.bicep`
- `components/06-app-config.bicep`

## Deployment Model

The pipelines create the resource group first, generate the shared resource names once, and then deploy each component in order.

- `B01 - Deploy AI Foundry (Bicep)`: deploy only the AI Foundry component
- `B02 - Deploy Infrastructure (Bicep)`: deploy all infrastructure components in sequence
- `B03 - Deploy Full App (Bicep)`: deploy infrastructure components, then build and publish the app

## Notes

- Terraform remains in the repo and is not replaced.
- The Bicep path is pipeline-first and avoids Azure Verified Modules.
- The app config step wires together AI Foundry, SQL, Application Insights, Key Vault, and App Service after the earlier components exist.
