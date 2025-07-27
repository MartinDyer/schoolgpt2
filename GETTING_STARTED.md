# 🚀 Getting Started with SchoolGPT

**Professional AI Assistant for Educational Institutions - 5-Minute Setup**

---

## 📋 Overview

**SchoolGPT** provides schools with a production-ready, secure AI assistant that can be deployed in just 5 minutes using our fully automated GitHub Actions workflows. No technical expertise required.

### What You'll Get
- ✅ **Secure AI Assistant** - Azure AI Foundry with school-safe content filtering
- ✅ **Unique Resources** - Completely isolated deployment for your school
- ✅ **Automatic Setup** - Everything configured automatically
- ✅ **Professional Grade** - Enterprise security and compliance features

---

## 🏫 For School IT Administrators

### Prerequisites (2 Minutes)
Before starting, ensure you have:

1. **Azure Subscription** - Admin access to your school's Azure account
2. **GitHub Account** - Access to create/fork repositories
3. **Basic Information**:
   - Azure Subscription ID
   - Azure Tenant ID
   - School IT admin email address
   - Your Azure AD Object ID

### Step-by-Step Setup

#### Step 1: Repository Setup (1 Minute)
```bash
# Option A: Fork this repository to your organization
# Click "Fork" button on GitHub

# Option B: Clone for customization
git clone https://github.com/your-org/schoolgpt.git
cd schoolgpt
```

#### Step 2: Azure Service Principal (1 Minute)
Create credentials for automated deployment:

```bash
# Login to Azure
az login

# Create service principal
az ad sp create-for-rbac \
  --name "SchoolGPT-Deployment" \
  --role contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --sdk-auth
```

**Copy the JSON output** - you'll need it in the next step.

#### Step 3: GitHub Secret Configuration (1 Minute)
1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Name: `AZURE_CREDENTIALS`
5. Value: *Paste the JSON from Step 2*
6. Click **"Add secret"**

#### Step 4: Automated Deployment (2 Minutes)
1. Go to the **Actions** tab in your GitHub repository
2. Find **"🔧 Setup SchoolGPT Backend Storage"** workflow
3. Click **"Run workflow"**
4. Fill in the form:
   - **School Name**: Your school's name (e.g., "Lincoln Elementary")
   - **Environment**: `production`
5. Click **"Run workflow"** button
6. Wait for completion (usually 1-2 minutes)

#### Step 5: Deploy Infrastructure (2 Minutes)
1. After backend setup completes, run **"🚀 Deploy SchoolGPT Infrastructure"** workflow
2. Use the same school name and environment
3. Wait for deployment (usually 3-5 minutes)

#### Step 6: Deploy Application (1 Minute)
1. Run **"📱 Deploy SchoolGPT Application"** workflow
2. Application builds and deploys automatically
3. You'll receive a URL to access your AI assistant

### ✅ Setup Complete!

Your school now has a fully functional, secure AI assistant at:
`https://[your-school-prefix]webapp[unique-id].azurewebsites.net`

---

## 🎯 For Multiple Schools

### Enterprise Deployment

If you're deploying for multiple schools:

#### Method 1: Template Approach
1. Each school forks the repository
2. Updates their `terraform.tfvars` with school-specific values
3. Follows the automated deployment process
4. Gets completely unique, isolated resources

#### Method 2: Centralized Management
1. One organization repository
2. Use different environments per school
3. Centralized monitoring and management
4. Per-school cost attribution

---

## 🔧 Configuration Options

### Basic Customization
Schools can customize:
- **School Name & Branding**
- **AI Model Selection** (GPT-3.5-turbo vs GPT-4)
- **Performance Tier** (based on school size)
- **Content Filtering Levels**
- **Authentication Settings**

### Advanced Options
For technical teams:
- **Custom Domain Names**
- **Additional Security Policies**
- **Integration with School Systems**
- **Custom Monitoring Alerts**

---

## 📊 What Gets Created

### For "Lincoln Elementary School":
```
🏫 Resource Group: lincolnelementary-production-rg
🧠 AI Foundry: lincolnelementaryaifoundryabc123
🌐 Web App: lincolnelementarywebappabc123
📦 Backend Storage: lincolnelementarytfstatedef456
🐳 Container Registry: lincolnelementaryacrabc123
🗄️ SQL Database: lincolnelementarysqlsrvabc123
🔐 Key Vault: lincolnelementarykvaabc123
📊 Application Insights: Monitoring & Analytics
```

### Security Features (Automatic)
- ✅ **Content Filtering**: HIGH level for all categories
- ✅ **Access Control**: Azure AD authentication required
- ✅ **Audit Logging**: All conversations logged and monitored
- ✅ **Data Encryption**: At rest and in transit
- ✅ **Backup & Recovery**: Automated daily backups

---

## 💰 Cost Expectations

### Small School (100-500 students)
- **Monthly Cost**: ~$135-185 USD
- **Configuration**: B2 App Service, S1 SQL Database
- **Usage**: Light to moderate AI interactions

### Medium School (500-2000 students)
- **Monthly Cost**: ~$320-470 USD
- **Configuration**: S2 App Service, S2 SQL Database
- **Usage**: Regular AI interactions across multiple classes

### Large School/District (2000+ students)
- **Monthly Cost**: ~$500-800 USD
- **Configuration**: Scalable, multi-region setup
- **Usage**: Heavy usage with advanced features

*Costs automatically scale with actual usage*

---

## 🚨 Troubleshooting

### Common Issues

**"Resource already exists" Error**:
```bash
# Solution: Run the Import Resources workflow first
# Go to Actions → "🔄 Import Existing Resources"
```

**"Access denied" Error**:
```bash
# Solution: Check Azure credentials and permissions
# Ensure service principal has Contributor role
```

**"Workflow failed" Error**:
```bash
# Solution: Check workflow logs for specific errors
# Verify all GitHub secrets are configured correctly
```

### Getting Help
- 📖 **Documentation**: Check specific guide files
- 🐛 **Issues**: Report on GitHub Issues
- 💬 **Community**: Join GitHub Discussions
- 📧 **Support**: Contact your implementation partner

---

## 📚 Next Steps

### After Deployment
1. **Configure Authentication**: Set up Azure AD integration
2. **Test the System**: Verify AI responses and safety features
3. **Train Staff**: Introduce teachers and IT staff to the system
4. **Monitor Usage**: Set up alerts and review analytics
5. **Scale as Needed**: Adjust resources based on actual usage

### Additional Resources
- **[School Setup Guide](SCHOOL_SETUP_GUIDE.md)** - Comprehensive deployment guide
- **[Import Guide](IMPORT_GUIDE.md)** - For migrating existing resources
- **[Infrastructure Guide](infra/README.md)** - Technical details
- **[Security Guide](SECURITY_GUIDE.md)** - Security best practices

---

## 🎯 Success Metrics

### Week 1: Basic Functionality
- ✅ AI assistant responding correctly
- ✅ Authentication working
- ✅ Content filtering active
- ✅ Basic monitoring in place

### Month 1: Full Integration
- ✅ Teachers trained and using system
- ✅ Student adoption growing
- ✅ No security incidents
- ✅ Performance metrics healthy

### Ongoing: Optimization
- ✅ Usage analytics reviewed monthly
- ✅ Cost optimization implemented
- ✅ Feature requests evaluated
- ✅ System updated regularly

---

**🚀 Ready to transform your school's educational experience with AI?**

**[Start Deployment Now](https://github.com/your-org/schoolgpt/actions) | [Join Community](https://github.com/your-org/schoolgpt/discussions)** 