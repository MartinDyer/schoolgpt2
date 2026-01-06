# SchoolGPT Deployment Guide

## Quick Start

### Prerequisites
- Azure subscription with appropriate permissions
- GitHub repository configured
- Azure CLI installed locally

### One-Command Deployment

```bash
# Run the deployment workflow
gh workflow run "06- Deploy Full App" --ref main
```

**Expected Duration:** 5-10 minutes

---

## Configuration Reference

### Required Environment Variables

#### App Service (`School-Safe-GPT-FE-1234`)
```bash
PORT=8080
NODE_VERSION=20-lts
SCM_DO_BUILD_DURING_DEPLOYMENT=true
AZURE_OPENAI_ENDPOINT=https://chatgpt-safe.cognitiveservices.azure.com/
AZURE_OPENAI_DEPLOYMENT=Test-gpt-4.1-mini
AZURE_OPENAI_API_VERSION=2024-08-01-preview
```

#### Frontend Build (`.env`)
```env
VITE_API_BASE=
VITE_AZURE_CLIENT_ID=abeede17-553a-4a0e-b2e2-ca619305a0e3
VITE_AZURE_TENANT_ID=<your-tenant-id>
```

**Note:** `VITE_API_BASE` should be empty string for production (uses relative paths)

---

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────┐
│          Azure App Service (Linux)              │
│  ┌──────────────────┐  ┌────────────────────┐  │
│  │    Frontend      │  │     Backend        │  │
│  │  React + Vite    │──│  Node.js Express   │  │
│  │  (Static Files)  │  │  Port: 8080        │  │
│  └──────────────────┘  └────────────────────┘  │
│              │                    │             │
│              │         ┌──────────┴─────────┐   │
│              │         │  Managed Identity  │   │
│              │         └──────────┬─────────┘   │
└──────────────┼────────────────────┼─────────────┘
               │                    │
       ┌───────▼────────┐  ┌────────▼──────────┐
       │  Azure AD      │  │  Azure OpenAI     │
       │  (Auth)        │  │  ChatGPT-Safe     │
       └────────────────┘  │  gpt-4.1-mini     │
                           └────────┬──────────┘
                                    │
                           ┌────────▼──────────┐
                           │   Azure SQL DB    │
                           │   school1db       │
                           └───────────────────┘
```

---

## Troubleshooting

### Common Issues

#### 1. Application Not Starting

**Symptoms:** Exit Code 1, no logs

**Check:**
```bash
# View startup logs
az webapp log tail --name School-Safe-GPT-FE-1234 \
  --resource-group school-ai-assistant-production-main
```

**Common Causes:**
- Missing environment variables
- Port configuration mismatch
- Node version incompatibility

**Solution:**
```bash
# Verify config
az webapp config appsettings list --name School-Safe-GPT-FE-1234

# Check Node version
az webapp config show --name School-Safe-GPT-FE-1234 \
  --query linuxFxVersion
```

#### 2. AI Chat Not Working

**Symptoms:** Generic error "I couldn't answer that..."

**Diagnostic:**
```bash
# Send test message
curl -X POST https://school-safe-gpt-fe-1234.azurewebsites.net/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"test","userId":"debug","sessionId":"debug"}'

# Check logs for "FULL ERROR DETAILS"
az webapp log tail --name School-Safe-GPT-FE-1234 | grep "ERROR DETAILS"
```

**Common Causes:**
- Rate limit exceeded (429 error)
- Missing Managed Identity permission
- Wrong AI endpoint/deployment

**Solution:**
```bash
# Check AI permissions
az role assignment list \
  --assignee $(az webapp identity show \
    --name School-Safe-GPT-FE-1234 \
    --query principalId -o tsv)

# Should show "Cognitive Services OpenAI User" on ChatGPT-Safe
```

#### 3. SQL Connection Failed

**Symptoms:** "Client with IP address... is not allowed"

**Solution:**
```bash
# Add firewall rule
az sql server firewall-rule create \
  --server school1sqlsrve2b9 \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

#### 4. Microsoft Login Redirects to Localhost

**Symptoms:** After login, redirected to `localhost:8080`

**Solution:**
1. Check `.env` - ensure no hardcoded `VITE_AZURE_*_URI` values
2. Azure Portal → App Registrations → School-SafeGPT-Latest
3. Add production URL to Redirect URIs
4. Redeploy frontend

---

## Deployment Commands

### Manual Deployment Steps

```bash
# 1. Build frontend
cd app/Frontend
npm install
npm run build

# 2. Package backend
cd ../Backend
zip -r ../../backend-app.zip . -x "node_modules/*"

# 3. Deploy to Azure
az webapp deployment source config-zip \
  --name School-Safe-GPT-FE-1234 \
  --resource-group school-ai-assistant-production-main \
  --src backend-app.zip

# 4. Restart app
az webapp restart --name School-Safe-GPT-FE-1234
```

### Verify Deployment

```bash
# Health check
curl https://school-safe-gpt-fe-1234.azurewebsites.net/health

# Test chat
curl -X POST https://school-safe-gpt-fe-1234.azurewebsites.net/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"What is the capital of France?","userId":"test","sessionId":"test"}'
```

---

## Maintenance

### View Logs
```bash
# Real-time log streaming
az webapp log tail --name School-Safe-GPT-FE-1234

# Download log archive
az webapp log download --name School-Safe-GPT-FE-1234 \
  --log-file logs.zip
```

### Database Queries
```bash
# Check chat count
az sql db query -s school1sqlsrve2b9 -d school1db \
  -Q "SELECT COUNT(*) FROM Chats"

# View recent chats
curl "https://school-safe-gpt-fe-1234.azurewebsites.net/api/chats?userId=<email>"
```

### Update AI Configuration
```bash
# Switch AI resource
az webapp config appsettings set \
  --name School-Safe-GPT-FE-1234 \
  --settings \
    AZURE_OPENAI_ENDPOINT="<new-endpoint>" \
    AZURE_OPENAI_DEPLOYMENT="<new-deployment>"

# Restart to apply
az webapp restart --name School-Safe-GPT-FE-1234
```

---

## Security Best Practices

### 1. Use Managed Identity
✅ Enabled for:
- Azure OpenAI authentication
- Azure SQL authentication (future)

### 2. No Hardcoded Secrets
- Environment variables in Azure App Settings
- Dynamic redirect URI detection
- No API keys in code

### 3. Firewall Rules
- SQL: Azure Services only (0.0.0.0)
- Consider adding specific IP restrictions for production

### 4. Content Filtering
- Azure OpenAI has built-in content filtering
- Flagged requests logged to `FlaggedRequests` table

---

## Performance Optimization

### Current Configuration
- **AI Capacity**: 100 (high throughput)
- **SQL Tier**: Standard
- **App Service**: Basic B1 (consider scaling up for production)

### Scaling Recommendations
```bash
# Scale up App Service
az appservice plan update --name <plan-name> --sku P1V2

# Increase AI capacity
az cognitiveservices account deployment update \
  --name ChatGPT-Safe \
  --deployment-name Test-gpt-4.1-mini \
  --sku-capacity 200
```

---

## Contact & Support

**Deployment Engineer**: Muhammad Umair Ali  
**Deployment Date**: 2026-01-07  
**Documentation Version**: 1.0

For issues or questions, refer to the [walkthrough.md](file:///Users/muhammadumairali/.gemini/antigravity/brain/d85929b8-d639-4d3e-b688-027dbe899c5b/walkthrough.md) for detailed troubleshooting steps.
