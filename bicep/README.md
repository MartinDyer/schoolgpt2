# SchoolGPT Bicep Deployment

This folder is the Bicep workstream that sits alongside the existing Terraform code.

## What It Covers

- Full SchoolGPT infrastructure in Bicep
- Azure AI Foundry account and model deployment in Bicep
- Dedicated GitHub Actions pipelines for validate, infra deploy, and full app deploy
- Parameter examples for local or pipeline-driven deployments

## Templates

- `main.bicep`: full SchoolGPT deployment at resource group scope
- `ai-foundry.bicep`: AI Foundry-only deployment at resource group scope
- `main.bicep`: full SchoolGPT deployment with native resource declarations
- `ai-foundry.bicep`: AI Foundry-only deployment with native resource declarations

## Deployment Model

The Bicep path is designed for pipelines first. The workflows create the resource group up front, then deploy these native Bicep files at resource group scope.

- `B01 - Deploy AI Foundry (Bicep)`: deploy or update only AI Foundry
- `B02 - Deploy Infrastructure (Bicep)`: deploy the full infrastructure stack
- `B03 - Deploy Full App (Bicep)`: deploy infrastructure and then publish the app package to the provisioned web app

## Notes

- Terraform remains in the repo and is not replaced.
- The Bicep workflow can either deploy AI Foundry itself or point the app at an existing AI Foundry resource.
- The web app gets the `Cognitive Services OpenAI User` role assignment automatically when `autoGrantAiAccess` is enabled.
