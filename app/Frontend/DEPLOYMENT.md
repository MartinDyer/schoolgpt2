# Deployment Guide - SchoolSafeAI Frontend

This guide covers deploying your Dockerized frontend application to various platforms including VPS servers and Railway.

## Table of Contents
- [Deploying to Railway](#deploying-to-railway)
- [Deploying to VPS (DigitalOcean, AWS, Linode, etc.)](#deploying-to-vps)
- [Deploying to Docker Hub](#deploying-to-docker-hub)
- [SSL/HTTPS Setup](#sslhttps-setup)
- [Environment Variables](#environment-variables)
- [Troubleshooting](#troubleshooting)

---

## Deploying to Railway

Railway is the easiest option for deploying Docker containers with automatic SSL and custom domains.

### Method 1: Deploy from GitHub (Recommended)

1. **Push your code to GitHub:**
   ```bash
   git add .
   git commit -m "Add Docker configuration"
   git push origin main
   ```

2. **Create Railway Account:**
   - Go to [Railway.app](https://railway.app)
   - Sign up with GitHub

3. **Deploy:**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your `schoolsafeai` repository
   - Railway will auto-detect the Dockerfile and deploy

4. **Configure Port:**
   - Railway will automatically detect port 80 from your Dockerfile
   - If needed, go to Settings → Variables → Add `PORT=80`

5. **Add Custom Domain (Optional):**
   - Go to Settings → Domains
   - Click "Generate Domain" for a free `.railway.app` domain
   - Or add your custom domain

6. **Deploy Updates:**
   - Push to GitHub and Railway auto-deploys
   - Or manually redeploy from Railway dashboard

### Method 2: Deploy with Railway CLI

1. **Install Railway CLI:**
   ```bash
   # macOS
   brew install railway
   
   # npm
   npm i -g @railway/cli
   ```

2. **Login and Initialize:**
   ```bash
   railway login
   cd /Users/mac/Desktop/Axtra\ Studios/schoolsafeai
   railway init
   ```

3. **Deploy:**
   ```bash
   railway up
   ```

4. **Open in Browser:**
   ```bash
   railway open
   ```

### Railway Configuration File (Optional)

Create `railway.toml` in your project root:

```toml
[build]
builder = "dockerfile"
dockerfilePath = "Dockerfile"

[deploy]
startCommand = ""
healthcheckPath = "/"
healthcheckTimeout = 100
restartPolicyType = "on_failure"
restartPolicyMaxRetries = 10
```

---

## Deploying to VPS

Deploy to any VPS provider like DigitalOcean, AWS EC2, Linode, Vultr, etc.

### Prerequisites

- VPS with Ubuntu 22.04 or later (recommended)
- SSH access to your server
- Domain name (optional, for SSL)

### Step 1: Initial Server Setup

1. **SSH into your VPS:**
   ```bash
   ssh root@your-server-ip
   ```

2. **Update system:**
   ```bash
   apt update && apt upgrade -y
   ```

3. **Install Docker:**
   ```bash
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   
   # Install Docker Compose
   apt install docker-compose -y
   
   # Verify installation
   docker --version
   docker-compose --version
   ```

### Step 2: Deploy Your Application

**Option A: Deploy from Docker Hub**

1. **Push to Docker Hub (from your local machine):**
   ```bash
   # Build and tag
   docker build -t yourusername/schoolsafeai-frontend:latest .
   
   # Login to Docker Hub
   docker login
   
   # Push
   docker push yourusername/schoolsafeai-frontend:latest
   ```

2. **Pull and run on VPS:**
   ```bash
   # On your VPS
   docker pull yourusername/schoolsafeai-frontend:latest
   docker run -d -p 80:80 --name schoolsafeai --restart unless-stopped yourusername/schoolsafeai-frontend:latest
   ```

**Option B: Deploy from GitHub**

1. **Clone repository on VPS:**
   ```bash
   # Install git if not present
   apt install git -y
   
   # Clone your repo
   cd /opt
   git clone https://github.com/yourusername/schoolsafeai.git
   cd schoolsafeai
   ```

2. **Update docker-compose.yml to use port 80:**
   ```yaml
   services:
     frontend:
       build:
         context: .
         dockerfile: Dockerfile
       container_name: schoolsafeai-frontend
       ports:
         - "80:80"
       restart: unless-stopped
       environment:
         - NODE_ENV=production
       networks:
         - schoolsafeai-network

   networks:
     schoolsafeai-network:
       driver: bridge
   ```

3. **Build and run:**
   ```bash
   docker-compose up -d --build
   ```

4. **Verify it's running:**
   ```bash
   docker-compose ps
   docker-compose logs -f
   ```

5. **Access your app:**
   - Open browser: `http://your-server-ip`

### Step 3: Setup Auto-Deploy (Optional)

Create a deployment script on VPS:

```bash
# Create deployment script
cat > /opt/deploy.sh << 'EOF'
#!/bin/bash
cd /opt/schoolsafeai
git pull origin main
docker-compose down
docker-compose up -d --build
docker system prune -f
EOF

chmod +x /opt/deploy.sh
```

Run manually or setup GitHub webhook for auto-deployment.

---

## SSL/HTTPS Setup

### For Railway
✅ **Automatic!** Railway provides free SSL certificates automatically.

### For VPS - Using Nginx Proxy Manager (Easiest)

1. **Install Nginx Proxy Manager:**
   ```bash
   cd /opt
   mkdir nginx-proxy-manager && cd nginx-proxy-manager
   
   cat > docker-compose.yml << 'EOF'
   version: '3.8'
   services:
     app:
       image: 'jc21/nginx-proxy-manager:latest'
       restart: unless-stopped
       ports:
         - '80:80'
         - '81:81'
         - '443:443'
       volumes:
         - ./data:/data
         - ./letsencrypt:/etc/letsencrypt
   EOF
   
   docker-compose up -d
   ```

2. **Access Nginx Proxy Manager:**
   - Open `http://your-server-ip:81`
   - Default credentials: `admin@example.com` / `changeme`
   - Change password immediately

3. **Update your app to run on different port:**
   ```bash
   cd /opt/schoolsafeai
   # Edit docker-compose.yml to use port 3001:80 instead of 80:80
   docker-compose down
   docker-compose up -d
   ```

4. **Add Proxy Host in Nginx Proxy Manager:**
   - Domain: `yourdomain.com`
   - Forward to: `schoolsafeai-frontend` (or your server IP)
   - Port: `3001`
   - Enable SSL → Request Let's Encrypt Certificate

### For VPS - Using Certbot (Manual)

1. **Install Certbot:**
   ```bash
   apt install certbot python3-certbot-nginx -y
   ```

2. **Update your app to run on port 3001:**
   ```bash
   cd /opt/schoolsafeai
   # Edit docker-compose.yml port mapping to 3001:80
   docker-compose down
   docker-compose up -d
   ```

3. **Install and configure Nginx:**
   ```bash
   apt install nginx -y
   
   cat > /etc/nginx/sites-available/schoolsafeai << 'EOF'
   server {
       listen 80;
       server_name yourdomain.com www.yourdomain.com;

       location / {
           proxy_pass http://localhost:3001;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   EOF
   
   ln -s /etc/nginx/sites-available/schoolsafeai /etc/nginx/sites-enabled/
   nginx -t
   systemctl restart nginx
   ```

4. **Get SSL Certificate:**
   ```bash
   certbot --nginx -d yourdomain.com -d www.yourdomain.com
   ```

5. **Auto-renewal is setup automatically!**

---

## Deploying to Docker Hub

Push your image to Docker Hub for easy deployment anywhere.

1. **Login to Docker Hub:**
   ```bash
   docker login
   ```

2. **Build and tag:**
   ```bash
   docker build -t yourusername/schoolsafeai-frontend:latest .
   docker tag yourusername/schoolsafeai-frontend:latest yourusername/schoolsafeai-frontend:v1.0.0
   ```

3. **Push:**
   ```bash
   docker push yourusername/schoolsafeai-frontend:latest
   docker push yourusername/schoolsafeai-frontend:v1.0.0
   ```

4. **Deploy anywhere:**
   ```bash
   docker run -d -p 80:80 --name schoolsafeai --restart unless-stopped yourusername/schoolsafeai-frontend:latest
   ```

---

## Environment Variables

### Build-time Variables (Vite)

Vite environment variables (prefixed with `VITE_`) must be set at **build time**.

1. **Create `.env.production`:**
   ```env
   VITE_API_URL=https://api.yourdomain.com
   VITE_APP_NAME=SchoolSafeAI
   VITE_AZURE_CLIENT_ID=your-client-id
   ```

2. **Build with variables:**
   ```bash
   docker build \
     --build-arg VITE_API_URL=https://api.yourdomain.com \
     --build-arg VITE_APP_NAME=SchoolSafeAI \
     -t schoolsafeai-frontend .
   ```

### Railway Environment Variables

1. Go to your Railway project
2. Click on your service
3. Go to "Variables" tab
4. Add variables:
   - Note: These won't work for Vite variables (need to rebuild)
   - For runtime config, implement a different strategy

### VPS Environment Variables

Add to `docker-compose.yml`:

```yaml
services:
  frontend:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        - VITE_API_URL=${VITE_API_URL}
        - VITE_APP_NAME=${VITE_APP_NAME}
    environment:
      - NODE_ENV=production
```

Then create `.env` file in the same directory:
```env
VITE_API_URL=https://api.yourdomain.com
VITE_APP_NAME=SchoolSafeAI
```

---

## Monitoring & Maintenance

### Check Container Status

```bash
# Docker Compose
docker-compose ps
docker-compose logs -f

# Docker
docker ps
docker logs -f schoolsafeai-frontend
```

### Update Application

**Railway:** Push to GitHub - auto-deploys

**VPS:**
```bash
cd /opt/schoolsafeai
git pull origin main
docker-compose down
docker-compose up -d --build
```

### Cleanup Old Images

```bash
docker system prune -a -f
```

### View Resource Usage

```bash
docker stats schoolsafeai-frontend
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs schoolsafeai-frontend

# Check if port is in use
lsof -i :80
# or
netstat -tulpn | grep :80

# Restart container
docker restart schoolsafeai-frontend
```

### Port Already in Use

```bash
# Find what's using the port
lsof -i :80

# Kill the process (replace PID)
kill -9 PID

# Or change your app's port in docker-compose.yml
```

### SSL Certificate Issues

```bash
# Renew certificate manually
certbot renew

# Test renewal
certbot renew --dry-run
```

### Out of Disk Space

```bash
# Check disk usage
df -h

# Clean Docker
docker system prune -a -f
docker volume prune -f
```

### Application Not Accessible

1. **Check firewall:**
   ```bash
   # Ubuntu/Debian
   ufw status
   ufw allow 80/tcp
   ufw allow 443/tcp
   ```

2. **Check cloud provider security groups:**
   - AWS: Security Groups (allow ports 80, 443)
   - DigitalOcean: Firewalls
   - Azure: Network Security Groups

3. **Check if container is running:**
   ```bash
   docker ps
   ```

### DNS Not Resolving

1. Wait 24-48 hours for DNS propagation
2. Check DNS settings:
   ```bash
   nslookup yourdomain.com
   dig yourdomain.com
   ```
3. Ensure A record points to your VPS IP

---

## Performance Optimization

### Enable Caching

Already configured in `nginx.conf`!

### CDN Setup

Use Cloudflare (free):
1. Add your domain to Cloudflare
2. Update nameservers
3. Enable "Proxied" on DNS records
4. Free SSL, CDN, and DDoS protection!

### Monitoring

**Railway:** Built-in metrics in dashboard

**VPS - Install monitoring:**
```bash
# Install htop
apt install htop -y

# Or use ctop for Docker containers
docker run --rm -ti \
  --name=ctop \
  --volume /var/run/docker.sock:/var/run/docker.sock:ro \
  quay.io/vektorlab/ctop:latest
```

---

## Cost Comparison

| Platform | Cost | Pros | Cons |
|----------|------|------|------|
| **Railway** | $5/month | Easy, Auto SSL, Auto-deploy | Limited free tier |
| **DigitalOcean** | $4-6/month | Full control, Predictable pricing | Manual setup |
| **AWS EC2** | $3-10/month | Scalable, Many services | Complex, Variable pricing |
| **Linode** | $5/month | Simple, Good docs | - |
| **Vultr** | $2.50-6/month | Cheap, Fast | - |

---

## Security Best Practices

1. **Never commit secrets:**
   ```bash
   # Add to .gitignore
   .env
   .env.local
   .env.production.local
   ```

2. **Use environment variables for sensitive data**

3. **Keep Docker images updated:**
   ```bash
   docker-compose pull
   docker-compose up -d
   ```

4. **Enable firewall on VPS:**
   ```bash
   ufw enable
   ufw allow 22/tcp  # SSH
   ufw allow 80/tcp  # HTTP
   ufw allow 443/tcp # HTTPS
   ```

5. **Regular backups:**
   ```bash
   # Backup script
   docker exec schoolsafeai-frontend tar czf /backup.tar.gz /usr/share/nginx/html
   ```

---

## Need Help?

- **Railway Docs:** https://docs.railway.app
- **Docker Docs:** https://docs.docker.com
- **DigitalOcean Tutorials:** https://www.digitalocean.com/community/tutorials
- **Let's Encrypt:** https://letsencrypt.org/docs/

---

## Quick Reference Commands

```bash
# Start application
npm run docker:up

# Stop application
npm run docker:down

# View logs
npm run docker:logs

# Rebuild and restart
npm run docker:rebuild

# On VPS - Deploy/Update
cd /opt/schoolsafeai && git pull && docker-compose up -d --build

# Check health
curl http://localhost
```

---

**You're all set! 🚀**

Choose Railway for the easiest deployment, or VPS for more control and potentially lower costs.

