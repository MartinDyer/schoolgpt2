# 🚀 Deployment Guide - VPS & Railway

This guide covers deploying the SchoolSafeAI backend Docker container to:
1. **VPS** (Virtual Private Server) - DigitalOcean, Linode, AWS EC2, Vultr, etc.
2. **Railway** - Modern application deployment platform

---

## 📋 Prerequisites

- Docker image built and tested locally
- Environment variables ready (Azure SQL, Azure OpenAI credentials)
- Domain name (optional but recommended for production)

---

## 🖥️ Option 1: Deploy to VPS (DigitalOcean, Linode, AWS EC2, etc.)

### Step 1: Provision Your VPS

Choose a cloud provider and create a server:

**Recommended Specs:**
- **OS**: Ubuntu 22.04 LTS or Ubuntu 24.04 LTS
- **RAM**: 1GB minimum (2GB recommended)
- **CPU**: 1 vCPU minimum
- **Storage**: 25GB SSD

**Popular VPS Providers:**
- [DigitalOcean](https://www.digitalocean.com/) - $6/month droplets
- [Linode](https://www.linode.com/) - $5/month instances
- [Vultr](https://www.vultr.com/) - $6/month cloud compute
- [AWS EC2](https://aws.amazon.com/ec2/) - t3.micro (free tier eligible)
- [Google Cloud](https://cloud.google.com/) - e2-micro (free tier eligible)

### Step 2: Initial Server Setup

SSH into your server:

```bash
ssh root@your_server_ip
```

Update the system and install essential packages:

```bash
# Update package lists
apt update && apt upgrade -y

# Install essential tools
apt install -y curl git ufw fail2ban

# Set timezone (optional)
timedatectl set-timezone America/New_York
```

### Step 3: Create Non-Root User (Security Best Practice)

```bash
# Create a new user
adduser deploy

# Add user to sudo group
usermod -aG sudo deploy

# Switch to the new user
su - deploy
```

### Step 4: Install Docker & Docker Compose

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group (to run docker without sudo)
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install -y docker-compose

# Verify installations
docker --version
docker-compose --version

# Logout and login again for group changes to take effect
exit
```

SSH back in as the `deploy` user.

### Step 5: Setup Firewall

```bash
# Allow SSH
sudo ufw allow OpenSSH

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow your app port (if accessing directly)
sudo ufw allow 8080/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

### Step 6: Deploy Your Application

#### Method A: Clone Repository and Build on Server

```bash
# Create app directory
mkdir -p ~/apps
cd ~/apps

# Clone your repository
git clone https://github.com/yourusername/backend-schoolsafeai.git
cd backend-schoolsafeai

# Create .env file
nano .env
```

Add your environment variables:

```bash
# Server Configuration
PORT=8080
NODE_ENV=production

# Azure SQL Database
AZURE_SQL_USER=your_sql_username
AZURE_SQL_PASS=your_sql_password
AZURE_SQL_SERVER=your_server.database.windows.net
AZURE_SQL_DB=your_database_name

# Azure OpenAI
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com
AZURE_OPENAI_DEPLOYMENT=your_deployment_name
AZURE_OPENAI_API_VERSION=2025-01-01-preview
AZURE_OPENAI_API_KEY=your_api_key
```

Build and start the container:

```bash
# Build the image
docker-compose build

# Start the container
docker-compose up -d

# Check logs
docker-compose logs -f
```

#### Method B: Pull Pre-built Image from Docker Hub

First, push your image to Docker Hub from your local machine:

```bash
# Tag your image
docker tag backend-schoolsafeai-backend:latest yourusername/schoolsafeai-backend:latest

# Login to Docker Hub
docker login

# Push to Docker Hub
docker push yourusername/schoolsafeai-backend:latest
```

On your VPS:

```bash
# Create app directory
mkdir -p ~/apps/schoolsafeai
cd ~/apps/schoolsafeai

# Create docker-compose.yml
nano docker-compose.yml
```

Add this configuration:

```yaml
services:
  backend:
    image: yourusername/schoolsafeai-backend:latest
    container_name: schoolsafeai-backend
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=production
      - PORT=8080
    env_file:
      - .env
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "node", "-e", "require('http').get('http://localhost:8080/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 10s
```

Create `.env` file and start:

```bash
# Create .env (add your variables)
nano .env

# Pull and start
docker-compose pull
docker-compose up -d
```

### Step 7: Setup Nginx Reverse Proxy (Recommended)

Install Nginx:

```bash
sudo apt install -y nginx
```

Create Nginx configuration:

```bash
sudo nano /etc/nginx/sites-available/schoolsafeai
```

Add this configuration:

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:8080/health;
        access_log off;
    }
}
```

Enable the site:

```bash
# Create symlink
sudo ln -s /etc/nginx/sites-available/schoolsafeai /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

### Step 8: Setup SSL with Let's Encrypt (HTTPS)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Test auto-renewal
sudo certbot renew --dry-run
```

### Step 9: Auto-start on Server Reboot

Docker Compose containers with `restart: unless-stopped` will automatically start on reboot.

Verify:

```bash
# Enable Docker to start on boot
sudo systemctl enable docker

# Check status
sudo systemctl status docker
```

### Step 10: Monitoring & Maintenance

```bash
# View logs
docker-compose logs -f

# Check container status
docker-compose ps

# Restart container
docker-compose restart

# Update application (pull latest code)
cd ~/apps/backend-schoolsafeai
git pull
docker-compose up -d --build

# Update application (from Docker Hub)
docker-compose pull
docker-compose up -d
```

### VPS Deployment Checklist

- ✅ Server provisioned with Ubuntu
- ✅ Non-root user created
- ✅ Docker & Docker Compose installed
- ✅ Firewall configured
- ✅ Application deployed
- ✅ Nginx reverse proxy setup
- ✅ SSL certificate installed
- ✅ Auto-restart configured
- ✅ Logs monitored

---

## 🚂 Option 2: Deploy to Railway

Railway is a modern deployment platform that makes deploying Docker containers simple.

### Step 1: Prepare Your Repository

Ensure your repository has:
- `Dockerfile` ✅
- `.dockerignore` ✅
- `package.json` ✅

Railway will automatically detect and build your Docker container.

### Step 2: Sign Up for Railway

1. Go to [Railway.app](https://railway.app/)
2. Sign up with GitHub (recommended) or email
3. Verify your account

### Step 3: Create a New Project

**Option A: Deploy from GitHub**

1. Click **"New Project"**
2. Select **"Deploy from GitHub repo"**
3. Authorize Railway to access your repositories
4. Select your `backend-schoolsafeai` repository
5. Railway will automatically detect the Dockerfile

**Option B: Deploy from Local CLI**

Install Railway CLI:

```bash
# macOS
brew install railway

# Windows (PowerShell)
iwr https://railway.app/install.ps1 | iex

# Linux
curl -fsSL https://railway.app/install.sh | sh
```

Login and deploy:

```bash
# Login to Railway
railway login

# Initialize project (from your app directory)
cd /path/to/backend-schoolsafeai
railway init

# Deploy
railway up
```

### Step 4: Configure Environment Variables

In the Railway dashboard:

1. Click on your deployed service
2. Go to **"Variables"** tab
3. Click **"+ New Variable"**
4. Add each variable:

```
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

Or use the **"RAW Editor"** and paste all at once:

```bash
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

Click **"Update Variables"** - Railway will automatically redeploy.

### Step 5: Configure Settings

1. Go to **"Settings"** tab
2. Set **Port**: `8080`
3. Set **Health Check Path**: `/health`
4. Set **Deploy on Push**: Enable for auto-deployment
5. Set **Root Directory**: Leave blank (unless app is in subdirectory)

### Step 6: Get Your Railway Domain

Railway automatically provides a domain:

1. Go to **"Settings"** tab
2. Scroll to **"Networking"**
3. Click **"Generate Domain"**
4. You'll get a URL like: `https://your-app.railway.app`

### Step 7: Add Custom Domain (Optional)

1. Go to **"Settings"** > **"Networking"**
2. Click **"Custom Domain"**
3. Enter your domain: `api.yourdomain.com`
4. Add the CNAME record to your DNS:
   - **Type**: CNAME
   - **Name**: api
   - **Value**: `your-app.railway.app`
5. Wait for DNS propagation (usually 5-60 minutes)
6. Railway automatically provisions SSL certificate

### Step 8: View Logs and Monitor

```bash
# Using Railway CLI
railway logs

# Or view in dashboard:
# Click on your service > "Deployments" tab > Select deployment > "View Logs"
```

### Step 9: Scale Your Application (if needed)

Railway automatically scales, but you can configure:

1. Go to **"Settings"** tab
2. Scroll to **"Deploy"**
3. Adjust resources if needed (requires paid plan for custom resources)

### Step 10: Auto-Deployment

Railway automatically redeploys when you push to your repository:

```bash
# Make changes to your code
git add .
git commit -m "Update feature"
git push origin main

# Railway automatically detects and deploys
```

### Railway CLI Commands

```bash
# View status
railway status

# View logs
railway logs

# Open in browser
railway open

# Run commands in Railway environment
railway run node server.js

# Link to existing project
railway link

# Add environment variables
railway variables set KEY=value
```

### Railway Deployment Checklist

- ✅ Railway account created
- ✅ Repository connected
- ✅ Environment variables configured
- ✅ Domain generated
- ✅ Health check configured
- ✅ Auto-deployment enabled
- ✅ SSL certificate active

---

## 🔒 Security Best Practices

### For VPS:

1. **Change SSH port** (optional but recommended):
   ```bash
   sudo nano /etc/ssh/sshd_config
   # Change Port 22 to something else (e.g., 2222)
   sudo systemctl restart sshd
   ```

2. **Disable password authentication** (use SSH keys):
   ```bash
   sudo nano /etc/ssh/sshd_config
   # Set: PasswordAuthentication no
   sudo systemctl restart sshd
   ```

3. **Regular updates**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

4. **Monitor failed login attempts**:
   ```bash
   sudo tail -f /var/log/auth.log
   ```

### For Both VPS & Railway:

1. **Never commit `.env` file** - Already in `.gitignore` ✅
2. **Use strong passwords** for all services
3. **Enable 2FA** on cloud provider accounts
4. **Regular backups** of your database
5. **Monitor application logs** regularly
6. **Keep Docker images updated**:
   ```bash
   docker-compose pull
   docker-compose up -d
   ```

---

## 📊 Monitoring & Logging

### VPS Monitoring:

```bash
# View real-time logs
docker-compose logs -f

# View specific number of lines
docker-compose logs --tail=100

# View container stats
docker stats

# Check disk space
df -h

# Check memory usage
free -h

# Monitor system resources
htop  # (install with: sudo apt install htop)
```

### Railway Monitoring:

- Built-in metrics dashboard
- Real-time logs in web interface
- Email notifications for deployment failures

---

## 🔄 Updating Your Application

### VPS Update Process:

```bash
# Navigate to app directory
cd ~/apps/backend-schoolsafeai

# Pull latest code
git pull origin main

# Rebuild and restart
docker-compose up -d --build

# Verify health
curl http://localhost:8080/health
```

### Railway Update Process:

Railway auto-deploys on git push:

```bash
# Make changes locally
git add .
git commit -m "Your update message"
git push origin main

# Railway automatically deploys
# Monitor in Railway dashboard
```

---

## 🐛 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs

# Check if port is in use
sudo lsof -i :8080

# Restart Docker
sudo systemctl restart docker
```

### Database Connection Issues

1. **Check firewall rules** on Azure SQL
2. **Verify credentials** in `.env`
3. **Test connection** from VPS:
   ```bash
   # Install telnet
   sudo apt install telnet
   
   # Test connection
   telnet your_server.database.windows.net 1433
   ```

### Railway-Specific Issues

1. **Build fails**: Check Dockerfile syntax
2. **Environment variables not loading**: Ensure they're saved in Railway dashboard
3. **Health check fails**: Verify `/health` endpoint returns 200 status

### Out of Memory

```bash
# Check memory usage
docker stats

# Increase VPS memory or upgrade plan
# For Railway, upgrade to a higher tier
```

---

## 💰 Cost Estimates

### VPS Costs:
- **DigitalOcean**: $6-12/month
- **Linode**: $5-10/month  
- **Vultr**: $6-12/month
- **AWS EC2**: $8-15/month (after free tier)

### Railway Costs:
- **Hobby Plan**: $5/month for 512MB RAM, 1 vCPU
- **Developer Plan**: Free tier available ($5 credit/month)
- **Pro Plan**: Custom pricing for higher resources

---

## 📞 Support & Resources

### Documentation:
- [Docker Documentation](https://docs.docker.com/)
- [Railway Documentation](https://docs.railway.app/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt](https://letsencrypt.org/docs/)

### Community:
- Railway Discord: [discord.gg/railway](https://discord.gg/railway)
- Docker Community: [forums.docker.com](https://forums.docker.com/)

---

## ✅ Post-Deployment Checklist

- [ ] Application accessible via public URL
- [ ] HTTPS/SSL certificate active (for production)
- [ ] Environment variables configured
- [ ] Database connection verified
- [ ] Health check endpoint responding
- [ ] Logs being generated and accessible
- [ ] Auto-restart on failure enabled
- [ ] Monitoring setup
- [ ] Backup strategy in place
- [ ] Domain name configured (if applicable)

---

**Congratulations!** 🎉 Your SchoolSafeAI backend is now deployed and accessible to the world!

