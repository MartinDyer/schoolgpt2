#################################################################
# School Safe GPT App using Azure AI Foundry - Configuration
#################################################################

# Fill in your details below for one-click deployment

# Basic Infrastructure (Will be auto-generated for each school)
resource_group_name   = ""
location              = "uksouth"
azure_tenant_id       = "d51fcef1-e2eb-407e-8d79-3cefaf2255ea" # REPLACE_WITH_YOUR_TENANT_ID

# SQL Database Configuration (Auto-generated unique names)
sql_server_name       = "luketestsqlsrv6f2f"
sql_admin                   = "sqladminuser"
sql_password                = "MyStrongP@ssw0rd123!" # REPLACE: Use a secure password
sql_db_name                 = "schoolgptdb"
sql_sku_name                = "S1"                                   # Basic, S0, S1, S2, S3 for different performance tiers
sql_azuread_admin_login     = "admin@myschool.edu"                   # REPLACE: Your Azure AD admin email
sql_azuread_admin_object_id = "f3885dda-10a2-41bc-bffa-3e657748ecfb" # REPLACE_WITH_YOUR_OBJECT_ID

# Application Insights
app_insights_name = "schoolgpt-ai"

# Azure Key Vault (Auto-generated unique names)
key_vault_name            = "luketestkv6f2f"
key_vault_admin_object_id = "f3885dda-10a2-41bc-bffa-3e657748ecfb" # REPLACE_WITH_YOUR_OBJECT_ID

# Content filtering is managed through Azure AI Foundry portal
# and configured via environment variables in the application

# Terraform Backend Storage
# backend_storage_account_name = "schoolgptstg"
# backend_container_name       = "tfstate"

#################################################################
# School-Safe GPT Configuration Notes:
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
# - sql_azuread_admin_login: Your Azure AD admin email  
# - sql_azuread_admin_object_id: Your Azure AD object ID
# - key_vault_admin_object_id: Your Azure AD object ID
# - All resource names must be globally unique
#################################################################