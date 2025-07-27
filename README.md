# 🏫 SchoolGPT - Professional AI Assistant for Educational Institutions

**Enterprise-grade, school-safe AI assistant template with 100% automated deployment**

[![Deploy to Azure](https://img.shields.io/badge/Deploy%20to-Azure-blue?style=for-the-badge&logo=microsoft-azure)](https://portal.azure.com)
[![Terraform](https://img.shields.io/badge/Infrastructure-Terraform-purple?style=for-the-badge&logo=terraform)](https://www.terraform.io/)
[![GitHub Actions](https://img.shields.io/badge/CI/CD-GitHub%20Actions-green?style=for-the-badge&logo=github-actions)](https://github.com/features/actions)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

---

## 🎯 Executive Summary

**SchoolGPT** is a complete, production-ready AI assistant template specifically designed for educational institutions. Built with Azure AI Foundry and enhanced with school-specific safety features, content filtering, and compliance monitoring.

### 🏆 Key Features

- 🧠 **Azure AI Foundry Integration** - Latest GPT models optimized for education
- 🔒 **Enterprise Security** - High-level content filtering and access controls
- 📚 **Educational Focus** - Age-appropriate responses for students under 16
- 🏫 **Multi-Tenant Architecture** - Isolated deployments for each school
- 📊 **Compliance & Auditing** - Complete conversation logging and monitoring
- 🚨 **Real-time Monitoring** - Instant alerts for policy violations
- 🔐 **Azure AD Integration** - Secure, school-only authentication
- ⚡ **5-Minute Deployment** - Fully automated setup process

---

## 🚀 Quick Deployment

### For Schools (5 Minutes Setup)

1. **Fork this repository**
2. **Add Azure credentials** to GitHub Secrets (`AZURE_CREDENTIALS`)
3. **Run setup workflow** with your school name
4. **Deploy infrastructure** - automated in GitHub Actions

**That's it!** Your school gets a completely unique, isolated AI assistant.

### What Gets Created Automatically

For **"Lincoln Elementary School"**:
```
🏫 Resource Group: lincolnelementary-production-rg
🧠 AI Foundry: lincolnelementaryaifoundryabc123
🌐 Web App: lincolnelementarywebappabc123
📦 Storage: lincolnelementarytfstatedef456
🐳 Registry: lincolnelementaryacrabc123
🗄️ Database: lincolnelementarysqlsrvabc123
🔐 Key Vault: lincolnelementarykvaabc123
```

---

## 🏗️ Architecture

### Technology Stack

- **Frontend**: React.js with TypeScript
- **Backend**: Python Flask with Azure integration
- **AI Engine**: Azure AI Foundry (OpenAI GPT models)
- **Database**: Azure SQL with automated backups
- **Infrastructure**: Terraform with Azure provider
- **CI/CD**: GitHub Actions with automated testing
- **Monitoring**: Application Insights with custom alerts
- **Security**: Azure Key Vault + Entra ID authentication

### Safety & Compliance Features

- ✅ **Content Filtering**: HIGH level for all inappropriate content
- ✅ **Age Verification**: Responses optimized for students under 16
- ✅ **Conversation Logging**: Complete audit trail for compliance
- ✅ **Access Controls**: Azure AD integration with school domains
- ✅ **Real-time Monitoring**: Instant alerts for violations
- ✅ **Data Privacy**: GDPR/COPPA compliant data handling

---

## 📋 Prerequisites

### For Schools
- Azure subscription (admin access)
- GitHub account
- Basic Azure information (subscription ID, tenant ID)

### For Developers
- Git
- GitHub account with repository access
- Azure CLI (for testing)

---

## 🛠️ Deployment Guide

### Step 1: Repository Setup
```bash
# Fork this repository or clone for your organization
git clone <your-forked-repo>
cd schoolgpt
```

### Step 2: Azure Credentials
1. Create Azure Service Principal
2. Add `AZURE_CREDENTIALS` secret to GitHub repository
3. Grant appropriate permissions in Azure

### Step 3: Automated Deployment
1. Go to **Actions** tab in GitHub
2. Run **"🔧 Setup SchoolGPT Backend Storage"** workflow
3. Provide school name and environment
4. Run **"🚀 Deploy SchoolGPT Infrastructure"** workflow
5. Access your deployed application

### Step 4: Application Deployment
1. Run **"📱 Deploy SchoolGPT Application"** workflow
2. Application builds and deploys automatically
3. School AI assistant is live and ready

---

## 📁 Project Structure

```
schoolgpt/
├── .github/workflows/           # Automated CI/CD pipelines
│   ├── 00-setup-backend.yml    # Backend storage setup
│   ├── 01-deploy-infrastructure.yml  # Infrastructure deployment
│   ├── 02-destroy-infrastructure.yml # Resource cleanup
│   ├── 03-deploy-application.yml     # Application deployment
│   └── 99-import-existing-resources.yml  # State import
├── infra/                       # Terraform infrastructure
│   ├── main.tf                 # Main infrastructure definition
│   ├── variables.tf            # Configuration variables
│   ├── terraform.tfvars        # Environment-specific values
│   └── README.md               # Infrastructure documentation
├── sample-app-aoai-chatGPT/    # Application source code (submodule)
│   ├── frontend/               # React.js frontend
│   ├── backend/                # Python Flask backend
│   ├── WebApp.Dockerfile       # Container configuration
│   └── app.py                  # Main application
├── SCHOOL_SETUP_GUIDE.md       # School deployment guide
├── IMPORT_GUIDE.md             # Resource import guide
└── README.md                   # This file
```

---

## 💰 Cost Analysis

### Monthly Costs (Estimated)

**Small School (100-500 students)**:
- Azure AI Foundry: $50-100/month
- App Service (B2): $55/month
- SQL Database (S1): $20/month
- Storage & Monitoring: $10/month
- **Total: ~$135-185/month**

**Medium School (500-2000 students)**:
- Azure AI Foundry: $150-300/month
- App Service (S2): $110/month
- SQL Database (S2): $40/month
- Storage & Monitoring: $20/month
- **Total: ~$320-470/month**

*Costs scale automatically with usage*

---

## 🔧 Configuration

### School-Specific Settings

Schools can customize:
- **Model Selection**: GPT-3.5-turbo (cost-effective) or GPT-4 (advanced)
- **Content Filtering**: Adjust sensitivity levels
- **User Access**: Configure Azure AD integration
- **Monitoring**: Set up custom alerts and notifications
- **Branding**: Customize UI with school colors and logo

### Environment Variables

All sensitive configuration is managed through Azure Key Vault:
- Database connection strings
- AI Foundry API keys
- Authentication secrets
- Third-party integrations

---

## 📊 Monitoring & Analytics

### Built-in Dashboards
- **Usage Analytics**: Student interaction patterns
- **Content Monitoring**: Real-time content filter alerts
- **Performance Metrics**: Response times and availability
- **Cost Tracking**: Azure resource utilization

### Alerts & Notifications
- Content filter violations → Email alerts
- High usage periods → Cost optimization suggestions
- System errors → Automatic incident creation
- Security events → Admin notifications

---

## 🔒 Security Features

### Data Protection
- All data encrypted at rest and in transit
- Regular automated backups
- Compliance with GDPR, COPPA, and FERPA
- Audit logs for all interactions

### Access Control
- Azure AD integration
- Role-based permissions
- School domain restrictions
- Session management

### Content Safety
- Real-time content filtering
- Age-appropriate response tuning
- Conversation monitoring
- Automated policy enforcement

---

## 🚀 Scaling for Multiple Schools

### Enterprise Deployment

This template supports unlimited schools with:
- **Isolated Tenants**: Each school gets independent resources
- **Automated Provisioning**: 5-minute setup per school
- **Centralized Management**: Monitor all deployments
- **Cost Attribution**: Per-school billing and analytics

### Business Model Ready

- **SaaS Deployment**: Host for multiple schools
- **White-label Options**: Customize branding per school
- **Tiered Pricing**: Different feature sets by plan
- **Support Integration**: Built-in help desk and documentation

---

## 📚 Documentation

- **[School Setup Guide](SCHOOL_SETUP_GUIDE.md)** - Step-by-step for schools
- **[Import Guide](IMPORT_GUIDE.md)** - Migrate existing resources
- **[Infrastructure Guide](infra/README.md)** - Technical infrastructure details
- **[CI/CD Guide](CICD_GUIDE.md)** - Development and deployment workflows
- **[Deployment Guide](DEPLOYMENT_GUIDE.md)** - Advanced deployment scenarios

---

## 🤝 Support

### For Schools
- 📧 Email support: support@schoolgpt.com
- 📞 Phone support: Available during business hours
- 💬 Community forum: Ask questions and share experiences
- 📖 Knowledge base: Comprehensive documentation

### For Developers
- 🐛 Issue tracking: GitHub Issues
- 💡 Feature requests: GitHub Discussions
- 🔧 Technical support: Developer documentation
- 🤝 Contributing: Pull requests welcome

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🎯 Ready to Deploy?

**Get your school's AI assistant up and running in 5 minutes:**

1. **[📖 Read the School Setup Guide](SCHOOL_SETUP_GUIDE.md)**
2. **[🚀 Start Deployment Process](https://github.com/your-org/schoolgpt/actions)**
3. **[💬 Join Our Community](https://github.com/your-org/schoolgpt/discussions)**

**Professional. Secure. Educational. Ready for production.** 