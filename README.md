# SchoolGPT - AI-Powered Educational Assistant

A safe, educational AI chatbot designed specifically for students, deployed on Azure with enterprise-grade security and scalability.

## 🚀 Live Application

**Production URL**: https://school-safe-gpt-fe-1234.azurewebsites.net

**Status**: ✅ Fully Operational

---

## Features

- 🤖 **AI-Powered Chat**: Powered by Azure OpenAI (gpt-4.1-mini)
- 💾 **Chat History**: Persistent storage with Azure SQL Database
- 🔐 **Microsoft Authentication**: Secure student login via Azure AD
- 🛡️ **Content Filtering**: Built-in AI safety for educational use
- 📱 **Responsive Design**: Works on desktop, tablet, and mobile

---

## Architecture

### Technology Stack

**Frontend:**
- React 18 with TypeScript
- Vite (build tool)
- MSAL Browser (Microsoft authentication)
- Deployed as static files

**Backend:**
- Node.js 20 (LTS)
- Express 5
- Azure OpenAI SDK
- MS SQL driver with Managed Identity

**Infrastructure:**
- Azure App Service (Linux)
- Azure OpenAI (ChatGPT-Safe resource)
- Azure SQL Database
- Azure AD (for authentication)
- Terraform (Infrastructure as Code)

### Security

- ✅ **Managed Identity**: No hardcoded credentials
- ✅ **Content Filtering**: Azure OpenAI safety features
- ✅ **SQL Injection Protection**: Parameterized queries
- ✅ **HTTPS Only**: Enforced SSL/TLS
- ✅ **Authentication**: Microsoft Azure AD

---

## Getting Started

### Prerequisites

- Node.js 20+ (LTS)
- npm or yarn
- Azure subscription (for deployment)
- Azure CLI (for deployment)

### Local Development

#### 1. Clone the Repository

```bash
git clone https://github.com/sapience-ext/schoolgpt.git
cd schoolgpt
```

#### 2. Set Up Backend

```bash
cd app/Backend
npm install
cp .env.example .env
# Edit .env with your Azure credentials
npm start
```

Backend will run on `http://localhost:8080`

#### 3. Set Up Frontend

```bash
cd app/Frontend
npm install
npm run dev
```

Frontend will run on `http://localhost:5173`

### Environment Variables

#### Backend (`.env`)
```env
# Azure OpenAI
AZURE_OPENAI_ENDPOINT=https://chatgpt-safe.cognitiveservices.azure.com/
AZURE_OPENAI_DEPLOYMENT=Test-gpt-4.1-mini
AZURE_OPENAI_API_VERSION=2024-08-01-preview

# Database
SQL_SERVER=school1sqlsrve2b9.database.windows.net
SQL_DATABASE=school1db
SQL_USER=<username>
SQL_PASSWORD=<password>

# App
PORT=8080
```

#### Frontend (`.env`)
```env
VITE_API_BASE=http://localhost:8080
VITE_AZURE_CLIENT_ID=abeede17-553a-4a0e-b2e2-ca619305a0e3
VITE_AZURE_TENANT_ID=<your-tenant-id>
```

---

## Deployment

### Automated Deployment

The project uses GitHub Actions for CI/CD:

```bash
# Trigger deployment
gh workflow run "06- Deploy Full App" --ref main

# Monitor deployment
gh run watch
```

### Manual Deployment

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed deployment instructions and troubleshooting.

---

## Project Structure

```
schoolgpt/
├── app/
│   ├── Backend/                 # Node.js Express API
│   │   ├── src/
│   │   │   ├── lib/            # Utilities (OpenAI, DB, etc.)
│   │   │   └── routes/         # API endpoints
│   │   ├── server.js           # Entry point
│   │   └── package.json
│   │
│   └── Frontend/                # React application
│       ├── src/
│       │   ├── components/     # React components
│       │   ├── pages/          # Page components
│       │   └── main.tsx        # Entry point
│       ├── index.html
│       └── package.json
│
├── infra/                       # Terraform configuration
│   ├── main.tf                 # Azure resources
│   ├── variables.tf
│   └── backend.tf              # State management
│
├── .github/workflows/          # CI/CD pipelines
│   ├── 01-setup-backend.yml
│   ├── 04-deploy-infrastructure.yml
│   └── 06-deploy-full-app.yml
│
├── DEPLOYMENT.md               # Deployment guide
└── README.md                   # This file
```

