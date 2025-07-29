# 🛡️ Azure AI Foundry Content Filter Management Guide

## Overview

Azure AI Foundry provides **comprehensive content filtering capabilities** that you can control from the Azure Portal. This guide shows you how to manage every aspect of content filtering for your school-safe AI application.

## 📊 Content Filter Categories

### 1. **Hate Speech Filter**
- **Low**: Catches obvious hate speech
- **Medium**: Catches subtle hate speech  
- **High**: Catches all forms of hate speech (recommended for schools)

### 2. **Sexual Content Filter**
- **Low**: Catches explicit sexual content only
- **Medium**: Catches suggestive content
- **High**: Catches all sexual references (recommended for schools)

### 3. **Violence Filter**
- **Low**: Catches graphic violence only
- **Medium**: Catches threats and weapons
- **High**: Catches all violence references (recommended for schools)

### 4. **Self-Harm Filter**
- **Low**: Catches explicit self-harm content
- **Medium**: Catches mental health concerns
- **High**: Catches all self-harm references (recommended for schools)

## 🔧 Azure Portal Management

### **Access Content Filters**

1. **Go to Azure Portal**
2. **Navigate to your AI Foundry resource**
3. **Click "Content Filters" in the left menu**
4. **View and modify filter settings**

### **Real-time Monitoring**

- **Filter Violation Dashboard**: See blocked content in real-time
- **Usage Analytics**: Monitor filter effectiveness
- **Alert Configuration**: Get notified of violations
- **Audit Logs**: Track all filter activities

## 🎛️ Configuration Options

### **Via Azure Portal**

```bash
# Adjust filter sensitivity
az cognitiveservices account update \
  --name your-ai-foundry \
  --resource-group your-rg \
  --content-filter-hate High \
  --content-filter-sexual High \
  --content-filter-violence High \
  --content-filter-self-harm High
```

### **Via Terraform Variables**

```hcl
# In terraform.tfvars
content_filter_hate_severity     = "High"
content_filter_sexual_severity   = "High"  
content_filter_violence_severity = "High"
content_filter_self_harm_severity = "High"
```

### **Via Environment Variables**

```bash
# In your app settings
AZURE_OPENAI_CONTENT_FILTER_HATE     = "2"  # High filtering
AZURE_OPENAI_CONTENT_FILTER_SEXUAL   = "2"  # High filtering  
AZURE_OPENAI_CONTENT_FILTER_VIOLENCE = "2"  # High filtering
AZURE_OPENAI_CONTENT_FILTER_SELF_HARM = "2"  # High filtering
```

## 🎯 Custom Content Filters

### **School-Specific Vocabulary**

Your setup includes custom patterns for school safety:

```hcl
custom_filter_patterns = [
  "bully*",      # Bullying content
  "cheat*",      # Academic dishonesty
  "skip* class", # Truancy
  "truant*",     # Truancy
  "vandal*",     # Property damage
  "fight*",      # Physical violence
  "weapon*"      # Weapons
]
```

### **Adding Custom Patterns**

1. **Via Terraform**:
   ```hcl
   custom_filter_patterns = [
     "your-custom-pattern*",
     "another-pattern*"
   ]
   ```

2. **Via Azure Portal**:
   - Go to Content Filters
   - Click "Add Custom Filter"
   - Enter pattern and severity

## 📈 Monitoring & Analytics

### **Filter Violation Reports**

- **Real-time alerts** via email
- **Daily/weekly summaries** of violations
- **Trend analysis** of filter effectiveness
- **User-specific reports** for administrators

### **Usage Analytics**

- **Filter hit rates** by category
- **Most common violations**
- **Effectiveness metrics**
- **Cost impact analysis**

## 🔒 Security Features

### **Compliance Reporting**

- **FERPA compliance** for student data
- **COPPA compliance** for children under 13
- **Audit trail** for all filter activities
- **Data retention** policies

### **Access Control**

- **Role-based access** to filter settings
- **Admin-only** filter modifications
- **Approval workflows** for changes
- **Change tracking** and history

## 🚀 Best Practices

### **For Schools**

1. **Start with High filtering** for all categories
2. **Monitor violations** regularly
3. **Adjust gradually** based on usage patterns
4. **Train staff** on filter management
5. **Document policies** for compliance

### **For Administrators**

1. **Review violation reports** weekly
2. **Adjust filters** based on false positives
3. **Communicate changes** to teachers
4. **Monitor student feedback**
5. **Update custom patterns** as needed

## 🔧 Troubleshooting

### **Common Issues**

**Too Many False Positives:**
- Reduce filter severity from High to Medium
- Add exceptions to custom patterns
- Review violation logs for patterns

**Not Catching Enough:**
- Increase filter severity
- Add more custom patterns
- Review content that should be blocked

**Performance Issues:**
- Monitor API response times
- Check filter processing overhead
- Optimize custom pattern complexity

### **Support Resources**

- **Azure AI Foundry Documentation**
- **Content Filter API Reference**
- **School Safety Guidelines**
- **Microsoft Support**

## 📞 Getting Help

### **Azure Support**
- **Technical issues**: Azure Support
- **Billing questions**: Azure Billing Support
- **Security concerns**: Azure Security Center

### **School Resources**
- **IT Administrator**: Your school's IT team
- **Microsoft Education**: Education-specific support
- **Community Forums**: Azure AI community

---

## 🎯 Summary

With Azure AI Foundry, you have **complete control** over content filtering:

✅ **Real-time monitoring** of all content  
✅ **Granular control** over filter sensitivity  
✅ **Custom patterns** for school-specific needs  
✅ **Comprehensive reporting** and analytics  
✅ **Compliance features** for educational use  
✅ **Easy management** via Azure Portal  

Your school-safe AI application is now fully protected with enterprise-grade content filtering! 