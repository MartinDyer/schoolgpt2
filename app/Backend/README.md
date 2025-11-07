# SchoolSafeAI Backend 🎓

A safe, AI-powered educational chatbot backend built with Node.js, Express, Azure OpenAI, and Azure SQL Database.

## 🚀 Quick Start

### Local Development

```bash
# Install dependencies
npm install

# Create .env file
cp env.template .env
# Edit .env with your Azure credentials

# Start the server
npm start
```

Server runs at `http://localhost:8080`

### Docker (Recommended)

```bash
# Quick setup with Docker
./docker-setup.sh

# Or manually
docker-compose up -d

# View logs
docker-compose logs -f
```

**📖 See [DOCKER_QUICK_START.md](./DOCKER_QUICK_START.md) for detailed Docker instructions**

## 📚 Documentation

| Guide | Description |
|-------|-------------|
| [🚂 RAILWAY_DEPLOY.md](./RAILWAY_DEPLOY.md) | **Deploy to Railway in 5 minutes** (Easiest!) |
| [🖥️ README.DEPLOYMENT.md](./README.DEPLOYMENT.md) | Deploy to VPS (DigitalOcean, AWS, etc.) |
| [🐳 DOCKER_QUICK_START.md](./DOCKER_QUICK_START.md) | Docker quick reference |
| [📦 README.Docker.md](./README.Docker.md) | Complete Docker guide |
| [⚙️ docs/BACKEND_OVERVIEW.md](./docs/BACKEND_OVERVIEW.md) | Backend architecture & API |

## 🎯 Features

- ✅ **AI-Powered Chat** - Uses Azure OpenAI for educational conversations
- ✅ **Safety First** - Content filtering and policy enforcement
- ✅ **Prompt Enhancement** - Automatically improves user prompts
- ✅ **Session Management** - Maintains conversation context
- ✅ **Chat History** - Save and retrieve conversations
- ✅ **Share Links** - Share conversations with unique tokens
- ✅ **Azure SQL Integration** - Persistent storage
- ✅ **Dockerized** - Easy deployment anywhere
- ✅ **Health Checks** - Built-in monitoring

## 🔧 Tech Stack

- **Runtime**: Node.js 20
- **Framework**: Express.js
- **AI**: Azure OpenAI
- **Database**: Azure SQL Database
- **Deployment**: Docker, Docker Compose

## 📋 API Endpoints

### Chat Endpoints
- `POST /api/chat` - Send a message
- `POST /api/chat/clear` - Clear session
- `POST /api/chats/save` - Save conversation
- `GET /api/chats` - List saved chats
- `GET /api/chats/:id` - Get specific chat

### Share Endpoints
- `POST /api/chats/share-link` - Create share link
- `GET /api/share/:token` - Get shared chat

### Health
- `GET /health` - Health check

**📖 See [docs/BACKEND_OVERVIEW.md](./docs/BACKEND_OVERVIEW.md) for detailed API documentation**

## 🌍 Environment Variables

```bash
# Server
PORT=8080
NODE_ENV=production

# Azure SQL Database
AZURE_SQL_USER=your_username
AZURE_SQL_PASS=your_password
AZURE_SQL_SERVER=your_server.database.windows.net
AZURE_SQL_DB=your_database_name

# Azure OpenAI
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com
AZURE_OPENAI_DEPLOYMENT=your_deployment_name
AZURE_OPENAI_API_VERSION=2025-01-01-preview
AZURE_OPENAI_API_KEY=your_api_key
```

## 🚀 Deployment Options

### Option 1: Railway (Fastest - 5 minutes)
Perfect for quick deployments and prototypes.

```bash
# Deploy to Railway
railway login
railway init
railway up
```

**📖 Full guide: [RAILWAY_DEPLOY.md](./RAILWAY_DEPLOY.md)**

### Option 2: VPS (Full Control)
Deploy to DigitalOcean, Linode, AWS EC2, etc.

```bash
# On your VPS
git clone <your-repo>
cd backend-schoolsafeai
docker-compose up -d
```

**📖 Full guide: [README.DEPLOYMENT.md](./README.DEPLOYMENT.md)**

### Option 3: Cloud Platforms
Deploy to Azure Container Instances, AWS ECS, Google Cloud Run, etc.

**📖 See [README.Docker.md](./README.Docker.md) for cloud deployment guides**

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
    "message": "Explain photosynthesis to a 12-year-old"
  }'
```

## 📊 Project Structure

```
backend-schoolsafeai/
├── server.js                 # Express server entry point
├── src/
│   ├── routes/
│   │   ├── chatRoutes.js    # Chat endpoints
│   │   └── shareRoutes.js   # Share link endpoints
│   └── lib/
│       ├── db.js            # Azure SQL helpers
│       ├── openai.js        # OpenAI/Azure helpers
│       ├── session.js       # Session management
│       └── prompt.js        # Prompt enhancement
├── docs/
│   └── BACKEND_OVERVIEW.md  # Detailed documentation
├── Dockerfile               # Docker image definition
├── docker-compose.yml       # Docker orchestration
└── package.json             # Dependencies
```

## 🔒 Security

- ✅ Content filtering and safety checks
- ✅ Flagged message tracking for auditing
- ✅ Environment variables for secrets
- ✅ Non-root Docker user
- ✅ Minimal Alpine Linux base image
- ✅ Health check monitoring

## 🛠️ Development

### Available Scripts

```bash
# Run server
npm start

# Docker commands
npm run docker:build     # Build Docker image
npm run docker:up        # Start container
npm run docker:down      # Stop container
npm run docker:logs      # View logs
npm run docker:restart   # Restart container
npm run docker:rebuild   # Rebuild & restart
```

### Local Development Without Docker

```bash
# Install dependencies
npm install

# Create .env file
cp env.template .env

# Start server
npm start
```

## 📈 Monitoring

### Docker
```bash
# View logs
docker-compose logs -f

# Check health
docker ps

# Container stats
docker stats
```

### Production
- Built-in `/health` endpoint
- Request ID tracking
- Detailed error logging
- Session metrics

## 🐛 Troubleshooting

### Container won't start
```bash
docker-compose logs backend
```

### Database connection issues
- Verify Azure SQL firewall rules
- Check credentials in `.env`
- Ensure network connectivity

### Port already in use
```bash
# Change port in .env
PORT=3000
```

**📖 See [README.DEPLOYMENT.md](./README.DEPLOYMENT.md#troubleshooting) for detailed troubleshooting**

## 📝 License

ISC

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

- **Documentation**: Check the guides in this repository
- **Issues**: Open a GitHub issue
- **Architecture**: See [docs/BACKEND_OVERVIEW.md](./docs/BACKEND_OVERVIEW.md)

---

**Built with ❤️ for safe, educational AI experiences**

