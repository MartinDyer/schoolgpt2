# 🚀 Quick Deployment Guide

Choose your deployment method:

## 1️⃣ Railway (Easiest - 5 minutes)

```bash
# Install Railway CLI
npm i -g @railway/cli

# Login and deploy
railway login
railway init
railway up

# Open in browser
railway open
```

✅ **Automatic SSL, domain, and deployment!**

---

## 2️⃣ VPS Deployment (DigitalOcean, AWS, Linode, etc.)

### Step 1: Prepare VPS

```bash
# SSH into your server
ssh root@your-server-ip

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
apt install docker-compose -y
```

### Step 2: Deploy Application

**Option A: From GitHub**
```bash
# Clone repository
cd /opt
git clone https://github.com/yourusername/schoolsafeai.git
cd schoolsafeai

# Update port to 80 in docker-compose.yml
# Change: "3001:80" to "80:80"

# Build and run
docker-compose up -d --build

# View logs
docker-compose logs -f
```

**Option B: From Docker Hub**
```bash
# On your local machine - push to Docker Hub
docker login
docker build -t yourusername/schoolsafeai-frontend:latest .
docker push yourusername/schoolsafeai-frontend:latest

# On VPS - pull and run
docker pull yourusername/schoolsafeai-frontend:latest
docker run -d -p 80:80 --restart unless-stopped yourusername/schoolsafeai-frontend:latest
```

### Step 3: Setup SSL (Optional but Recommended)

**Using Nginx Proxy Manager (Easiest):**
```bash
cd /opt
mkdir nginx-proxy-manager && cd nginx-proxy-manager

# Create docker-compose.yml
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

Then:
1. Go to `http://your-server-ip:81`
2. Login: `admin@example.com` / `changeme`
3. Add your domain and request SSL certificate
4. Point to your app container

---

## 3️⃣ Local Docker Testing

```bash
# Start
npm run docker:up

# Stop
npm run docker:down

# View logs
npm run docker:logs

# Rebuild
npm run docker:rebuild
```

Access at: `http://localhost:3001`

---

## Environment Variables

Create `.env.production` before building:

```env
VITE_API_URL=https://api.yourdomain.com
VITE_APP_NAME=SchoolSafeAI
VITE_AZURE_CLIENT_ID=your-client-id
```

**Note:** Vite variables are baked into build, so rebuild after changes!

---

## Firewall Setup (VPS)

```bash
# Enable firewall
ufw enable

# Allow necessary ports
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS

# Check status
ufw status
```

---

## Troubleshooting

### Port already in use
```bash
# Find what's using the port
lsof -i :80

# Kill the process
kill -9 PID

# Or change port in docker-compose.yml
```

### Check logs
```bash
docker logs schoolsafeai-frontend
docker-compose logs -f
```

### Container won't start
```bash
# Rebuild from scratch
docker-compose down
docker system prune -a -f
docker-compose up -d --build
```

### Out of disk space
```bash
# Clean Docker
docker system prune -a -f
docker volume prune -f

# Check space
df -h
```

---

## Update Deployment

**Railway:** Just push to GitHub - auto-deploys ✅

**VPS:**
```bash
cd /opt/schoolsafeai
git pull origin main
docker-compose down
docker-compose up -d --build
docker system prune -f
```

---

## Cost Comparison

| Platform | Monthly Cost | SSL | Setup Time |
|----------|-------------|-----|------------|
| Railway | $5 | ✅ Free | 5 min |
| DigitalOcean | $4-6 | Manual | 15 min |
| AWS EC2 | $3-10 | Manual | 20 min |
| Linode | $5 | Manual | 15 min |
| Vultr | $2.50-6 | Manual | 15 min |

---

## Need More Details?

📖 **[Full Deployment Guide](./DEPLOYMENT.md)** - Complete step-by-step instructions

📖 **[Docker Documentation](./DOCKER.md)** - Docker configuration details

---

## Quick Health Check

```bash
# Check if running
curl http://localhost

# Check container status
docker ps | grep schoolsafeai

# Check health
docker inspect --format='{{.State.Health.Status}}' schoolsafeai-frontend
```

---

**🎉 You're ready to deploy!**

Choose Railway for fastest deployment, or VPS for more control.

