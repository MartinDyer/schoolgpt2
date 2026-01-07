# Destroy School Infrastructure (Keep Shared AI)

This guide explains how to destroy a school's infrastructure while preserving the shared `ChatGPT-Safe` AI Foundry resource.

## Why Keep the AI Foundry?

The `ChatGPT-Safe` resource has **100k token capacity** and can be shared across multiple school deployments. Keeping it saves:
- Money (no need to create new AI resources)
- Time (no need to reconfigure and request quota increases)
- Quota (100k tokens is valuable and hard to get)

## Protected Resource

**Resource**: `ChatGPT-Safe`  
**Type**: Azure OpenAI (AI Foundry)  
**Location**: AI-Foundry resource group  
**Capacity**: 100 tokens  
**Protection**: `prevent_destroy = true`

---

## How to Destroy a School Deployment

### Option 1: Via GitHub Actions (Recommended)

The destroy workflow will **automatically skip** the AI Foundry resource due to `prevent_destroy`. It will destroy everything else:

```bash
# Just run the workflow - it will fail gracefully, destroying everything except AI Foundry
gh workflow run "Destroy Infrastructure" --ref main
```

**Expected behavior**: Workflow will destroy all school resources but fail at the end with "Instance cannot be destroyed" for the AI Foundry. This is **NORMAL and SAFE**.

### Option 2: Manual Terraform Destroy

Destroy everything except the AI Foundry and its resource group:

```bash
cd infra

# Destroy school-specific resources only
terraform destroy \
  -var-file=terraform.tfvars \
  -var="environment=production" \
  -var="school_name=School1" \
  -target=azurerm_linux_web_app.frontend \
  -target=azurerm_mssql_database.main \
  -target=azurerm_mssql_server.main \
  -target=azurerm_key_vault.main \
  -target=azurerm_service_plan.main \
  -target=azurerm_application_insights.main \
  -target=azurerm_log_analytics_workspace.main \
  -target=azurerm_resource_group.main
```

This preserves:
- ✅ `ChatGPT-Safe` AI Foundry
- ✅ `rg-aifoundry-73744` resource group
- ✅ `gpt-4.1-mini` deployment

---

## Deploying a New School

### Step 1: Update Configuration

When deploying for a new school, just update the environment variables to point to the existing AI Foundry:

```bash
# In your GitHub Actions workflow or Terraform
AZURE_OPENAI_ENDPOINT="https://chatgpt-safe.cognitiveservices.azure.com/"
AZURE_OPENAI_DEPLOYMENT="Test-gpt-4.1-mini"
```

### Step 2: Grant Permissions

The new school's Web App will need access to the AI Foundry:

```bash
# Get the new web app's Managed Identity principal ID
NEW_APP_PRINCIPAL_ID=$(az webapp identity show \
  --name <new-school-app-name> \
  --resource-group <new-school-rg> \
  --query principalId -o tsv)

# Grant access to ChatGPT-Safe
az role assignment create \
  --assignee $NEW_APP_PRINCIPAL_ID \
  --role "Cognitive Services OpenAI User" \
  --scope "/subscriptions/b314f8eb-7c3d-4ca4-87c9-5daa33527126/resourceGroups/AI-Foundry/providers/Microsoft.CognitiveServices/accounts/ChatGPT-Safe"
```

Or via Azure Portal:
1. Go to `ChatGPT-Safe` resource
2. Access control (IAM) → Add role assignment
3. Role: **Cognitive Services OpenAI User**
4. Select: New school's web app

### Step 3: Deploy

Run your deployment workflow - it will use the shared AI resource automatically!

---

## Resource Sharing Architecture

```
┌─────────────────────────────────────────┐
│   Shared AI Foundry (ChatGPT-Safe)      │
│   - 100 token capacity                  │
│   - Reusable across all schools         │
└────────────┬────────────────────────────┘
             │
      ┌──────┴──────┬──────────────┬────────────
      │             │              │
┌─────▼─────┐ ┌─────▼─────┐ ┌─────▼─────┐
│  School1  │ │  School2  │ │  School3  │
│  Web App  │ │  Web App  │ │  Web App  │
│  SQL DB   │ │  SQL DB   │ │  SQL DB   │
└───────────┘ └───────────┘ └───────────┘
```

**Benefits:**
- One AI resource for all schools (cost-effective)
- Shared 100k token quota pool
- Easy to add new schools (just grant permission)
- Each school has its own database (data isolation)

---

## Cost Optimization

**Shared across schools:**
- AI Foundry: ~$0.03/1K tokens (shared pool)

**Per school:**
- Web App: ~$55/month (B2 plan)
- SQL Database: ~$15/month (S1)
- Key Vault: ~$0.03/month
- **Total per school: ~$70/month**

**Savings**: By sharing the AI resource, you avoid paying multiple AI resource fees!

---

## Important Notes

⚠️ **Token Quota Sharing**: All schools share the 100k token pool. Monitor usage to ensure fair distribution.

⚠️ **Rate Limits**: The capacity 100 is shared. If one school has high traffic, it may affect others.

✅ **Data Isolation**: Each school has its own SQL database - no data sharing or privacy concerns.

✅ **Security**: Managed Identity ensures each school can only use the AI, not access other schools' data.

---

## Monitoring Shared Usage

```bash
# Check which schools have access
az role assignment list \
  --scope "/subscriptions/b314f8eb-7c3d-4ca4-87c9-5daa33527126/resourceGroups/AI-Foundry/providers/Microsoft.CognitiveServices/accounts/ChatGPT-Safe" \
  --query "[].{App:principalId, Role:roleDefinitionName}" -o table
```

---

## Summary

✅ **Keep**: ChatGPT-Safe AI Foundry (protected)  
✅ **Reuse**: Same AI for all future schools  
✅ **Per School**: Deploy Web App + SQL Database  
✅ **Grant Access**: Add Managed Identity permission  
✅ **Save Money**: ~$50-100/month per additional school
