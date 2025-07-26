# 📚 SchoolGPT Deployment Guide for IT Administrators

## Prerequisites Checklist

### Azure Requirements
- [ ] Azure subscription with **Contributor** or **Owner** access
- [ ] Azure CLI installed on your machine ([Download here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- [ ] Terraform installed ([Download here](https://www.terraform.io/downloads.html))

### Information You'll Need
- [ ] Azure Subscription ID
- [ ] Azure Tenant ID  
- [ ] Your Azure AD Object ID (for admin access)
- [ ] School IT admin email address
- [ ] Desired Azure region (e.g., `uksouth`, `eastus`, `westeurope`)

---

## Step-by-Step Deployment

### Step 1: Gather Azure Information

#### Get Subscription ID
```bash
az login
az account show --query id --output tsv
```

#### Get Tenant ID
```bash
az account show --query tenantId --output tsv
```

#### Get Your Object ID
```bash
az ad signed-in-user show --query id --output tsv
```

### Step 2: Choose Globally Unique Names

Azure requires globally unique names for certain resources. Use your school's name/abbreviation:

```bash
# Example for "Lincoln Elementary School"
ai_foundry_name = "lincoln-elem-ai-foundry"
acr_name = "lincolnelemacr"
web_app_name = "lincoln-elem-ai-app"
sql_server_name = "lincoln-elem-sql"
key_vault_name = "lincoln-elem-kv"
```

### Step 3: Configure terraform.tfvars

Copy the template and fill in your values:

```bash
cp terraform.tfvars.template infra/terraform.tfvars
```

**Example configuration for "Lincoln Elementary":**

```hcl
# Azure Information
azure_subscription_id = "12345678-1234-1234-1234-123456789012"
azure_tenant_id       = "87654321-4321-4321-4321-210987654321"

# School Information
school_name = "Lincoln Elementary AI Assistant"
alert_email = "technology@lincoln.edu"
location    = "uksouth"

# Globally Unique Names
resource_group_name   = "lincoln-elem-ai-rg"
ai_foundry_name      = "lincoln-elem-ai-foundry"
ai_foundry_subdomain = "lincoln-elem-ai"
acr_name             = "lincolnelemacr"
web_app_name         = "lincoln-elem-ai-app"
sql_server_name      = "lincoln-elem-sql"
key_vault_name       = "lincoln-elem-kv"

# Admin Access
sql_azuread_admin_login     = "admin@lincoln.edu"
sql_azuread_admin_object_id = "YOUR-OBJECT-ID-HERE"
key_vault_admin_object_id   = "YOUR-OBJECT-ID-HERE"

# Security
sql_password = "LincolnSecure123!"

# School Size Configuration
app_service_sku = "B2"  # Medium school
sql_sku_name    = "S1"  # Standard performance
```

### Step 4: Deploy Infrastructure

```bash
cd infra

# Initialize Terraform
terraform init

# Review deployment plan
terraform plan

# Deploy (takes 10-15 minutes)
terraform apply
```

**Expected Output:**
```
Apply complete! Resources: 20 added, 0 changed, 0 destroyed.

Outputs:
deployment_summary = {
  "web_app_url" = "https://lincoln-elem-ai-app.azurewebsites.net"
  "ai_foundry_endpoint" = "https://lincoln-elem-ai.openai.azure.com/"
  # ... other outputs
}
```

### Step 5: Configure GitHub Actions (For Automated Deployments)

#### Create Service Principal
```bash
az ad sp create-for-rbac --name "schoolgpt-github-actions" \
  --role contributor \
  --scopes /subscriptions/YOUR-SUBSCRIPTION-ID \
  --sdk-auth
```

#### Add GitHub Secrets
Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:
```
AZURE_CREDENTIALS: {copy the JSON output from above}
ACR_LOGIN_SERVER: yourschoolacr.azurecr.io
ACR_USERNAME: (from terraform output)
ACR_PASSWORD: (from terraform output)
WEB_APP_NAME: your-school-ai-app
RESOURCE_GROUP: your-school-ai-rg
```

### Step 6: Deploy Application Code

```bash
# Commit and push to trigger deployment
git add .
git commit -m "Deploy SchoolGPT for Lincoln Elementary"
git push origin main
```

### Step 7: Configure Authentication

1. **Wait for deployment** (5-10 minutes after push)
2. **Visit your app URL** (from terraform output)
3. **Follow authentication setup**:
   - Click "Azure Portal" link
   - Navigate to your app → Authentication
   - Add Microsoft identity provider
   - Configure for your school's tenant

---

## School Size Recommendations

### Small School (< 500 students)
```hcl
app_service_sku = "B1"
sql_sku_name    = "Basic"
model_capacity  = 60
```
**Monthly Cost**: ~$150-200

### Medium School (500-1500 students)
```hcl
app_service_sku = "B2"
sql_sku_name    = "S1"
model_capacity  = 120
```
**Monthly Cost**: ~$250-350

### Large School (1500+ students)
```hcl
app_service_sku = "S1"
sql_sku_name    = "S2"
model_capacity  = 240
```
**Monthly Cost**: ~$400-600

---

## Post-Deployment Configuration

### Database Initialization
```bash
# Connect to your SQL database and run the schema
sqlcmd -S your-sql-server.database.windows.net \
       -d schoolgptdb \
       -U sqladminuser \
       -P 'YourPassword!' \
       -i school_safe_database_schema.sql
```

### Monitor Setup
1. **Application Insights**: Automatically configured
2. **Alerts**: Set up for content filter violations
3. **Cost Management**: Set up budget alerts in Azure Portal

### User Access Management
1. **Azure AD Groups**: Create groups for students, teachers, staff
2. **Conditional Access**: Configure based on your school's policy
3. **Usage Analytics**: Monitor through Application Insights

---

## Troubleshooting

### Common Issues

#### Issue: "Resource name not available"
**Solution**: Resource names must be globally unique. Try:
- Adding your location: `lincoln-ca-ai-app`
- Adding year: `lincoln-2024-ai-app`
- Adding random suffix: `lincoln-ai-app-xyz`

#### Issue: "Insufficient permissions"
**Solution**: Ensure you have:
- Contributor access to the subscription
- Permission to create Azure AD app registrations
- Permission to assign roles

#### Issue: "Deployment fails"
**Solution**:
```bash
# Check logs
terraform show
terraform refresh

# Clean up and retry
terraform destroy
terraform apply
```

#### Issue: "App not loading"
**Solution**:
1. Check GitHub Actions completed successfully
2. Verify Docker image was pushed to ACR
3. Check Application Insights for errors

### Getting Help

1. **Check logs**: Azure Portal → Your App Service → Log stream
2. **Review documentation**: This repository's docs folder  
3. **GitHub Issues**: Report problems with detailed error messages
4. **Community**: Join our discussions for peer support

---

## Security Best Practices

### Access Control
- [ ] Configure Azure AD groups for different user types
- [ ] Set up conditional access policies
- [ ] Review permissions regularly

### Monitoring
- [ ] Set up Application Insights alerts
- [ ] Configure budget alerts
- [ ] Review audit logs monthly

### Updates
- [ ] Monitor for security updates
- [ ] Test updates in staging environment
- [ ] Keep Terraform and Azure CLI updated

---

## Maintenance Schedule

### Weekly
- [ ] Review chat audit logs
- [ ] Check Application Insights for errors
- [ ] Monitor usage and costs

### Monthly  
- [ ] Review security alerts
- [ ] Update documentation
- [ ] Backup configuration

### Quarterly
- [ ] Review access permissions
- [ ] Evaluate performance and scaling
- [ ] Plan for updates and new features

---

## Next Steps After Deployment

1. **Test the application** with sample educational queries
2. **Train teachers** on appropriate AI usage
3. **Create student guidelines** for AI assistance
4. **Set up monitoring dashboards** for administrators
5. **Plan for scale** as usage grows

---

**Your SchoolGPT deployment is now complete! 🎉**

For ongoing support and community discussions, visit our [GitHub repository](https://github.com/your-repo/schoolgpt). 