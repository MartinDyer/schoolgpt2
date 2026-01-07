# GitHub Actions Deployment Workflow

Complete guide for deploying SchoolGPT using GitHub Actions automation.

## Architecture Overview

SchoolGPT uses **separate Terraform modules** for different layers:

```
infra/
├── AI-Foundry/          # Separate TF module for AI Foundry (protected)
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
└── main.tf              # Main infrastructure (Web App, SQL, etc.)
```

**Why Separate?**
- AI Foundry can be deployed once and **reused** across schools
- Protected with `prevent_destroy` to avoid accidental deletion
- Different lifecycle - AI stays, schools come/go

---

## Deployment Workflows

### 1️⃣ **Setup Backend** (One-time)
**Workflow**: `01-setup-backend.yml`

Creates Azure Storage for Terraform state management.

**Run Once**: Before any deployments

```bash
gh workflow run "01-setup-backend.yml"
```

---

### 2️⃣ **Deploy AI Foundry** (Per School or Shared)
**Workflow**: `02-deploy-aifoundry.yml`

Deploys Azure OpenAI resource with GPT model.

**Options**:
- **Option A**: One AI Foundry shared across all schools (cost-effective)
- **Option B**: Separate AI Foundry per school (better isolation)

**For Option A** (Shared AI - Run Once):
```bash
gh workflow run "02-deploy-aifoundry.yml" \
  --field environment=production \
  --field school_name="Shared-AI-Resource" \
  --field action=apply \
  --field auto_approve=true
```

**For Option B** (Per School):
```bash
gh workflow run "02-deploy-aifoundry.yml" \
  --field environment=production \
  --field school_name="Lincoln-High-School" \
  --field action=apply \
  --field auto_approve=true
```

**What Gets Deployed**:
- Azure OpenAI (AI Foundry) resource
- GPT-4o model deployment
- Capacity: Configurable (default: 1, recommend: 100+)

**Outputs**:
- AI Foundry endpoint
- Resource ID
- Deployment name

---

### 3️⃣ **Deploy School Infrastructure** (Per School)
**Workflow**: `04-deploy-infrastructure.yml` or `06-deploy-full-app.yml`

Deploys school-specific resources.

**For Lincoln High School**:
```bash
gh workflow run "06-deploy-full-app.yml" \
  --field school_name="Lincoln High School"
```

or manually:

```bash
gh workflow run "04-deploy-infrastructure.yml" \
  --field environment=production \
  --field school_name="Lincoln-High-School" \
  --field action=apply \
  --field auto_approve=true
```

**What Gets Deployed**:
- Web App (Frontend + Backend)
- SQL Server + Database
- Key Vault
- Application Insights
- Log Analytics
- **References** existing AI Foundry

**Requires**:
Before running, update `infra/terraform.tfvars` with AI Foundry details:

```hcl
# AI Foundry Configuration
azure_openai_endpoint = "https://[ai-foundry-name].openai.azure.com/"
azure_openai_deployment = "gpt-4o"
azure_openai_resource_group = "rg-aifoundry-xxxxx"
azure_openai_resource_name = "School-Safe-GPT-AIF-xxxxx"
```

---

### 4️⃣ **Grant AI Access** (Per School)
**Manual Step** (Azure Portal) or via CLI:

