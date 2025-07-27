# 🏫 SchoolGPT - Professional AI Assistant for Schools

**Enterprise-grade, school-safe AI assistant with 100% automated deployment**

[![Deploy to Azure](https://img.shields.io/badge/Deploy%20to-Azure-blue?style=for-the-badge&logo=microsoft-azure)](https://portal.azure.com)
[![Terraform](https://img.shields.io/badge/Infrastructure-Terraform-purple?style=for-the-badge&logo=terraform)](https://www.terraform.io/)
[![GitHub Actions](https://img.shields.io/badge/CI/CD-GitHub%20Actions-green?style=for-the-badge&logo=github-actions)](https://github.com/features/actions)

---

## 🎯 What is SchoolGPT?

**SchoolGPT** is a complete, production-ready AI assistant template specifically designed for educational institutions. Built with Azure AI Foundry and enhanced with school-specific safety features, content filtering, and compliance monitoring.

### ✨ Key Features

- 🧠 **Azure AI Foundry Integration** - Latest GPT models optimized for education
- 🔒 **Enterprise Security** - High-level content filtering and access controls  
- 📚 **Educational Focus** - Age-appropriate responses for students under 16
- 🏫 **Multi-School Ready** - Isolated deployments for each school
- 📊 **Compliance & Auditing** - Complete conversation logging and monitoring
- 🚨 **Real-time Monitoring** - Instant alerts for policy violations
- 🔐 **Azure AD Integration** - Secure, school-only authentication
- ⚡ **5-Minute Deployment** - Fully automated setup process

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

### What Gets Created
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

## 🔒 Safety & Compliance

### Content Safety
- ✅ **HIGH Content Filtering** - Blocks inappropriate content automatically
- ✅ **Age-Appropriate Responses** - Optimized for students under 16  
- ✅ **Educational Focus** - Responses tailored for learning environments
- ✅ **Real-time Monitoring** - Instant alerts for policy violations

### Security Features
- ✅ **Data Encryption** - All data encrypted at rest and in transit
- ✅ **Access Controls** - Azure AD integration with school domains
- ✅ **Audit Logging** - Complete conversation history for compliance
- ✅ **GDPR/COPPA Compliant** - Meets educational privacy standards

---

## 💰 Cost Estimates

### Small School (100-500 students)
- **Azure AI Foundry**: $50-100/month
- **App Service**: $55/month  
- **SQL Database**: $20/month
- **Storage & Monitoring**: $10/month
- **Total**: ~$135-185/month

### Medium School (500-2000 students)  
- **Azure AI Foundry**: $150-300/month
- **App Service**: $110/month
- **SQL Database**: $40/month  
- **Storage & Monitoring**: $20/month
- **Total**: ~$320-470/month

*Costs scale automatically with usage*

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
├── sample-app-aoai-chatGPT/    # Application source code
│   ├── frontend/               # React.js frontend
│   ├── backend/                # Python Flask backend
│   └── WebApp.Dockerfile       # Container configuration
├── DEPLOYMENT_GUIDE.md         # Complete setup instructions
└── README.md                   # This file
```

---

## 🚀 Quick Start

### For Schools (5 Minutes Total)

1. **Fork this repository** 
2. **Add Azure credentials** to GitHub Secrets
3. **Configure terraform.tfvars** with your school details
4. **Run deployment workflows** - fully automated

**That's it!** Your school gets a completely unique, isolated AI assistant.

### For Developers

1. **Clone repository**
2. **Review infrastructure** in `/infra` folder  
3. **Customize application** in `/sample-app-aoai-chatGPT`
4. **Deploy via GitHub Actions**

---

## 📖 Complete Setup Instructions

**👉 See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed step-by-step instructions**

The deployment guide covers:
- ✅ Prerequisites and setup
- ✅ Azure credential configuration  
- ✅ terraform.tfvars configuration
- ✅ CI/CD pipeline usage
- ✅ Troubleshooting and support

---

## 🔧 CI/CD Workflows

This project includes 5 automated workflows:

1. **🔧 Setup Backend Storage** - Creates Terraform remote state storage
2. **🚀 Deploy Infrastructure** - Creates all Azure resources  
3. **📱 Deploy Application** - Builds and deploys the web application
4. **🔄 Import Existing Resources** - Imports existing Azure resources to Terraform state
5. **🗑️ Destroy Infrastructure** - Safely removes all resources

---

## 🌟 Professional Features

### Multi-Tenant Architecture
- **Isolated Deployments** - Each school gets independent resources
- **Automated Provisioning** - 5-minute setup per school
- **Cost Attribution** - Per-school billing and analytics
- **Scalable Design** - Supports unlimited schools

### Monitoring & Analytics  
- **Usage Analytics** - Student interaction patterns
- **Content Monitoring** - Real-time content filter alerts  
- **Performance Metrics** - Response times and availability
- **Cost Tracking** - Azure resource utilization

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🚀 Ready to Deploy?

**[📖 Read the Complete Deployment Guide →](DEPLOYMENT_GUIDE.md)**

**Professional. Secure. Educational. Ready for production.** 