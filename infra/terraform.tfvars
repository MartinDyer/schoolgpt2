# Example Terraform Variables for School Deployment
# Copy this file to `terraform.tfvars` and fill in your values

# ================== Basic Configuration ==================
school_name = "blundells-school"  # Your school name (lowercase, hyphens)
environment = "production"
location    = "uksouth"  # Azure region

# ================== Azure AD / Tenant ==================
azure_tenant_id = "927d1a3d-4615-4ae3-84c4-775d3e0f39b3"  # From Azure Portal → Azure AD → Overview

# ================== AI Foundry (Manual Deployment) ==================
# School deploys AI Foundry manually first using AI_FOUNDRY_DEPLOYMENT_GUIDE.md
# Then provides these values:

azure_openai_endpoint       = "https://blundells-ai-foundry.openai.azure.com/"
azure_openai_deployment     = "gpt-4o"
azure_openai_resource_name  = "Blundells-ai-foundry"
azure_openai_resource_group = "rg-Blundells-ai-foundry"

# Auto-grant AI access via Terraform (false = school grants manually in Portal)
auto_grant_ai_access = false

# ================== Database Configuration ==================
sql_admin   = "sqladminuser"
sql_db_name = "blundellsschooldb"
sql_sku_name = "S1"  # Basic, S0, S1, S2, S3

# SQL password is auto-generated and stored in Key Vault
# sql_password = "optional-custom-password"  # Uncomment to set custom password

# ================== App Service ==================
app_service_sku = "B1"  # B1 ($13/mo), B2 ($55/mo), S1 ($70/mo)

# ================== Optional: Custom Names ==================
# resource_group_name = "custom-rg-name"  # Auto-generated if not provided
# app_service_plan_name = "custom-asp-name"
# sql_server_name = "custom-sql-server"  # Must be globally unique
