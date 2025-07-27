# 🏫 SchoolGPT - Automated Setup for Any School

## What You Get
✅ **100% Automated Setup** - Just provide your school name and Azure details  
✅ **Unique Resource Names** - Every school gets their own automatically  
✅ **School-Safe AI** - Content filtering, monitoring, and audit logging  
✅ **No Technical Skills Required** - Everything done through GitHub Actions  

---

## Quick Setup for Schools (5 Minutes!)

### Step 1: Get Your Azure Information 📋
You'll need these 4 pieces of information from your school's Azure account:

1. **Azure Subscription ID** - Found in Azure Portal → Subscriptions
2. **Azure Tenant ID** - Found in Azure Portal → Azure Active Directory → Properties  
3. **Your Admin Email** - Your school IT admin email address
4. **Your Object ID** - Found in Azure Portal → Azure Active Directory → Users → (Your User) → Object ID

### Step 2: Set Up GitHub Secret 🔑
1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**  
3. Click **"New repository secret"**
4. Name: `AZURE_CREDENTIALS`
5. Value: Your Azure service principal JSON (ask your IT team)

### Step 3: Run the Setup Workflow 🚀
1. Go to **Actions** tab in GitHub
2. Find **"🔧 Setup SchoolGPT Backend Storage"** workflow
3. Click **"Run workflow"**
4. Fill in:
   - **School Name**: Your school name (e.g., "Lincoln Elementary")
   - **Environment**: `production`
5. Click **"Run workflow"** button

**That's it!** The system will automatically:
- Create unique Azure resources for your school
- Generate a custom configuration file
- Set up backend storage for state management

### Step 4: Deploy Your SchoolGPT 🎯
After setup completes:
1. Run **"🚀 Deploy SchoolGPT Infrastructure"** workflow
2. Wait for deployment to complete
3. Your school AI assistant is ready!

---

## What Gets Created Automatically

### 🏫 For "Lincoln Elementary School":
```
Resource Group: lincolnelementary-production-rg
AI Foundry: lincolnelementaryaifoundryabc123
Web App: lincolnelementarywebappabc123
Storage: lincolnelementarytfstatedef456
Container Registry: lincolnelementaryacrabc123
SQL Server: lincolnelementarysqlsrvabc123
Key Vault: lincolnelementarykvaabc123
```

### 🔒 **Security Features (Automatic)**:
- Content filtering set to HIGH level
- Target audience: Students under 16
- Authentication required (Azure AD)
- All conversations logged and monitored
- Secure secrets management

---

## For New Schools (Template Mode)

If you're selling this to another school:

### 1. They Fork/Copy This Repository
### 2. Update `infra/terraform.tfvars` with their details:
```terraform
# Replace these with school's actual values:
azure_subscription_id = "their-subscription-id"
azure_tenant_id = "their-tenant-id" 
alert_email = "admin@theirschool.edu"
sql_azuread_admin_login = "admin@theirschool.edu"
sql_azuread_admin_object_id = "their-object-id"
key_vault_admin_object_id = "their-object-id"
sql_password = "their-secure-password"
```

### 3. They Follow Steps 2-4 Above

**Everything else is generated automatically!** 🎉

---

## Cost Estimate 💰

**Monthly cost for small school (100-500 students):**
- Azure AI Foundry: ~$50-100/month
- App Service (B2): ~$55/month  
- SQL Database (S1): ~$20/month
- Storage & Other: ~$10/month
- **Total: ~$135-185/month**

**Scales automatically with usage!**

---

## Support 🆘

### Common Issues:
1. **"Resource already exists"** → Run the Import Resources workflow first
2. **"Access denied"** → Check your Azure credentials and permissions
3. **"Name not available"** → The system generates unique names automatically

### What Schools Love:
- ✅ Works out of the box
- ✅ Safe for students
- ✅ Transparent monitoring  
- ✅ No ongoing maintenance
- ✅ Scales with school size

---

## 🚀 Ready to Deploy!

**This template is ready for any school worldwide!**  
Each school gets their own unique, isolated, secure AI assistant.

**No coding required. No technical expertise needed. Just click and deploy!** 🎯 