---

## API Reference

### Health Check
```http
GET /health
```

**Response:**
```json
{"status": "ok"}
```

### Send Chat Message
```http
POST /api/chat
Content-Type: application/json

{
  "message": "What is photosynthesis?",
  "userId": "student@school.edu",
  "sessionId": "unique-session-id"
}
```

**Response:**
```json
{
  "ok": true,
  "requestId": "uuid",
  "reply": "Photosynthesis is the process...",
  "enhancedPrompt": "Can you explain what photosynthesis is?",
  "usage": {
    "prompt_tokens": 45,
    "completion_tokens": 120,
    "total_tokens": 165
  },
  "latencyMs": 1250
}
```

### Get Chat History
```http
GET /api/chats?userId=student@school.edu
```

**Response:**
```json
{
  "ok": true,
  "items": [
    {
      "id": "uuid",
      "title": "Science Questions",
      "preview": "What is photosynthesis? Photosynthesis is...",
      "messageCount": 5,
      "updatedAt": "2026-01-07T10:30:00.000Z"
    }
  ]
}
```

For complete API documentation, see the backend [routes directory](./app/Backend/src/routes/).

---

## Configuration Details

### Key Files

#### Backend Configuration
- [`server.js`](./app/Backend/server.js) - Express server setup, static file serving
- [`openai.js`](./app/Backend/src/lib/openai.js) - Azure OpenAI integration
- [`chatRoutes.js`](./app/Backend/src/routes/chatRoutes.js) - Chat API logic

#### Frontend Configuration
- [`Index.tsx`](./app/Frontend/src/pages/Index.tsx) - Main application component
- [`.env`](./app/Frontend/.env) - Environment variables
- [`vite.config.ts`](./app/Frontend/vite.config.ts) - Build configuration

#### Infrastructure
- [`main.tf`](./infra/main.tf) - Azure resources (App Service, SQL, AI)

---

## Troubleshooting

### Common Issues

**Issue: Chat returns "I couldn't answer that"**
- Check Azure OpenAI rate limits
- Verify Managed Identity has permission
- Review logs: `az webapp log tail --name School-Safe-GPT-FE-1234`

**Issue: Login redirects to localhost**
- Ensure `.env` has no hardcoded redirect URIs
- Add production URL to Azure AD App Registration

**Issue: SQL connection errors**
- Verify firewall rule allows Azure Services (0.0.0.0)
- Check connection string in App Settings

For detailed troubleshooting, see [DEPLOYMENT.md](./DEPLOYMENT.md#troubleshooting).

---

## Development Workflow

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature
   ```

2. **Make your changes**
   - Frontend: Edit files in `app/Frontend/src/`
   - Backend: Edit files in `app/Backend/src/`
   - Infrastructure: Edit `infra/main.tf`

3. **Test locally**
   ```bash
   # Backend
   cd app/Backend && npm test

   # Frontend
   cd app/Frontend && npm run dev
   ```

4. **Commit and push**
   ```bash
   git add .
   git commit -m "feat: your feature description"
   git push origin feature/your-feature
   ```

5. **Deploy to Azure**
   - Merge to `main` branch
   - GitHub Actions will automatically deploy

---

## Contributing

This is a client project. For issues or feature requests, contact the development team.

---

## License

Proprietary - All rights reserved

---

## Support

**Developer**: Muhammad Umair Ali  
**Email**: mumairali@outlook.com  
**Deployed**: 2026-01-07

For deployment issues, see [DEPLOYMENT.md](./DEPLOYMENT.md)  
For technical walkthrough, see [walkthrough.md](./walkthrough.md)

---

## Acknowledgments

- Azure OpenAI Service
- Microsoft Azure Platform
- React and Vite communities
- Express.js framework