**Option A - Azure Portal**:
1. Go to AI Foundry resource
2. Access control (IAM) → Add role assignment
3. Role: **Cognitive Services OpenAI User**
4. Assign to: `[school-name]-app` (Web App's Managed Identity)

**Option B - Azure CLI**:
```bash
# Get Web App's Principal ID (from Terraform output or Portal)
WEB_APP_ID=$(az webapp identity show \
  --name lincoln-high-school-app \
  --resource-group lincoln-high-school-production-main \
  --query principalId -o tsv)

# Grant access to AI Foundry
az role assignment create \
  --assignee $WEB_APP_ID \
  --role "Cognitive Services OpenAI User" \
  --scope "/subscriptions/[sub-id]/resourceGroups/[ai-rg]/providers/Microsoft.CognitiveServices/accounts/[ai-name]"
```

⏱️ Wait 1-2 min for permission to propagate

---

## Complete End-to-End Test

### Scenario: Deploy Lincoln High School

#### Step 1: Setup (One-time if not done)

```bash
# 1. Setup Terraform backend
gh workflow run "01-setup-backend.yml"

# 2. Deploy shared AI Foundry (or skip if using per-school AI)
gh workflow run "02-deploy-aifoundry.yml" \
  --field environment=production \
  --field school_name="Shared-AI" \
  --field action=apply \
  --field auto_approve=true
```

Wait ~5-10 minutes for AI Foundry deployment.

#### Step 2: Configure School Deployment

Update `infra/terraform.tfvars`:

```hcl
school_name = "lincoln-high-school"
environment = "production"

# From AI Foundry deployment outputs:
azure_openai_endpoint = "https://school-safe-gpt-aif-xxxxx.openai.azure.com/"
azure_openai_deployment = "gpt-4o"
azure_openai_resource_group = "rg-aifoundry-xxxxx"
azure_openai_resource_name = "School-Safe-GPT-AIF-xxxxx"

azure_tenant_id = "your-tenant-id"
```

Commit and push:
```bash
git add infra/terraform.tfvars
git commit -m "config: lincoln high school deployment"
git push
```

#### Step 3: Deploy School Infrastructure

```bash
gh workflow run "06-deploy-full-app.yml"
```

Wait ~10 minutes.

#### Step 4: Grant AI Access

```bash
# Get web app principal ID from workflow output
# Then grant permission (see step 4 above)
```

#### Step 5: Test

```bash
# Health check
curl https://lincoln-high-school-app.azurewebsites.net/health

# AI Chat test
curl -X POST https://lincoln-high-school-app.azurewebsites.net/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"What is 2+2?","userId":"test","sessionId":"test"}'

# Expected: {"ok":true,"reply":"2 plus 2 equals 4..."}
```

---

##Destroy Workflow

### Destroy School (Keep AI Foundry)

**Workflow**: `x01-destroy-infrastructure.yml`

```bash
gh workflow run "x01-destroy-infrastructure.yml"
```

**What Happens**:
- ❌ Destroys: Web App, SQL, Key Vault, Application Insights
- ✅ Keeps: AI Foundry (protected by `prevent_destroy`)
- **Status**: Workflow will show "FAILED" - **THIS IS EXPECTED!**

The failure is because Terraform can't destroy the protected AI Foundry, which is exactly what you want.

### Destroy Everything (Including AI)

```bash
# 1. Destroy main infrastructure
gh workflow run "x01-destroy-infrastructure" 

# 2. Manually destroy AI Foundry via Portal or:
cd infra/AI-Foundry
# Remove lifecycle.prevent_destroy from main.tf
terraform destroy -var-file=terraform.tfvars
```

---

## Multi-School Deployment Strategy

### Option A: Shared AI Foundry (Recommended)

**Setup**:
1. Deploy AI Foundry once (workflow 02)
2. Deploy School1 infrastructure (workflow 06)
3. Deploy School2 infrastructure (workflow 06) - same AI Foundry
4. Deploy School3 infrastructure (workflow 06) - same AI Foundry

**Cost**: ~$70/month per school + shared AI costs

**Pros**:
- Cost-effective
- Centralized AI management
- Easy quota увеличения

**Cons**:
- Shared token quota (100k tokens split among schools)
- One school's heavy usage affects others

### Option B: Per-School AI Foundry

**Setup**:
1. Deploy AI Foundry for School1 (workflow 02)
2. Deploy School1 infrastructure (workflow 06)
3. Deploy AI Foundry for School2 (workflow 02)
4. Deploy School2 infrastructure (workflow 06)

**Cost**: ~$120-220/month per school

**Pros**:
- Dedicated 100k tokens per school
- Complete isolation
- Clear cost attribution

**Cons**:
- Higher cost
- More resources to manage

---

## Workflow Cheat Sheet

| Task | Workflow | Frequency |
|------|----------|-----------|
| Setup Backend | `01-setup-backend.yml` | Once |
| Deploy AI Foundry | `02-deploy-aifoundry.yml` | Once or Per School |
| Deploy School App | `06-deploy-full-app.yml` | Per School |
| Destroy School | `x01-destroy-infrastructure.yml` | As needed |

---

## Current Status

**Your Current Deployment**:
- AI Foundry: `ChatGPT-Safe` (manually deployed, 100k tokens)
- School1: Deployed and working
- Architecture: Shared AI model (Option A)

**To Test With New School**:
1. Update `infra/terraform.tfvars` with new school name
2. Run `gh workflow run "06-deploy-full-app.yml"`
3. Grant AI access via Portal
4. Test!

---

## Troubleshooting

### Destroy Fails with "prevent_destroy"
**Expected**: AI Foundry is protected - this is normal!

**Solution**: Ignore the error - everything except AI Foundry was destroyed successfully.

### AI Chat Returns "I couldn't answer that"
**Cause**: Web App doesn't have AI Foundry permission

**Fix**: Grant "Cognitive Services OpenAI User" role (Step 4)

### Terraform State Locked
**Cause**: Previous workflow still running or crashed

**Fix**:
```bash
# In Azure Portal → Storage Account → Containers → tfstate
# Delete the .terraform.tfstate.lock.info file
```

---

## Next Steps

1. ✅ Understand the workflow structure
2. ✅ Choose multi-school strategy (shared vs per-school AI)
3. ✅ Test end-to-end deployment for  a new school
4. ✅ Document any issues encountered
5. ✅ Create runbook for future deployments

**You now have a fully automated GitHub Actions-based deployment system!** 🚀
