# 🚀 SchoolGPT CI/CD Guide

## Overview

SchoolGPT includes a **complete, automated CI/CD pipeline** designed for **non-technical school administrators**. Everything is managed through **GitHub Actions workflows** with **simple button clicks** - no command-line experience required!

## 🎯 Key Features

✅ **One-Click Deployment** - Deploy complete SchoolGPT with buttons  
✅ **Automated State Management** - Terraform state stored in Azure  
✅ **Environment Support** - Production, Staging, Development  
✅ **Safety Features** - Destroy protection with confirmations  
✅ **Zero Technical Knowledge** - All managed through GitHub web interface  

---

## 📋 Quick Start Checklist

### Prerequisites (One-Time Setup)
- [ ] Azure subscription with admin access
- [ ] GitHub repository (fork of SchoolGPT)
- [ ] Azure Service Principal credentials

### Initial Setup
1. [ ] Add Azure credentials to GitHub Secrets
2. [ ] Run **Setup Backend Storage** workflow
3. [ ] Add backend storage secrets to GitHub
4. [ ] Deploy infrastructure
5. [ ] Deploy application
6. [ ] Configure authentication

---

## 🔧 Step-by-Step Deployment

### Step 1: Add GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

Add these secrets:

| Secret Name | Description | Where to Get |
|-------------|-------------|--------------|
| `AZURE_CREDENTIALS` | Service Principal JSON | Azure Portal → App registrations |

**Azure Credentials Format:**
```json
{
  "clientId": "your-client-id",
  "clientSecret": "your-client-secret",
  "subscriptionId": "your-subscription-id",
  "tenantId": "your-tenant-id"
}
```

### Step 2: Setup Backend Storage

1. Go to **Actions** tab in your GitHub repository
2. Click **"🔧 Setup SchoolGPT Backend Storage"**
3. Click **"Run workflow"**
4. Fill in:
   - **School Name**: `Lincoln Elementary`
   - **Environment**: `production`
5. Click **"Run workflow"**

This creates Azure Storage for Terraform state management.

**After completion:**
- Check the workflow output for backend configuration values
- Add these as GitHub Secrets:
  - `TERRAFORM_STORAGE_ACCOUNT`
  - `TERRAFORM_CONTAINER` 
  - `TERRAFORM_RESOURCE_GROUP_BACKEND`

### Step 3: Deploy Infrastructure

1. Go to **Actions** tab
2. Click **"🚀 Deploy SchoolGPT Infrastructure"**
3. Click **"Run workflow"**
4. Fill in:
   - **Environment**: `production`
   - **School Name**: `Lincoln Elementary`
   - **Action**: `plan` (first run to review)
   - **Auto-approve**: `false`
5. Click **"Run workflow"**

**Review the plan, then run again with:**
- **Action**: `apply`
- **Auto-approve**: `true`

### Step 4: Deploy Application

1. Go to **Actions** tab
2. Click **"🚀 Deploy SchoolGPT Application"**
3. Click **"Run workflow"**
4. Fill in:
   - **Environment**: `production`
   - **School Name**: `Lincoln Elementary`
5. Click **"Run workflow"**

### Step 5: Configure Authentication

1. Visit your app URL (from deployment output)
2. Follow the authentication setup instructions
3. **Your SchoolGPT is ready!** 🎉

---

## 📊 Available Workflows

### 🔧 Setup SchoolGPT Backend Storage
**Purpose**: One-time setup of Azure Storage for Terraform state  
**When to use**: First deployment or after destroying backend  
**Inputs**:
- School Name
- Environment

### 🚀 Deploy SchoolGPT Infrastructure  
**Purpose**: Deploy/update Azure infrastructure (servers, databases, etc.)  
**When to use**: Initial deployment, configuration changes  
**Inputs**:
- Environment (production/staging/development)
- School Name
- Action (plan/apply)
- Auto-approve (safety feature)

### 🚀 Deploy SchoolGPT Application
**Purpose**: Deploy/update the SchoolGPT application code  
**When to use**: Code updates, configuration changes  
**Inputs**:
- Environment
- School Name  
- Force Rebuild (optional)

**Auto-triggers**: When code changes are pushed to main branch

### 🗑️ Destroy SchoolGPT Infrastructure
**Purpose**: **PERMANENTLY DELETE** all SchoolGPT resources  
**When to use**: Cleanup, cost saving, decommissioning  
**Safety Features**:
- Must type "DESTROY" exactly
- Production environment warnings
- 30-second countdown
- Environment protection

