# School Safe AI App using Azure AI Foundry – Complete 1-Click Deployment

## 🎓 **Complete High Level Design Implementation**

This comprehensive Azure solution provides schools with **safe, monitored AI access** for students under 16. Everything is fully automated with enterprise-grade security, content filtering, and audit logging.

### ✅ **Fully Implemented Features**
- ✅ **Azure AI Foundry Integration** with GPT-3.5-turbo/GPT-4 models
- ✅ **High-Level Content Filtering** for all safety categories  
- ✅ **Enhanced Prompt Engineering** for students under 16
- ✅ **Microsoft Entra ID Authentication** (required for access)
- ✅ **Comprehensive Audit Logging** (all interactions tracked)
- ✅ **Content Filter Violation Tracking** with automated alerts
- ✅ **Real-time Monitoring** with Application Insights
- ✅ **Complete Database Schema** for chat history and audit
- ✅ **1-Click GitHub Actions Deployment**
- ✅ **Enterprise Security** with Key Vault and managed identities

---

## 🚀 **What This Template Creates**

### **1. Azure AI Foundry Platform**
- **AI Foundry Cognitive Services** with OpenAI models
- **Model Deployment**: GPT-3.5-turbo (or GPT-4) with school-safe configuration
- **High Content Filtering**: Blocking inappropriate content across all categories
- **Enhanced System Prompts**: Optimized for educational use by students under 16

### **2. Complete Application Stack**
- **React Frontend**: Microsoft sample app with school customizations
- **Python Backend**: FastAPI with enhanced security and monitoring
- **Docker Containerization**: Azure Container Registry with automated builds
- **Azure App Service**: Linux web app with managed identity

### **3. Database & Storage**
- **Azure SQL Database**: Complete schema for chat history, audit logs, content filter violations
- **Automated Backups**: Built-in disaster recovery
- **Performance Optimization**: Indexed tables and optimized queries

### **4. Security & Monitoring**
- **Application Insights**: Real-time monitoring with custom dashboards
- **Azure Key Vault**: Secure secrets management
- **Content Filter Alerts**: Automated notifications for safety violations
- **Comprehensive Audit Trail**: Every interaction logged for compliance

### **5. DevOps Automation**
- **Terraform Infrastructure**: All resources deployed automatically
- **GitHub Actions**: CI/CD pipeline for app deployments
- **Environment Management**: Separate configs for dev/staging/production

---

## 🟢 **Quick Start - 1-Click Deployment**

### **Step 1: Configure Your Settings**
Edit `terraform.tfvars` with your school's information:

```hcl
# School Configuration
school_name = "Westfield High School AI Assistant"
alert_email = "it-admin@westfield.edu"

# Azure AI Foundry
ai_foundry_name = "westfieldaifoundry"  # MUST BE GLOBALLY UNIQUE
azure_openai_model = "gpt-35-turbo"    # or "gpt-4" for advanced

# Azure Resources (all must be globally unique)
acr_name = "westfieldacr"
web_app_name = "westfield-schoolgpt"
sql_server_name = "westfield-sql"
key_vault_name = "westfield-kv"

# Security (replace with your values)
sql_azuread_admin_login = "admin@westfield.edu"
sql_azuread_admin_object_id = "your-azure-ad-object-id"
key_vault_admin_object_id = "your-azure-ad-object-id"
```

### **Step 2: Set GitHub Secrets**
Add these secrets to **GitHub → Settings → Secrets and variables → Actions**:

| Secret Name | Value | Description |
|-------------|--------|-------------|
| `AZURE_CREDENTIALS` | Service Principal JSON | For GitHub Actions to deploy |
| `AZURE_TENANT_ID` | Your tenant ID | Azure authentication |
| `AZURE_SUBSCRIPTION_ID` | Your subscription ID | Target subscription |

### **Step 3: Deploy Everything**
```bash
git add .
git commit -m "Deploy School Safe AI App"
git push origin main
```

**That's it!** GitHub Actions will:
1. Deploy all Azure infrastructure via Terraform
2. Build and deploy the Microsoft sample app
3. Configure all security and monitoring
4. Initialize the database schema

