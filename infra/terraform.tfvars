# Fill in your details below for one-click deployment

resource_group_name   = "schoolgpt-rg"
location              = "uksouth"
acr_name              = "schoolgptacr123"
app_service_plan_name = "schoolgpt-asp"
web_app_name          = "schoolgpt-webapp123"
acr_login_server      = "schoolgptacr123.azurecr.io"
docker_image          = "schoolgpt-app"
docker_tag            = "latest"

# AI Foundry (Promptflow) Cognitive Services
promptflow_name      = "schoolgptpromptflow123"
promptflow_subdomain = "schoolgptpf123"

# (No need to provide endpoint or API key, Terraform will output them)

# SQL Database
sql_server_name       = "schoolgptsqlsrv123"
sql_admin             = "sqladminuser"
sql_password          = "12345" # Please fill in
sql_db_name           = "schoolgptdb"

# Application Insights
app_insights_name     = "schoolgpt-ai"

# Azure Key Vault
key_vault_name            = "schoolgptkv123"
azure_tenant_id           = "d51fcef1-e2eb-407e-8d79-3cefaf2255ea"
key_vault_admin_object_id = "12345678-90ab-cdef-1234-567890abcdef"
azure_subscription_id = "b314f8eb-7c3d-4ca4-87c9-5daa33527126"