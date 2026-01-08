# Multi-School Deployment Architecture

Each school deploys their own complete infrastructure including a dedicated AI Foundry resource.

## Architecture Overview

```
┌─────────────────────────────────────────────┐
│ School A                                     │
│ ┌─────────────┐  ┌──────────────────────┐  │
│ │  Web App    │──│ AI Foundry (own)     │  │
│ │  SQL DB     │  │ 100k tokens          │  │
│ └─────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ School B                                     │
│ ┌─────────────┐  ┌──────────────────────┐  │
│ │  Web App    │──│ AI Foundry (own)     │  │
│ │  SQL DB     │  │ 100k tokens          │  │
│ └─────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ School C                                     │
│ ┌─────────────┐  ┌──────────────────────┐  │
│ │  Web App    │──│ AI Foundry (own)     │  │
│ │  SQL DB     │  │ 100k tokens          │  │
│ └─────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────┘
```

## Benefits

### 1. Complete Isolation
- ✅ Each school has dedicated resources
- ✅ No performance impact from other schools
- ✅ Independent scaling

### 2. Clear Cost Attribution
- ✅ Each school pays for their own usage
- ✅ Easy billing and invoicing
- ✅ Transparent cost tracking

### 3. Independent Management
- ✅ Schools can request their own quota increases
- ✅ Configure content filtering per school
- ✅ Control their own AI models

### 4. Better Security
- ✅ No cross-school access risks
- ✅ Managed Identity per school
- ✅ Separate resource groups

---

## Deployment Process

### Phase 1: School Creates AI Foundry
**Who**: School IT team or admin  
**Where**: Azure Portal  
**Time**: ~15 minutes  
**Guide**: [AI_FOUNDRY_DEPLOYMENT_GUIDE.md](./AI_FOUNDRY_DEPLOYMENT_GUIDE.md)

**Outputs**: 
- AI Foundry endpoint URL
- Deployment name
- Resource group name

### Phase 2: Deploy School Infrastructure
**Who**: Development team  
**Where**: GitHub Actions workflow  
**Time**: ~10 minutes  

**Required inputs from school**:
```bash
SCHOOL_NAME="Lincoln High School"
AZURE_OPENAI_ENDPOINT="https://lincoln-high-ai.openai.azure.com/"
AZURE_OPENAI_DEPLOYMENT="gpt-4o"
AZURE_AD_TENANT_ID="school's-tenant-id"
```

**What gets deployed**:
- Web App (app + database)
- SQL Server + Database
- Key Vault
- Application Insights
- Service Plan

### Phase 3: Grant AI Access
**Who**: School IT team  
**Where**: Azure Portal  
**Time**: ~2 minutes  

**Steps**:
1. Get Web App's Managed Identity principal ID
2. Grant "Cognitive Services OpenAI User" role
3. Test AI chat functionality

---

## Cost Structure

### Per School Monthly Costs

| Component | Monthly Cost | Notes |
|-----------|--------------|-------|
| Web App (B2) | $55 | Can scale based on usage |
| SQL Database (S1) | $15 | Can scale based on data |
| AI Foundry (gpt-4o) | $50-150 | Usage-based, varies by activity |
| AI Foundry (gpt-4o-mini) | $10-30 | Lower cost alternative |
| Key Vault | $0.03 | Minimal |
| **Total (gpt-4o)** | **$120-220/month** |  |
| **Total (gpt-4o-mini)** | **$80-100/month** |  |

**Recommendation**: Start with gpt-4o-mini to minimize costs

---

## Deployment Checklist

### School Pre-Deployment
- [ ] Azure subscription created
- [ ] AI Foundry deployed (following guide)
- [ ] Configuration values collected
- [ ] Admin email for notifications

### Development Team Deployment
- [ ] Received school configuration
- [ ] Updated Terraform variables
- [ ] Ran deployment workflow
- [ ] Verified health endpoint

### School Post-Deployment
- [ ] Granted Managed Identity access
- [ ] Configured Microsoft/Azure AD login
- [ ] Tested AI chat functionality
- [ ] Set up cost alerts

---

## Terraform Configuration

### Required Variables (per school)

```hcl
# terraform.tfvars
school_name = "lincoln-high-school"
environment = "production"

# Provided by school after AI Foundry deployment
azure_openai_endpoint = "https://lincoln-high-ai.openai.azure.com/"
azure_openai_deployment = "gpt-4o"
azure_openai_resource_group = "rg-lincoln-high-ai-foundry"

# School's Azure AD
azure_tenant_id = "school-tenant-id"
azure_client_id = "school-app-registration-id"
```

### Deploy Command

```bash
cd infra
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars -auto-approve
```

---

## Scaling Considerations

### Small School (< 100 students)
- Web App: B1 ($13/month)
- SQL: S0 ($5/month)  
- AI: gpt-4o-mini
- **Total: ~$30-50/month**

### Medium School (100-500 students)
- Web App: B2 ($55/month)
- SQL: S1 ($15/month)
- AI: gpt-4o-mini or gpt-4o
- **Total: ~$80-150/month**

### Large School (500+ students)
- Web App: S1 ($70/month) or higher
- SQL: S2 ($30/month)
- AI: gpt-4o with increased quota
- **Total: ~$150-300/month**

---

## Support Model

### School Support
- Azure Portal access and training
- AI Foundry deployment guide
- Cost monitoring setup
- Azure AD configuration help

### Development Team Support
- Infrastructure deployment
- Technical troubleshooting
- Code updates and features
- Monitoring and alerts

---

## FAQ

**Q: Can multiple schools share one AI Foundry?**  
A: Technically yes, but not recommended. Each school gets better isolation, clearer costs, and independent quota with their own resource.

**Q: What if a school wants to switch AI models?**  
A: Easy! Just deploy a new model in their AI Foundry and update the configuration. No code changes needed.

**Q: How do we handle school mergers?**  
A: Keep separate infrastructures initially, then migrate data and consolidate resources if needed.

**Q: Can schools use their existing Azure subscription?**  
A: Yes! Just deploy the AI Foundry in their subscription and provide the configuration values.

---

## Next Steps

1. **Review**: [AI_FOUNDRY_DEPLOYMENT_GUIDE.md](./AI_FOUNDRY_DEPLOYMENT_GUIDE.md)
2. **Send to schools**: Have them deploy AI Foundry first
3. **Collect config**: Get endpoint, deployment name, etc.
4. **Deploy**: Run GitHub Actions workflow with school's values
5. **Grant access**: School grants Managed Identity permission
6. **Test**: Verify everything works
7. **Launch**: School starts using the AI chatbot 🚀
