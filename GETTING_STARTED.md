# 🚀 Getting Started with SchoolGPT

## For School IT Administrators

Welcome! This template helps you deploy a **secure, school-safe AI assistant** for your educational institution in just **15 minutes**.

### Option 1: Quick Setup (Recommended) 🏃‍♂️

Run our automated setup script:

```bash
./setup.sh
```

The script will:
- ✅ Check your Azure setup
- 📝 Gather your school's information
- 🔧 Create configuration files
- 🚀 Optionally deploy immediately

### Option 2: Manual Setup 🛠️

1. **Configure your school settings:**
   ```bash
   cp infra/terraform.tfvars.template infra/terraform.tfvars
   # Edit terraform.tfvars with your school's details
   ```

2. **Deploy to Azure:**
   ```bash
   cd infra
   terraform init
   terraform apply
   ```

3. **Set up GitHub Actions for app deployment**

## What You Get

✅ **Complete AI Assistant** for your school  
✅ **High content filtering** for student safety  
✅ **Secure authentication** via school accounts  
✅ **Full audit logging** for compliance  
✅ **Real-time monitoring** and alerts  
✅ **Easy customization** for your school brand  

## Next Steps

1. **📖 Read [README.md](README.md)** - Complete overview
2. **📚 See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Detailed instructions
3. **🏫 Customize for your school** - Branding and settings

## Need Help?

- 🐛 **Report Issues**: GitHub Issues
- 💬 **Ask Questions**: GitHub Discussions  
- 📧 **Enterprise Support**: Contact us

**Ready to give your school AI superpowers?** Let's go! 🎓 