# 🚂 Railway Deployment - Quick Guide

Deploy your SchoolSafeAI backend to Railway in under 5 minutes!

## Prerequisites

- ✅ GitHub account
- ✅ Code pushed to GitHub repository
- ✅ Environment variables ready

---

## 🚀 Deploy in 5 Steps

### Step 1: Sign Up & Connect
1. Go to [railway.app](https://railway.app)
2. Click **"Start a New Project"**
3. Sign in with GitHub
4. Authorize Railway

### Step 2: Deploy Repository
1. Click **"Deploy from GitHub repo"**
2. Select `backend-schoolsafeai`
3. Railway auto-detects Dockerfile ✅
4. Deployment starts automatically 🚀

### Step 3: Add Environment Variables
1. Click on your service
2. Go to **"Variables"** tab
3. Click **"RAW Editor"**
4. Paste:

```env
PORT=8080
NODE_ENV=production
AZURE_SQL_USER=your_sql_username
AZURE_SQL_PASS=your_sql_password
AZURE_SQL_SERVER=your_server.database.windows.net
AZURE_SQL_DB=your_database_name
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com
AZURE_OPENAI_DEPLOYMENT=your_deployment_name
AZURE_OPENAI_API_VERSION=2025-01-01-preview
AZURE_OPENAI_API_KEY=your_api_key
```

5. Click **"Update Variables"**

### Step 4: Generate Domain
1. Go to **"Settings"** tab
2. Scroll to **"Networking"**
3. Click **"Generate Domain"**
4. Copy your Railway URL: `https://your-app.railway.app`

### Step 5: Test Your API
```bash
curl https://your-app.railway.app/health
```

Expected response:
```json
{"status":"ok"}
```

**Done! 🎉 Your API is live!**

---

## 📱 Using Railway CLI

### Install
```bash
# macOS
brew install railway

# Windows
iwr https://railway.app/install.ps1 | iex

# Linux
curl -fsSL https://railway.app/install.sh | sh
```

### Deploy
```bash
# Login
railway login

# Initialize (in your project directory)
railway init

# Deploy
railway up

# View logs
railway logs
```

---

## 🔧 Configuration

### Health Check
1. Go to **"Settings"**
2. Set **Health Check Path**: `/health`
3. Set **Port**: `8080`

### Auto-Deploy on Push
Already enabled by default! ✅

Every git push triggers automatic deployment:
```bash
git add .
git commit -m "Update"
git push origin main
# Railway auto-deploys ✨
```

---

## 🌐 Custom Domain (Optional)

### Add Your Domain
1. **Settings** > **"Networking"** > **"Custom Domain"**
2. Enter: `api.yourdomain.com`
3. Add DNS record:
   - **Type**: CNAME
   - **Name**: api
   - **Value**: `your-app.railway.app`
4. Wait 5-60 minutes for DNS propagation
5. SSL auto-configured ✅

---

## 📊 Monitoring

### View Logs
- **Dashboard**: Service > Deployments > View Logs
- **CLI**: `railway logs`

### View Metrics
- Dashboard shows CPU, Memory, Network usage
- **Settings** > **"Metrics"**

---

## 💰 Pricing

### Free Tier (Starter)
- **$5 free credit/month**
- Good for development/testing
- Auto-sleeps after inactivity

### Hobby Plan
- **$5/month**
- 512MB RAM, 1 vCPU
- No sleep
- Custom domains

### Pro Plan
- **Custom pricing**
- More resources
- Priority support

[View full pricing](https://railway.app/pricing)

---

## 🛠️ Common Tasks

### Restart Service
Dashboard: Service > **"⋮"** > **"Restart"**

### View Environment Variables
```bash
railway variables
```

### Add Variable
```bash
railway variables set KEY=value
```

### Open in Browser
```bash
railway open
```

### Link Existing Project
```bash
railway link
```

---

## 🐛 Troubleshooting

### Build Failed
- Check Dockerfile syntax
- View build logs in Railway dashboard
- Ensure `package-lock.json` exists

### App Not Responding
- Check environment variables
- View runtime logs: `railway logs`
- Verify health check endpoint

### Database Connection Error
- Verify Azure SQL firewall allows Railway IPs
- Check credentials in Railway variables
- Test locally first

### 502 Bad Gateway
- Check if app is listening on `PORT` env variable
- Verify port `8080` is exposed in Dockerfile
- Check health check configuration

---

## ✅ Quick Checklist

- [ ] Repository connected to Railway
- [ ] All environment variables added
- [ ] Domain generated
- [ ] Health check responding (200 OK)
- [ ] Auto-deploy enabled
- [ ] Logs show no errors
- [ ] Test API endpoints

---

## 🔗 Useful Links

- **Railway Dashboard**: [railway.app/dashboard](https://railway.app/dashboard)
- **Documentation**: [docs.railway.app](https://docs.railway.app)
- **Discord Support**: [discord.gg/railway](https://discord.gg/railway)
- **Status Page**: [railway.statuspage.io](https://railway.statuspage.io)

---

## 📞 Need Help?

1. Check Railway docs: [docs.railway.app](https://docs.railway.app)
2. Join Discord: [discord.gg/railway](https://discord.gg/railway)
3. View logs: `railway logs`
4. Check status: [railway.statuspage.io](https://railway.statuspage.io)

---

**Your backend is now live on Railway!** 🎉

Next steps:
- Test all API endpoints
- Configure custom domain
- Set up monitoring alerts
- Update frontend to use new URL

