# SchoolGPT Bicep Deployment

This folder is the native Bicep workstream that sits alongside the existing Terraform code.

## What It Covers

- full SchoolGPT infrastructure in native Bicep
- Azure AI Foundry account and model deployment in native Bicep
- step-by-step GitHub Actions workflows that call one Bicep file per component
- environment teardown through a guarded destroy workflow

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
- `B04 - Destroy Bicep Environment`: delete the resource group and everything inside it

## Before You Run It

- Add GitHub Actions secrets documented in `docs/BICEP_SETUP_GUIDE.md`
- Confirm the Azure service principal has permission to create and delete resource groups, Key Vault, SQL, App Service, and Cognitive Services resources
- Confirm the frontend Entra app registration redirect URIs include the final deployed app URL if sign-in is enabled

## Notes

- Terraform remains in the repo and is not replaced.
- The Bicep path is pipeline-first and avoids Azure Verified Modules.
- The app config step wires together AI Foundry, SQL, Application Insights, Key Vault, and App Service after the earlier components exist.
- The frontend currently uses checked-in Vite auth settings from `app/Frontend/.env` at build time unless you change that build process.
