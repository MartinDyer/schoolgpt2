# 🚀 SchoolGPT Deployment Guide

**Complete step-by-step instructions to deploy SchoolGPT for your school**

---

## 📋 Prerequisites

### What You Need
- ✅ **Azure Subscription** - Admin access to your school's Azure account  
- ✅ **GitHub Account** - Ability to fork repositories and manage secrets
- ✅ **Basic Information**:
  - Azure Subscription ID
  - Azure Tenant ID  
  - School IT admin email address
  - Your Azure AD Object ID

### Getting Your Azure Information

```bash
# 1. Login to Azure
az login

# 2. Get your subscription ID and tenant ID
az account show --query '{subscriptionId:id, tenantId:tenantId}' -o table

# 3. Get your Object ID
az ad signed-in-user show --query 'id' -o tsv
```

---

## 🔧 Step 1: Repository Setup

### Option A: Fork Repository (Recommended)
1. Go to the SchoolGPT repository on GitHub
2. Click **"Fork"** button
3. Choose your organization/account
4. ✅ You now have your own copy

### Option B: Clone Repository  
```bash
git clone https://github.com/your-org/schoolgpt.git
cd schoolgpt
```

---

## 🔑 Step 2: Azure Credentials Setup

### Create Azure Service Principal
```bash
# Create service principal with contributor role
az ad sp create-for-rbac \
  --name "SchoolGPT-GitHub-Actions" \
  --role contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --sdk-auth
```

### Add GitHub Secret
1. In your GitHub repository, go to **Settings** → **Secrets and variables** → **Actions**
2. Click **"New repository secret"**
3. Name: `AZURE_CREDENTIALS`
4. Value: **Paste the entire JSON output** from the command above
5. Click **"Add secret"**

**Example JSON format:**
```json
{
  "clientId": "12345678-1234-1234-1234-123456789012",
  "clientSecret": "your-client-secret",
  "subscriptionId": "87654321-4321-4321-4321-210987654321", 
  "tenantId": "11111111-2222-3333-4444-555555555555"
}
```

---

## ⚙️ Step 3: Configure terraform.tfvars

**This is the most important step!** You must configure `infra/terraform.tfvars` with your school's information.

### Open the File
```bash
cd schoolgpt/infra
nano terraform.tfvars  # or use any text editor
```

### Required Configuration

**Replace ALL placeholder values with your actual information:**

```hcl
#################################################################
# School Safe AI App using Azure AI Foundry - Configuration
#################################################################

# Basic Infrastructure
resource_group_name   = "yourschool-production-rg"    # CHANGE THIS
location              = "uksouth"                     # Choose your region
azure_subscription_id = "YOUR_SUBSCRIPTION_ID"        # REQUIRED
azure_tenant_id       = "YOUR_TENANT_ID"             # REQUIRED

# School Configuration  
school_name = "Your School Name"                      # CHANGE THIS
alert_email = "admin@yourschool.edu"                  # CHANGE THIS

# Azure AI Foundry Configuration (Auto-generated unique names)
ai_foundry_name      = "yourschoolaifoundry2024"      # CHANGE THIS (make unique)
ai_foundry_subdomain = "yourschoolai2024"             # CHANGE THIS (make unique)
azure_openai_model   = "gpt-35-turbo"                # gpt-35-turbo or gpt-4
azure_openai_model_version = "1106"
azure_openai_model_deployment_name = "school-safe-chat"
model_sku_name       = "Standard"
model_capacity       = 80                            # Adjust based on quota

# Container Registry and App Service (Auto-generated unique names)
acr_name              = "yourschoolacr2024"           # CHANGE THIS (make unique)
app_service_plan_name = "schoolgpt-asp"
app_service_sku       = "B2"                         # B1/B2/B3 for different sizes
web_app_name          = "yourschoolwebapp2024"       # CHANGE THIS (make unique)
acr_login_server      = "yourschoolacr2024.azurecr.io"  # Match ACR name

# Docker Configuration
docker_image = "schoolgpt-app"
docker_tag   = "latest"

# SQL Database Configuration (Auto-generated unique names)
sql_server_name       = "yourschoolsql2024"          # CHANGE THIS (make unique)
sql_admin             = "sqladminuser"
sql_password          = "MyStrongP@ssw0rd123!"       # CHANGE THIS (secure password)
sql_db_name           = "schoolgptdb"
sql_sku_name          = "S1"                         # S0/S1/S2 for different performance
sql_azuread_admin_login = "admin@yourschool.edu"     # CHANGE THIS
sql_azuread_admin_object_id = "YOUR_OBJECT_ID"       # CHANGE THIS

# Application Insights
app_insights_name = "schoolgpt-ai"

# Azure Key Vault (Auto-generated unique names)  
key_vault_name            = "yourschoolkv2024"       # CHANGE THIS (make unique)
key_vault_admin_object_id = "YOUR_OBJECT_ID"         # CHANGE THIS
```

