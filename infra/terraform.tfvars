#################################################################
# School Safe AI App using Azure AI Foundry - Configuration
#################################################################

# Fill in your details below for one-click deployment

# Basic Infrastructure (Will be auto-generated for each school)
resource_group_name   = "schoolgpt-rg"
location              = "uksouth"
azure_subscription_id = "b314f8eb-7c3d-4ca4-87c9-5daa33527126"  # REPLACE_WITH_YOUR_SUBSCRIPTION_ID
azure_tenant_id       = "d51fcef1-e2eb-407e-8d79-3cefaf2255ea"  # REPLACE_WITH_YOUR_TENANT_ID

# School Configuration (Auto-filled by setup workflow)
school_name = "Test-School"
alert_email = "admin@myschool.edu"                        # REPLACE: Your school IT admin email

# Azure AI Foundry Configuration (Auto-generated unique names)
ai_foundry_name      = "testschoolaifoundry2024"
ai_foundry_subdomain = "testschoolai2024"
azure_openai_model   = "gpt-35-turbo"            # Options: gpt-35-turbo, gpt-4, gpt-4o
azure_openai_model_version = "1106"
azure_openai_model_deployment_name = "school-safe-chat"
model_sku_name       = "Standard"
model_capacity       = 120  # Tokens per minute

# Container Registry and App Service (Auto-generated unique names)
acr_name              = "testschoolacr2024"
app_service_plan_name = "schoolgpt-asp"
app_service_sku       = "B2"                     # B1/B2/B3 for basic, S1/S2/S3 for standard
web_app_name          = "testschoolwebapp2024"
acr_login_server      = "testschoolacr2024.azurecr.io"

# Docker Configuration
docker_image = "schoolgpt-app"
docker_tag   = "latest"

# SQL Database Configuration (Auto-generated unique names)
sql_server_name       = "testschoolsql2024"
sql_admin             = "sqladminuser"
sql_password          = "MyStrongP@ssw0rd123!"   # REPLACE: Use a secure password
sql_db_name           = "schoolgptdb"
sql_sku_name          = "S1"                     # Basic, S0, S1, S2, S3 for different performance tiers
sql_azuread_admin_login = "admin@myschool.edu"   # REPLACE: Your Azure AD admin email
sql_azuread_admin_object_id = "f3885dda-10a2-41bc-bffa-3e657748ecfb"  # REPLACE_WITH_YOUR_OBJECT_ID

# Application Insights
app_insights_name = "schoolgpt-ai"

# Azure Key Vault (Auto-generated unique names)
key_vault_name            = "testschoolkv2024"
key_vault_admin_object_id = "f3885dda-10a2-41bc-bffa-3e657748ecfb"  # REPLACE_WITH_YOUR_OBJECT_ID

# Terraform Backend Storage
# backend_storage_account_name = "schoolgptstg"
# backend_container_name       = "tfstate"

#################################################################
# School-Safe AI Configuration Notes:
#################################################################
#
# 1. Content Filtering: Set to HIGH level for all categories
# 2. Target Audience: Students under 16 years old
# 3. Authentication: Entra ID required for access
# 4. Monitoring: Application Insights with content filter alerts
# 5. Audit Logging: All interactions logged to SQL database
# 6. Model Choice: 
#    - gpt-35-turbo: Cost-effective, fast, great for most school use
#    - gpt-4: More advanced reasoning, higher cost
#    - gpt-4o: Latest model with vision capabilities
#
# IMPORTANT: Replace the following with YOUR values:
# - alert_email: Your school IT admin email
# - sql_azuread_admin_login: Your Azure AD admin email  
# - sql_azuread_admin_object_id: Your Azure AD object ID
# - key_vault_admin_object_id: Your Azure AD object ID
# - All resource names must be globally unique
#################################################################