# End-to-End Deployment Test Guide

Complete walkthrough for deploying SchoolGPT for a new school from scratch.

## Scenario: Lincoln High School Deployment

**Goal**: Deploy a complete working SchoolGPT instance for "Lincoln High School"

**Timeline**: ~30 minutes total

---

## Phase 1: School Deploys AI Foundry (15 min)

**Who**: Lincoln High School IT team  
**Guide**: [AI_FOUNDRY_DEPLOYMENT_GUIDE.md](./AI_FOUNDRY_DEPLOYMENT_GUIDE.md)

### Steps:

1. **Create AI Foundry Resource**
   - Name: `lincoln-high-ai-foundry`
   - Resource Group: `rg-lincoln-high-ai-foundry`
   - Region: UK South
   - Model: gpt-4o-mini (cost-effective)

2. **Deploy Model**
   - Deployment name: `gpt-4o-mini`
   - Capacity: 100K tokens

3. **Collect Configuration**
   ```bash
   AZURE_OPENAI_ENDPOINT="https://lincoln-high-ai-foundry.openai.azure.com/"
   AZURE_OPENAI_DEPLOYMENT="gpt-4o-mini"
   AI_FOUNDRY_RESOURCE_GROUP="rg-lincoln-high-ai-foundry"
   AI_FOUNDRY_RESOURCE_NAME="lincoln-high-ai-foundry"
   ```

4. **Send to Development Team** ✉️

---

## Phase 2: Update Configuration (5 min)

**Who**: Development team (you!)

### Step 1: Update Terraform Variables

Edit `infra/terraform.tfvars`:

```hcl
# School Information
school_name = "lincoln-high-school"
environment = "production"

# AI Foundry (created by school)
azure_openai_endpoint = "https://lincoln-high-ai-foundry.openai.azure.com/"
azure_openai_deployment = "gpt-4o-mini"
azure_openai_resource_group = "rg-lincoln-high-ai-foundry"
azure_openai_resource_name = "lincoln-high-ai-foundry"

# Azure AD (provided by school)
azure_tenant_id = "school-azure-tenant-id"

# Database
sql_admin = "sqladminuser"
sql_db_name = "lincolnhighdb"
```

### Step 2: Commit Changes

```bash
git add infra/terraform.tfvars
git commit -m "config: lincoln high school deployment"
git push
```

---

## Phase 3: Deploy Infrastructure (10 min)

**Who**: Development team (automated via GitHub Actions)

### Option A: Via GitHub Actions (Recommended)

1. Go to GitHub repository
2. Click "Actions" tab
3. Select "06- Deploy Full App" workflow
4. Click "Run workflow"
5. Wait ~10 minutes

### Option B: Manual Terraform

```bash
cd infra

# Initialize
terraform init

# Plan
terraform plan -var-file=terraform.tfvars

# Deploy
terraform apply -var-file=terraform.tfvars -auto-approve
```

**Outputs to Save**:
```bash
web_app_name = "lincoln-high-school-app"
web_app_url = "https://lincoln-high-school-app.azurewebsites.net"
web_app_principal_id = "12345678-1234-1234-1234-123456789abc"
```

---

## Phase 4: Grant AI Access (2 min)

**Who**: Lincoln High School IT team

### Steps:

1. **Azure Portal** → AI Foundry resource (`lincoln-high-ai-foundry`)
2. **Access control (IAM)** → Add role assignment
3. **Role**: Cognitive Services OpenAI User
4. **Assign to**: Managed Identity
5. **Select**: `lincoln-high-school-app`
6. **Review + assign**

⏱️ Wait 1-2 minutes for permission to propagate

---

## Phase 5: Configure Microsoft Login (5 min)

**Who**: Lincoln High School IT team

### Steps:

1. **Azure Portal** → Azure Active Directory → App Registrations
2. **New registration**:
   - Name: `Lincoln-High-SchoolGPT`
   - Supported account types: Single tenant
   - Redirect URI: `https://lincoln-high-school-app.azurewebsites.net`
3. **Save** → Copy `Application (client) ID`
4. **Authentication** → Add platform → Single-page application
   - Redirect URI: `https://lincoln-high-school-app.azurewebsites.net`
5. **Implicit grant**: Enable ID tokens
6. **Save**

### Update App Configuration:

```bash
az webapp config appsettings set \
  --name lincoln-high-school-app \
  --resource-group lincoln-high-school-production-main \
  --settings AZURE_CLIENT_ID="app-registration-client-id"
```

---

## Phase 6: Testing & Verification

### Test 1: Health Check

```bash
curl https://lincoln-high-school-app.azurewebsites.net/health
# Expected: {"status":"ok"}
```

### Test 2: AI Chat

```bash
curl -X POST https://lincoln-high-school-app.azurewebsites.net/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"What is 2 plus 2?","userId":"test","sessionId":"test"}'
  
# Expected: {"ok":true,"reply":"2 plus 2 equals 4..."}
```

### Test 3: Microsoft Login

1. Open: `https://lincoln-high-school-app.azurewebsites.net`
2. Click "Sign in with Microsoft"
3. Login with school account
4. Should redirect back successfully

### Test 4: Chat History Persistence

1. Login with Microsoft account
2. Send several messages
3. Refresh page
4. Chat history should still be there ✅

---

## Complete Success Checklist

- [ ] AI Foundry deployed by school
- [ ] Configuration provided to dev team
- [ ] Infrastructure deployed via GitHub Actions
- [ ] Web app is accessible
- [ ] Health endpoint returns 200 OK
- [ ] Managed Identity granted AI access
- [ ] AI chat returns actual responses (not errors)
- [ ] Microsoft login works
- [ ] Chat history persists in database
- [ ] Students can use the chatbot

---

## Expected Costs (Lincoln High School)

| Resource | Monthly Cost |
|----------|--------------|
| Web App (B2) | $55 |
| SQL Database (S1) | $15 |
| AI Foundry (gpt-4o-mini) | $10-30 |
| Key Vault | $0.03 |
| **Total** | **$80-100/month** |

---

## Troubleshooting

### Issue: "I couldn't answer that" error

**Cause**: Managed Identity doesn't have permission

**Fix**:
```bash
# Verify permission exists
az role assignment list --assignee <web-app-principal-id>

# If missing, grant in Azure Portal (Phase 4)
```

### Issue: Login redirects to localhost

**Cause**: Azure AD redirect URI not configured

**Fix**: Add production URL to App Registration (Phase 5)

### Issue: Chat history not saving

**Cause**: SQL firewall blocking connection

**Fix**:
```bash
# Add firewall rule for Azure Services
az sql server firewall-rule create \
  --server lincoln-high-sqlserver \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

---

## Next Steps After Successful Test

1. ✅ Document actual timeline and any issues
2. ✅ Create deployment template for next schools
3. ✅ Setup monitoring and alerts
4. ✅ Train school staff on basic usage
5. ✅ Prepare invoice/billing report

---

## Clean Up Test Deployment

If you want to remove Lincoln High test deployment:

```bash
# Run destroy workflow (keeps AI Foundry)
gh workflow run "Destroy Infrastructure"

# Or manual
cd infra
terraform destroy -var-file=terraform.tfvars
```

**Note**: School can keep their AI Foundry for future use!

---

## Summary

**Total Time**: ~30 minutes
**School Effort**: ~20 minutes (AI deployment + permissions)
**Dev Effort**: ~10 minutes (configuration + deployment)

**Result**: Fully functional AI chatbot for the school! 🎉