### Important Notes
- **Resource names must be globally unique** - Add your school name/year
- **Use only lowercase letters and numbers** for Azure resource names
- **No spaces or special characters** except hyphens in some cases
- **Object ID** - Use the ID you got from `az ad signed-in-user show`

### Example for "Lincoln Elementary School"
```hcl
resource_group_name   = "lincolnelementary-production-rg"
school_name = "Lincoln Elementary School"  
alert_email = "it@lincolnelementary.edu"
ai_foundry_name      = "lincolnelementaryai2024"
acr_name              = "lincolnelementaryacr2024"
web_app_name          = "lincolnelementaryapp2024"
sql_server_name       = "lincolnelementarysql2024"
key_vault_name        = "lincolnelementarykv2024"
```

---

## 🚀 Step 4: Deploy Using CI/CD Workflows

### 4.1 Setup Backend Storage
1. Go to **Actions** tab in your GitHub repository
2. Select **"🔧 Setup SchoolGPT Backend Storage"** workflow
3. Click **"Run workflow"**
4. Fill in:
   - **School Name**: `Lincoln Elementary School`
   - **Environment**: `production`
5. Click **"Run workflow"**
6. ✅ Wait for completion (~3 minutes)

**This creates:**
- Terraform remote state storage
- Updates backend configuration automatically

### 4.2 Deploy Infrastructure  
1. Select **"🚀 Deploy SchoolGPT Infrastructure"** workflow
2. Click **"Run workflow"**
3. Fill in:
   - **School Name**: `Lincoln Elementary School`
   - **Environment**: `production` 
   - **Action**: `plan` (first time)
   - **Auto Approve**: `false`
4. Click **"Run workflow"**
5. ✅ Review the plan output
6. **Run again** with **Action**: `apply` and **Auto Approve**: `true`
7. ✅ Wait for completion (~10 minutes)

**This creates:**
- Resource Group
- Azure AI Foundry
- Container Registry  
- App Service Plan & Web App
- SQL Server & Database
- Key Vault
- Application Insights
- Storage Accounts

### 4.3 Deploy Application
1. Select **"📱 Deploy SchoolGPT Application"** workflow
2. Click **"Run workflow"**
3. Fill in:
   - **Environment**: `production`
4. Click **"Run workflow"**
5. ✅ Wait for completion (~5 minutes)

**This:**
- Builds the React/Python application
- Creates Docker image
- Deploys to Azure App Service
- Configures all environment variables

---

## 🎯 Step 5: Access Your Application

### Get Your App URL
After successful deployment:

1. Go to **Azure Portal** → **Resource Groups** → **Your Resource Group**
2. Click on your **App Service** (e.g., `lincolnelementaryapp2024`)
3. Copy the **URL** (e.g., `https://lincolnelementaryapp2024.azurewebsites.net`)
4. 🎉 **Your SchoolGPT is live!**

### First-Time Setup
1. **Test the application** - Open the URL
2. **Configure Azure AD** (if using school authentication)
3. **Test AI responses** - Ensure content filtering works
4. **Share with teachers** - Provide the URL and access instructions

---

## 🔧 CI/CD Workflows Reference

### Available Workflows
1. **🔧 Setup Backend Storage** - One-time setup for Terraform state
2. **🚀 Deploy Infrastructure** - Creates/updates Azure resources
3. **📱 Deploy Application** - Builds and deploys the web app
4. **🔄 Import Existing Resources** - Import existing Azure resources 
5. **🗑️ Destroy Infrastructure** - Safely removes all resources

### Workflow Inputs
Most workflows accept these inputs:
- **School Name** - Your school's display name
- **Environment** - Usually `production`
- **Auto Approve** - For automatic deployments

### Running Workflows
1. Go to **Actions** tab
2. Select the workflow you want
3. Click **"Run workflow"**  
4. Fill in the required inputs
5. Click **"Run workflow"**

---

## 🛠️ Troubleshooting

### Common Issues

#### 1. Terraform Validation Errors
```
Error: Invalid value for variable "acr_name"
ACR name must be 5-50 characters, lowercase letters and numbers only.
```
**Solution:** Check `terraform.tfvars` - ensure all names follow Azure naming requirements

#### 2. Azure Quota Exceeded
```
Error: InsufficientQuota: This operation require 120 new capacity in quota 
Tokens Per Minute (thousands) - GPT-35-Turbo
```
**Solution:** Reduce `model_capacity` in `terraform.tfvars` or delete unused AI services