---

## 🛠️ **Detailed Configuration Options**

### **AI Model Selection**
Choose the best model for your school:

| Model | Best For | Cost | Performance |
|-------|----------|------|-------------|
| `gpt-35-turbo` | Most schools, cost-effective | $ | Fast, reliable |
| `gpt-4` | Advanced reasoning, higher quality | $$$ | Slower, premium |
| `gpt-4o` | Latest with vision capabilities | $$$ | Advanced features |

### **App Service Sizing**
Match your school's usage:

| SKU | Users | Cost | Memory | CPU |
|-----|-------|------|--------|-----|
| `B1` | <50 students | $ | 1.75 GB | 1 core |
| `B2` | <200 students | $$ | 3.5 GB | 2 cores |
| `S1` | <500 students | $$$ | 1.75 GB | 1 core (always-on) |
| `S2` | <1000 students | $$$$ | 3.5 GB | 2 cores |

### **Database Performance**
Scale based on usage:

| SKU | Concurrent Users | Storage | Performance |
|-----|------------------|---------|-------------|
| `Basic` | <10 | 2 GB | Light testing |
| `S1` | <100 | 250 GB | Small schools |
| `S2` | <500 | 250 GB | Medium schools |
| `S3` | <1000 | 250 GB | Large schools |

---

## 🔒 **School-Safe Security Features**

### **Content Filtering (High Level)**
All safety categories set to maximum protection:
- **Hate Speech**: Blocked
- **Sexual Content**: Blocked  
- **Violence**: Blocked
- **Self-Harm**: Blocked
- **Custom Filters**: Educational content only

### **Enhanced Prompt Engineering**
Every AI interaction includes:
```
You are an educational AI assistant for students under 16. 
Provide safe, age-appropriate, educational responses only.
Refuse inappropriate topics and redirect to learning resources.
```

### **Authentication & Access Control**
- **Microsoft Entra ID Required**: No anonymous access
- **Student/Teacher/Admin Roles**: Granular permissions
- **Session Management**: Automatic logout, secure sessions

### **Comprehensive Monitoring**
- **Real-time Alerts**: Instant notifications for safety violations
- **Audit Logging**: Every interaction tracked and stored
- **Dashboard Views**: School administrators can monitor usage
- **Compliance Reports**: Regular safety and usage reports

---

## 📊 **Database Schema Overview**

The system automatically creates these tables:

### **Core Tables**
- **`Users`**: Student/teacher profiles from Entra ID
- **`ChatSessions`**: Grouped conversations by topic
- **`ChatHistory`**: Complete chat history for display
- **`AuditLog`**: Comprehensive audit trail

### **Safety Tables**
- **`ContentFilterViolations`**: Detailed safety incident tracking
- **`SystemMetrics`**: Usage analytics and performance monitoring

### **Automated Features**
- **Performance Indexes**: Optimized for fast queries
- **Audit Triggers**: Automatic logging of all changes
- **Data Views**: Pre-built queries for common reports

To initialize the database schema:
```sql
-- Run the provided SQL script after deployment
sqlcmd -S your-sql-server.database.windows.net -d schoolgptdb -i school_safe_database_schema.sql
```

---

## 🎯 **After Deployment**

### **1. Configure Entra ID Authentication**
1. Go to Azure Portal → App Service → Authentication
2. Add Microsoft as identity provider
3. Configure allowed users/groups (students, teachers, admins)

### **2. Deploy AI Model**
1. Go to Azure AI Foundry portal
2. Deploy your chosen model (GPT-3.5-turbo or GPT-4)
3. Configure content filter policies to "High" for all categories

### **3. Initialize Database**
1. Connect to your Azure SQL database
2. Run the `school_safe_database_schema.sql` script
3. Verify all tables and indexes are created

### **4. Test the Application**
1. Navigate to your web app URL: `https://your-app-name.azurewebsites.net`
2. Sign in with school Entra ID credentials
3. Test with appropriate educational questions
4. Verify content filtering with inappropriate test queries

