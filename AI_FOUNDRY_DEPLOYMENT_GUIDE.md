# AI Foundry Deployment Guide for Schools

This guide helps each school deploy their own dedicated Azure OpenAI (AI Foundry) resource.

## Why Each School Gets Their Own AI Foundry?

**Benefits:**
- ✅ Dedicated 100k token quota per school
- ✅ No sharing conflicts with other schools
- ✅ Independent cost tracking and billing
- ✅ Full control over AI configuration
- ✅ Better performance isolation

---

## Prerequisites

- Azure subscription with appropriate permissions
- Ability to create Azure OpenAI resources
- Basic Azure Portal knowledge

---

## Step-by-Step Deployment

### Step 1: Create AI Foundry Resource

1. **Log into Azure Portal**: https://portal.azure.com

2. **Create Resource**:
   - Click "Create a resource"
   - Search for "Azure OpenAI"
   - Click "Create"

3. **Configure**:
   ```
   Subscription: [Your Azure Subscription]
   Resource Group: [Create new] rg-[school-name]-ai-foundry
   Region: UK South (or your preferred region)
   Name: [school-name]-ai-foundry
   Pricing Tier: S0 (Standard)
   ```

4. **Click "Review + Create"** → **Create**

⏱️ **Wait 2-5 minutes** for deployment to complete

---

### Step 2: Create GPT-4 Deployment

1. **Go to your AI Foundry resource**

2. **Navigate to**: Model deployments → Create

3. **Configure deployment**:
   ```
   Model: gpt-4o (or gpt-4o-mini for lower cost)
   Deployment name: gpt-4o
   Model version: Latest (2024-11-20 or newer)
   Deployment type: Standard
   Tokens per minute rate limit: 100K (or request increase)
   ```

4. **Click "Create"**

---

### Step 3: Get Configuration Details

After deployment, collect these values:

**1. Endpoint**:
- Go to your AI Foundry resource
- Click "Keys and Endpoint"
- Copy the **Endpoint URL**
- Format: `https://[your-name].openai.azure.com/`

**2. Deployment Name**:
- Go to "Model deployments"
- Note the deployment name (e.g., `gpt-4o`)

**3. API Version**:
- Use: `2024-08-01-preview` (or latest)

---

### Step 4: Configure Managed Identity Access

**Important**: The school's web app needs permission to use this AI resource.

**After the web app is deployed**, grant access:

1. **Get Web App Identity**:
   ```bash
   # The web app principal ID will be provided after deployment
   # Format: 12345678-1234-1234-1234-123456789abc
   ```

2. **Grant Permission**:
   - Go to your AI Foundry resource
   - Click "Access control (IAM)"
   - Click "+ Add" → "Add role assignment"
   - **Role**: Cognitive Services OpenAI User
   - Click "Next"
   - **Assign access to**: Managed identity
   - Click "+ Select members"
   - **Select**: [School-WebApp-Name]
   - Click "Review + assign"

---

## Configuration Values for Deployment

Provide these values to your deployment team:

```bash
# AI Foundry Configuration
AZURE_OPENAI_ENDPOINT="https://[your-ai-name].openai.azure.com/"
AZURE_OPENAI_DEPLOYMENT="gpt-4o"
AZURE_OPENAI_API_VERSION="2024-08-01-preview"

# Resource Details
AI_FOUNDRY_RESOURCE_NAME="[your-ai-name]"
AI_FOUNDRY_RESOURCE_GROUP="rg-[school-name]-ai-foundry"
```

---

## Cost Estimation

**AI Foundry Costs** (per school):

| Model | Input (per 1K tokens) | Output (per 1K tokens) | Monthly Estimate* |
|-------|---------------------|----------------------|------------------|
| gpt-4o | $0.0025 | $0.01 | $50-150 |
| gpt-4o-mini | $0.00015 | $0.0006 | $10-30 |

*Based on moderate usage (~10-50 students, 20 messages/day)

**Recommendations:**
- Start with **gpt-4o-mini** for cost savings
- Upgrade to **gpt-4o** if better quality is needed
- Monitor usage in Azure Portal → Cost Management

---

## Quota Increase Request

If you need more than 100K tokens per minute:

1. Go to Azure Portal → Your AI Foundry resource
2. Click "Quotas" in left menu
3. Click "Request quota increase"
4. Fill in the form with:
   - Model: gpt-4o
   - Deployment: [your deployment name]
   - Requested tokens per minute: [e.g., 300K]
   - Justification: "School AI chatbot for [X] students"

⏱️ Approval typically takes 1-3 business days

---

## Security Best Practices

1. ✅ **Use Managed Identity** (no API keys in code)
2. ✅ **Enable Content Filtering** (default is enabled)
3. ✅ **Monitor Usage** (set up cost alerts)
4. ✅ **Restrict Access** (only grant to school's web app)

---

## Troubleshooting

### Error: "Quota Exceeded"
**Solution**: Request quota increase (see above)

### Error: "Access Denied"
**Solution**: Verify Managed Identity role assignment (Step 4)

### Error: "Deployment Not Found"
**Solution**: Verify deployment name matches configuration

---

## Support

For Azure OpenAI issues:
- Azure Support Portal: https://portal.azure.com → Support
- Documentation: https://learn.microsoft.com/en-us/azure/ai-services/openai/

For deployment assistance:
- Contact your technical team
- Refer to main [DEPLOYMENT.md](./DEPLOYMENT.md)

---

## Quick Reference

**Must-Have Values:**
```bash
✓ Endpoint URL
✓ Deployment Name  
✓ API Version
✓ Resource Group Name
```

**Must-Do Steps:**
```bash
✓ Create AI Foundry resource
✓ Deploy GPT model
✓ Grant Managed Identity access
✓ Provide config to deployment team
```

**Timeline:**
- AI Foundry creation: ~5 minutes
- Model deployment: ~2 minutes
- Permission setup: ~2 minutes
- **Total: ~10-15 minutes**

---

## Next Steps

After completing this guide:

1. ✅ Email configuration values to deployment team
2. ✅ Confirm web app deployment is complete
3. ✅ Test AI chat functionality
4. ✅ Set up cost alerts in Azure Portal

Your school's AI chatbot will be ready to use! 🚀