#### 3. Resource Already Exists
```
Error: A resource with the ID "/subscriptions/.../resourceGroups/..." already exists
```
**Solution:** Run the **"🔄 Import Existing Resources"** workflow first

#### 4. Authentication Failed
```
Error: AADSTS70011: The provided value for the input parameter 'scope' is not valid
```
**Solution:** Check `AZURE_CREDENTIALS` secret - ensure JSON is valid and complete

### Getting Help

#### Check Workflow Logs
1. Go to **Actions** tab
2. Click on the failed workflow run
3. Click on the failed step  
4. Read the error message and logs

#### Common Solutions
- **Resource naming conflicts** → Make names more unique
- **Quota issues** → Reduce resource sizes or delete unused resources
- **Permission errors** → Check Azure service principal permissions
- **Configuration errors** → Verify `terraform.tfvars` values

---

## 🔄 Updating Your Deployment

### Update Application Code
1. Make changes to code in `sample-app-aoai-chatGPT/`
2. Commit and push to your repository
3. Run **"📱 Deploy Application"** workflow
4. ✅ Application updates automatically

### Update Infrastructure  
1. Modify `infra/terraform.tfvars` or `infra/main.tf`
2. Commit and push changes
3. Run **"🚀 Deploy Infrastructure"** workflow with **Action**: `plan`
4. Review changes
5. Run again with **Action**: `apply`
6. ✅ Infrastructure updates safely

### Add New Schools
1. **Option A**: Copy repository and change `terraform.tfvars`
2. **Option B**: Use different environments (`staging`, `development`) 
3. Run setup workflows for each school
4. Each gets completely isolated resources

---

## 💰 Cost Management

### Monitor Costs
- **Azure Portal** → **Cost Management** → **Cost Analysis**
- Filter by **Resource Group** to see school-specific costs
- Set up **Budget Alerts** for cost control

### Optimize Costs
- **App Service**: Start with B1, upgrade to B2/S1 if needed
- **SQL Database**: Use S0 for testing, S1+ for production
- **AI Foundry**: Monitor usage, adjust `model_capacity` as needed

### Typical Monthly Costs
- **Small School**: $135-185/month
- **Medium School**: $320-470/month
- **Large School**: $500-800/month

---

## 🔒 Security & Compliance

### Data Protection
- ✅ All data encrypted at rest and in transit
- ✅ Regular automated backups
- ✅ Compliance with GDPR, COPPA, and FERPA
- ✅ Audit logs for all interactions

### Access Control
- ✅ Azure AD integration
- ✅ School domain restrictions  
- ✅ Role-based permissions
- ✅ Session management

### Content Safety
- ✅ HIGH-level content filtering
- ✅ Age-appropriate response tuning
- ✅ Real-time conversation monitoring
- ✅ Automated policy enforcement

---

## 🎓 Next Steps

### For School Administrators
1. **Train Teachers** - Show them how to use the AI assistant
2. **Set Guidelines** - Create usage policies for students
3. **Monitor Usage** - Review analytics and content filters
4. **Gather Feedback** - Continuously improve based on usage

### For Developers
1. **Customize UI** - Brand with school colors and logo
2. **Add Features** - Integrate with school systems
3. **Monitor Performance** - Set up additional alerts
4. **Scale Up** - Add more schools or advanced features

---

## 📞 Support & Resources

### Documentation
- **Azure AI Foundry**: [Official Documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/)
- **Terraform**: [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- **GitHub Actions**: [Workflow Documentation](https://docs.github.com/en/actions)

### Community
- **GitHub Issues**: Report bugs and request features
- **GitHub Discussions**: Ask questions and share experiences

---

## ✅ Deployment Checklist

### Pre-Deployment  
- [ ] Azure subscription ready with admin access
- [ ] GitHub repository forked/cloned
- [ ] `AZURE_CREDENTIALS` secret added to GitHub
- [ ] `terraform.tfvars` configured with school information
- [ ] All resource names are unique and valid

### Deployment
- [ ] "🔧 Setup Backend Storage" workflow completed successfully
- [ ] "🚀 Deploy Infrastructure" workflow completed successfully
- [ ] "📱 Deploy Application" workflow completed successfully
- [ ] Application URL accessible and working

### Post-Deployment
- [ ] Azure AD authentication configured (if using)
- [ ] Content filtering tested and working
- [ ] Teachers trained on usage
- [ ] Monitoring and alerts configured
- [ ] Usage guidelines established

---

**🎉 Congratulations! Your SchoolGPT is now live and ready for educational use!**

**Need help? Check the troubleshooting section above or create a GitHub issue.** 