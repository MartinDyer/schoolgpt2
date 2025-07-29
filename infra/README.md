# SchoolGPT Infrastructure - Simplified Azure AI Foundry Deployment

A **simplified, cost-effective** infrastructure template for deploying a school-safe AI chat application using Azure AI Foundry and Microsoft's native stack.

## 🎯 **Key Features**

- ✅ **Azure AI Foundry** - Complete AI service with content filtering
- ✅ **Azure Table Storage** - Cost-effective chat history storage
- ✅ **Entra ID Authentication** - Secure user management
- ✅ **Container Deployment** - Docker-based application hosting
- ✅ **Application Insights** - Monitoring and analytics
- ✅ **Key Vault** - Secure secrets management

## 🏗️ **Architecture Overview**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Students      │    │   Teachers      │    │   Administrators │
│   (Entra ID)    │    │   (Entra ID)    │    │   (Entra ID)    │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │    🌐 School AI App       │
                    │   (Container Web App)     │
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │    🔐 Key Vault           │
                    │   (Secrets Management)    │
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │    🧠 AI Foundry          │
                    │   (Content Filtering)     │
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │    📋 Table Storage       │
                    │   (Chat History)          │
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │    📈 App Insights        │
                    │   (Monitoring)            │
                    └───────────────────────────┘
```

## 📊 **Resource Breakdown**

| **Component** | **Purpose** | **Features** |
|---------------|-------------|--------------|
| **AI Foundry** | AI service with content filtering | School-safe responses, content moderation |
| **App Service** | Web application hosting | Auto-scaling enabled |
| **Container Registry** | Docker image storage | Private repository |
| **Table Storage** | Chat history storage | Cost-effective, simple management |
| **Key Vault** | Secure secrets management | Access policies configured |
| **Application Insights** | Monitoring and analytics | Custom dashboards |
| **Storage Account** | Terraform state management | Geo-redundant |

## 💰 **Cost Optimization**

### **Why This Architecture is Cost-Effective:**

1. **No SQL Server** - Eliminates ~$20-80/month database costs
2. **Table Storage** - 80% cheaper than Cosmos DB for chat history
3. **Entra ID** - Free user management (no local database needed)
4. **Auto-scaling** - Pay only for what you use

### **Estimated Monthly Costs**

| School Size | App Service | AI Foundry | Table Storage | Monitoring | **Total** |
|-------------|-------------|------------|---------------|------------|-----------|
| Small (100-500) | $55 | $50-100 | $5 | $10 | **$120-170** |
| Medium (500-2000) | $110 | $150-300 | $10 | $20 | **$290-440** |
| Large (2000+) | $200 | $300-500 | $20 | $30 | **$550-750** |

### **Table Storage Benefits**

**Cost-Effective Chat History:**
- ✅ **80% cost savings** vs Cosmos DB
- ✅ **Automatic scaling** with usage
- ✅ **Built-in encryption** and security
- ✅ **Microsoft native** integration
- ✅ **Simple management** via Azure Portal

---

## 🚀 **Quick Start**

### **Prerequisites**
- Azure subscription
- Azure CLI installed
- Terraform installed

### **1. Clone and Configure**
```bash
# Clone the repository
git clone <your-repo>
cd schoolgpt/infra

# Copy and configure variables
cp terraform.tfvars.template terraform.tfvars
# Edit terraform.tfvars with your values
```

### **2. Deploy Infrastructure**
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Deploy infrastructure
terraform apply
```

### **3. Configure Authentication**
1. Go to Azure Portal → App Service
2. Configure Entra ID authentication
3. Set up user access policies

### **4. Deploy Application**
1. Push code to trigger GitHub Actions
2. Monitor deployment in Azure Portal
3. Test the application

---

## 🔧 **Configuration**

### **Required Variables**

Update `terraform.tfvars` with your values:

```hcl
# Azure Subscription
azure_subscription_id = "your-subscription-id"
azure_tenant_id       = "your-tenant-id"

# School Configuration
school_name           = "Your School Name"
alert_email           = "admin@yourschool.edu"

# Globally Unique Names
ai_foundry_name       = "yourschool-ai-foundry"
ai_foundry_subdomain  = "yourschool-ai-foundry"
acr_name              = "yourschoolacr"
web_app_name          = "yourschool-ai-app"
key_vault_name        = "yourschool-kv"

# Admin Access
key_vault_admin_object_id = "your-object-id"
```

### **Environment Variables**

The application automatically configures:

```bash
# AI Foundry
AZURE_OPENAI_ENDPOINT=https://your-ai-foundry.openai.azure.com/
AZURE_OPENAI_KEY=your-api-key
AZURE_OPENAI_MODEL=gpt-35-turbo

# Table Storage
TABLE_STORAGE_CONNECTION_STRING=your-connection-string
TABLE_STORAGE_CONVERSATIONS_TABLE=conversations
TABLE_STORAGE_MESSAGES_TABLE=messages

# Authentication
AUTH_ENABLED=true
ENTRA_ID_ENABLED=true
```

---

## 🔒 **Security Features**

### **Content Filtering**
- **High-level filtering** for school safety
- **Automatic content moderation**
- **Age-appropriate responses**
- **Violation logging and alerts**

### **Authentication**
- **Entra ID integration**
- **Role-based access control**
- **Secure token management**
- **No local user database**

### **Data Protection**
- **Encryption at rest**
- **Encryption in transit**
- **Key Vault for secrets**
- **Audit logging**

---

## 📈 **Monitoring & Alerts**

### **Application Insights**
- **Real-time monitoring**
- **Performance metrics**
- **Error tracking**
- **Usage analytics**

### **Alert Configuration**
- **Content filter violations**
- **System health issues**
- **Performance degradation**
- **Security events**

---

## 🛠️ **Troubleshooting**

### **Common Issues**

1. **Authentication Errors**
   - Verify Entra ID configuration
   - Check user permissions
   - Validate token settings

2. **Content Filter Issues**
   - Review filter policies
   - Check AI Foundry settings
   - Monitor violation logs

3. **Storage Connection Issues**
   - Verify Table Storage connection
   - Check Key Vault access
   - Validate managed identity

### **Support Resources**
- Azure Portal monitoring
- Application Insights logs
- Terraform state inspection
- GitHub Actions logs

---

## 📚 **Next Steps**

1. **Configure Entra ID authentication**
2. **Deploy your application code**
3. **Set up monitoring dashboards**
4. **Train staff on usage**
5. **Monitor and optimize costs**

---

## 🤝 **Contributing**

This template is designed for educational institutions. Contributions welcome!

---

## 📄 **License**

MIT License - See LICENSE file for details. 