### **5. Set Up Monitoring**
1. Configure Application Insights dashboards
2. Set up email alerts for content filter violations
3. Create usage reports for school administrators

---

## 🧑‍💻 **Advanced Customization**

### **UI Customization for Schools**
The app includes school-specific branding:
```javascript
// Customizable in terraform.tfvars
UI_TITLE = "Your School AI Assistant"
UI_CHAT_TITLE = "School AI Assistant" 
UI_CHAT_DESCRIPTION = "Ask educational questions!"
```

### **Content Filter Customization**
Adjust filtering levels in `main.tf`:
```hcl
# Content Filter Settings (0=Off, 1=Low, 2=High)
"AZURE_OPENAI_CONTENT_FILTER_HATE" = "2"
"AZURE_OPENAI_CONTENT_FILTER_SEXUAL" = "2"
"AZURE_OPENAI_CONTENT_FILTER_VIOLENCE" = "2"
"AZURE_OPENAI_CONTENT_FILTER_SELF_HARM" = "2"
```

### **Adding Custom Subjects**
Track conversations by subject:
```sql
-- Add to ChatHistory table
UPDATE ChatHistory 
SET Subject = 'Mathematics' 
WHERE UserMessage LIKE '%math%' OR UserMessage LIKE '%algebra%'
```

---

## 📈 **Monitoring & Analytics**

### **Real-Time Dashboards**
View live usage in Application Insights:
- **Active Users**: Students and teachers online
- **Message Volume**: Conversations per hour/day
- **Response Times**: AI performance metrics
- **Error Rates**: System health monitoring

### **Safety Monitoring**
Track content safety:
- **Filter Triggers**: Safety violations by type and severity
- **User Patterns**: Identify users needing guidance
- **Trend Analysis**: Safety patterns over time

### **Usage Analytics**
Understand educational impact:
- **Popular Subjects**: Most discussed topics
- **Peak Usage**: When students use the system most
- **Engagement Metrics**: Session duration and message count

---

## 🆘 **Troubleshooting**

### **Common Issues**

**Deployment Fails**
- Verify all resource names are globally unique
- Check Azure subscription limits and quotas
- Ensure GitHub secrets are configured correctly

**Authentication Not Working**
- Configure Entra ID authentication in Azure Portal
- Verify redirect URLs are correctly set
- Check user permissions and group memberships

**Content Filter Too Restrictive**
- Adjust filter levels in Terraform configuration
- Test with educational content to verify appropriate responses
- Review AI Foundry content filter policies

**Database Connection Issues**
- Verify SQL firewall rules allow Azure services
- Check connection strings in Key Vault
- Ensure managed identity has database permissions

### **Getting Help**
- Check Application Insights for error details
- Review audit logs for security issues
- Contact your Azure administrator for infrastructure support

---

## 🏆 **Best Practices for Schools**

### **Security**
1. **Regular Reviews**: Monitor content filter violations weekly
2. **User Management**: Review student/teacher access quarterly  
3. **Backup Verification**: Test database backups monthly
4. **Security Updates**: Keep all components updated

### **Educational Use**
1. **Teacher Training**: Provide guidance on AI-assisted learning
2. **Student Guidelines**: Clear policies on appropriate AI use
3. **Subject Integration**: Encourage AI use across curricula
4. **Assessment**: Monitor educational impact and learning outcomes

### **Compliance**
1. **Data Privacy**: Ensure FERPA/GDPR compliance
2. **Audit Trails**: Maintain comprehensive logging
3. **Incident Response**: Have procedures for safety violations
4. **Regular Reporting**: Provide usage and safety reports to leadership

---

## 📞 **Support & Community**

- **Documentation**: This README and inline code comments
- **Issue Tracking**: Use GitHub Issues for bug reports
- **Feature Requests**: Submit enhancement suggestions
- **Community**: Share experiences with other educational institutions

---

**🎓 Your School Safe AI App is ready to transform education with secure, monitored AI assistance for students under 16!** 