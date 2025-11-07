# 🐳 Docker Quick Start Guide

## ✅ Current Status

Your SchoolSafeAI backend is **successfully dockerized and running**!

- 🟢 Container: `schoolsafeai-backend` 
- 🟢 Status: **Healthy**
- 🌐 URL: http://localhost:8080
- 🏥 Health Check: http://localhost:8080/health

## 📋 Quick Commands

### Start/Stop Container
```bash
# Start the container
docker-compose up -d

# Stop the container
docker-compose down

# Restart the container
docker-compose restart
```

### View Logs
```bash
# Follow logs in real-time
docker-compose logs -f

# View last 50 lines
docker-compose logs --tail=50
```

### Rebuild After Code Changes
```bash
# Rebuild and restart
docker-compose up -d --build

# Or using npm script
npm run docker:rebuild
```

### Check Status
```bash
# Container status
docker-compose ps

# Health check
curl http://localhost:8080/health
```

## 🔧 NPM Scripts Available

```bash
npm run docker:build    # Build the Docker image
npm run docker:up       # Start the container
npm run docker:down     # Stop the container
npm run docker:logs     # View logs
npm run docker:restart  # Restart the container
npm run docker:rebuild  # Rebuild and start
```

## 📁 Docker Files Overview

| File | Purpose |
|------|---------|
| `Dockerfile` | Defines how to build the container image |
| `docker-compose.yml` | Orchestrates the container with environment variables |
| `.dockerignore` | Excludes files from the Docker build context |
| `.env` | Environment variables (not committed to git) |

## 🔐 Environment Variables

Make sure your `.env` file contains:

```bash
# Server
PORT=8080

# Azure SQL
AZURE_SQL_USER=your_username
AZURE_SQL_PASS=your_password
AZURE_SQL_SERVER=your_server.database.windows.net
AZURE_SQL_DB=your_database

# Azure OpenAI
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com
AZURE_OPENAI_DEPLOYMENT=your_deployment
AZURE_OPENAI_API_VERSION=2025-01-01-preview
AZURE_OPENAI_API_KEY=your_api_key
```

## 🧪 Testing

```bash
# Health check
curl http://localhost:8080/health

# Test chat endpoint
curl -X POST http://localhost:8080/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user",
    "sessionId": "test-session",
    "message": "Hello, how are you?"
  }'
```

## 🐛 Troubleshooting

### Container won't start
```bash
# Check logs for errors
docker-compose logs backend

# Check if port 8080 is already in use
lsof -i :8080
```

### Database connection issues
- Verify Azure SQL firewall allows your IP
- Check credentials in `.env` file
- Ensure network connectivity to Azure

### Rebuild from scratch
```bash
# Stop and remove everything
docker-compose down

# Remove old images
docker rmi backend-schoolsafeai-backend

# Rebuild
docker-compose up -d --build
```

## 📚 More Information

- **Quick Railway Deploy**: [RAILWAY_DEPLOY.md](./RAILWAY_DEPLOY.md) - 5 minute deployment
- **VPS/Production Deploy**: [README.DEPLOYMENT.md](./README.DEPLOYMENT.md) - Full deployment guide
- **Docker Reference**: [README.Docker.md](./README.Docker.md) - Docker commands & cloud platforms
- **Backend Architecture**: [docs/BACKEND_OVERVIEW.md](./docs/BACKEND_OVERVIEW.md) - How it works
- **Automated Setup**: Run `./docker-setup.sh` for local setup

## 🚀 Next Steps

1. ✅ Container is running locally
2. 🔜 Test all API endpoints
3. 🔜 Deploy to production:
   - **Railway (Easiest)**: See [RAILWAY_DEPLOY.md](./RAILWAY_DEPLOY.md) - Deploy in 5 minutes!
   - **VPS/Server**: See [README.DEPLOYMENT.md](./README.DEPLOYMENT.md) - Full control
4. 🔜 Set up CI/CD pipeline

---

**Current Container Status:**
```
NAME: schoolsafeai-backend
STATUS: Up and healthy
PORTS: 0.0.0.0:8080->8080/tcp
HEALTH: ✅ Passing
```

