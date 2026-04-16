# Reporting Layer Deployment

This document describes the separate safeguarding reporting layer introduced for SchoolGPT and how to configure it through deployment.

## Scope

- Python Azure Functions
- Email-only reporting
- DSL daily safeguarding incident report
- Aggregate usage summary
- DSL keyword-watch reporting
- Leadership anonymised summary report
- Teacher summary/referral report
- Reporting retention cleanup
- No custom dashboard UI in this phase

## Required Inputs Per School

- `SCHOOL_NAME`
- `SCHOOL_TIMEZONE`
- `DSL_EMAIL` (**required when reporting is enabled**)
- `TEACHER_SUMMARY_EMAILS` (optional)
- `LEADERSHIP_EMAILS` (optional)
- `ENABLE_CSV_EXPORT`
- `CSV_EXPORT_THRESHOLD`
- `REPORTING_PLAN_SKU` (recommended default: `B1`)
- SQL connection string with reporting read access
- Email provider configuration
- Existing Application Insights resource from the base SchoolGPT deployment

## Runtime Notes

- Recommended provider: **Azure Communication Services**
- The reporting layer should stay a normal separate Azure Function aligned with the repo's existing deployment shape.
- The reporting layer now uses the Microsoft `mssql-python` driver to avoid OS-level ODBC setup in Azure Functions.
- The reporting layer uses a pure Python SQL Server client (`python-tds`) to avoid OS-level ODBC setup in Azure Functions.
- Reports render timestamps using `SCHOOL_TIMEZONE`.
- Detailed incident emails are DSL-only; aggregate summaries must not include raw message content.
- If `ENABLE_CSV_EXPORT=true` and flagged safeguarding incidents exceed `CSV_EXPORT_THRESHOLD`, the DSL report attaches a CSV file that staff can open in Excel.

## Canonical safeguarding incident source

For the current application architecture, incident-triggered safeguarding reporting is based on a single authoritative source:

- `dbo.FlaggedMessages`

This is the table written by the live backend moderation/blocking flow when prompts are rejected or policy-violating. Using one explicit incident source avoids ambiguity between multiple schemas and ensures DSL/teacher/keyword safeguarding notifications align with the actual blocked-message write path.

Higher-level aggregate reporting can still use summary/query views where appropriate, but **blocked-message safeguarding notifications are sourced from `FlaggedMessages`**.

## B03 Full App Deployment Setup

The preferred school onboarding path is now the existing **B03** pipeline.

When `ENABLE_REPORTING=true`, B03 asks for/accepts:

- `DSL_EMAIL` (required)
- `TEACHER_SUMMARY_EMAILS` (optional)
- `LEADERSHIP_EMAILS` (optional)
- `ENABLE_CSV_EXPORT`
- `CSV_EXPORT_THRESHOLD`
- `SCHOOL_TIMEZONE`

B03 will then:

- deploy the main student app
- deploy the separate reporting Function App
- create/reuse Azure Communication Services email resources for reporting
- generate the reporting sender address automatically
- store `acs-connection-string` and `reporting-email-from` in Key Vault
- push reporting app settings into Azure
- publish the reporting package to the Function App

This keeps reporting as a **separate layer**, but makes setup easier by configuring it during the normal school deployment flow.

## Hosting compatibility recommendation

For broad compatibility across many schools and Azure environments, the reporting layer should use a **dedicated Linux App Service plan** by default rather than Linux Consumption.

Recommended default:

- `REPORTING_PLAN_SKU=B1`

Why:

- avoids `LinuxDynamicWorkersNotAllowedInResourceGroup` failures
- works more consistently across school subscriptions and policy setups
- keeps reporting as a separate layer without changing the overall architecture

## Automated ACS handling in B03

When reporting is enabled, B03 now automates the platform email setup:

- creates or reuses the Azure Email Service
- creates or reuses the Azure-managed domain (`AzureManagedDomain`)
- creates or reuses the linked Communication Service
- creates the `reporting` sender username
- saves these Key Vault secrets automatically:
  - `acs-connection-string`
  - `reporting-email-from`

So the school/team does **not** need to know those values manually before deployment.

The only reporting values that should still be entered during deployment are the recipient emails:

- `DSL_EMAIL` (required)
- `TEACHER_SUMMARY_EMAILS` (optional)
- `LEADERSHIP_EMAILS` (optional)

## Deployment Path

Use:

- `.github/workflows/B03-deploy-bicep-full-app.yml` **(recommended for school onboarding)**
- `.github/workflows/B05-deploy-bicep-reporting.yml`

This workflow:
- installs reporting dependencies
- runs unit and integration tests
- validates `bicep/components/07-reporting.bicep`
- deploys the reporting Function App
- publishes the `reporting/` code package
- prints key deployment outputs for operators

B03 additionally:
- deploys the main application stack
- prompts for reporting recipient emails
- configures CSV/export threshold fields
- deploys the separate reporting layer in the same school rollout

## Manual Operations

For non-public manual execution, use the CLI entry point in the reporting package:

```bash
cd reporting
python manual_run.py dsl-daily
python manual_run.py usage-daily
python manual_run.py keyword-watch
```

Additional phase-2 functions now present:

```bash
# leadership summary (anonymous)
# teacher summary/referral
# retention cleanup
```

## Phase Boundary

Dashboards are not implemented here. If dashboarding is required later, the expected path is Power BI on top of the existing SQL/reporting data.