**Inputs**:
- Environment
- School Name (must match)
- Confirmation ("DESTROY")
- Destroy Backend Storage (optional)

---

## 🌍 Environment Management

### Production
- **Purpose**: Live system for students and teachers
- **Protection**: Extra confirmations for destructive actions
- **State File**: `production.terraform.tfstate`

### Staging  
- **Purpose**: Testing new features/configurations
- **Protection**: Standard safety measures
- **State File**: `staging.terraform.tfstate`

### Development
- **Purpose**: Development and experimentation
- **Protection**: Minimal restrictions
- **State File**: `development.terraform.tfstate`

**Each environment is completely isolated** - you can deploy different configurations to each.

---

## 🔒 Security Features

### State Management
- **Terraform state stored in Azure Storage** (not in GitHub)
- **Encrypted at rest and in transit**
- **Access controlled via Azure permissions**

### Secrets Management
- **No secrets in code** - all stored in GitHub Secrets and Azure Key Vault
- **ACR credentials auto-retrieved** from Key Vault
- **Service Principal authentication** for Azure access

### Deployment Safety
- **Plan before apply** - review changes before deployment
- **Environment protection** - production requires confirmations
- **Destroy protection** - multiple safety checks
- **Audit trail** - all actions logged in GitHub Actions

---

## 🏫 Multi-School Usage

### Each School Gets:
- **Their own Azure resources** (completely isolated)
- **Their own Terraform state** (separate backend storage)
- **Their own GitHub repository** (fork of template)
- **Their own configurations** (terraform.tfvars)

### Deployment per School:
1. Fork the SchoolGPT repository
2. Follow the setup steps above
3. Customize `terraform.tfvars` for the school
4. Deploy using workflows

**Result**: Each school has a completely independent SchoolGPT deployment.

---

## 📋 Common Workflows

### 🔄 Regular Updates

**Monthly Application Updates:**
1. Click **"Deploy SchoolGPT Application"**
2. Select environment
3. Click **"Run workflow"**

**Infrastructure Changes:**
1. Update `terraform.tfvars` (if needed)
2. Click **"Deploy SchoolGPT Infrastructure"**
3. Select **"plan"** first to review
4. Run again with **"apply"** to deploy

### 🔧 Troubleshooting

**Application Not Working:**
1. Check **Actions** tab for failed workflows
2. Run **"Deploy SchoolGPT Application"** with **Force Rebuild**
3. Check workflow logs for errors

**Infrastructure Issues:**
1. Run **"Deploy SchoolGPT Infrastructure"** with **"plan"**
2. Review the plan output for issues
3. Check Azure Portal for resource status

### 🧹 Cleanup

**Temporary Shutdown (keeping data):**
1. Use **"Destroy SchoolGPT Infrastructure"**
2. **Don't** destroy backend storage
3. Can redeploy later with same configuration

**Permanent Removal:**
1. Use **"Destroy SchoolGPT Infrastructure"**
2. Type **"DESTROY"** to confirm
3. Check **"destroy backend storage"** if removing completely

---

## 💡 Pro Tips

### 🎯 Best Practices
- **Always run "plan" first** for infrastructure changes
- **Use staging environment** for testing changes
- **Keep terraform.tfvars updated** with your school info
- **Monitor costs** through Azure Portal

### ⚡ Efficiency Tips
- **Application updates don't need infrastructure runs**
- **Use Force Rebuild** only when needed (saves time)
- **Check workflow logs** for detailed progress
- **Environment protection** prevents accidents

### 🔍 Monitoring
- **GitHub Actions logs** show detailed deployment progress
- **Azure Portal** shows resource status and costs
- **Application Insights** monitors app performance
- **GitHub Issues** can track problems

---

## 🆘 Getting Help

### 📖 Documentation
- **DEPLOYMENT_GUIDE.md** - Detailed technical steps
- **README.md** - Overall project overview
- **This guide** - CI/CD specifics

### 🐛 Troubleshooting
1. **Check workflow logs** in GitHub Actions
2. **Review error messages** carefully
3. **Try re-running workflows** (often fixes temporary issues)
4. **Check Azure Portal** for resource status

### 💬 Support
- **GitHub Issues** - Report problems
- **GitHub Discussions** - Ask questions
- **Documentation** - Comprehensive guides

---

## 🎉 Success!

With this CI/CD pipeline, **anyone can deploy and manage SchoolGPT** without technical expertise. The workflows handle all the complexity while providing safety and reliability.

**Your school's AI assistant is just a few clicks away!** 🏫✨ 