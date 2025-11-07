# Docker Setup for SchoolSafeAI Backend

This document provides instructions for running the SchoolSafeAI backend using Docker.

## Prerequisites

- Docker installed (version 20.10 or higher)
- Docker Compose installed (version 1.29 or higher)
- Azure OpenAI and Azure SQL credentials

## Quick Start

### 1. Environment Setup

Copy the example environment file and fill in your credentials:

```bash
cp .env.example .env
```

Edit `.env` and add your Azure credentials.

### 2. Build and Run with Docker Compose

```bash
# Build and start the container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the container
docker-compose down
```

### 3. Build and Run with Docker Only

```bash
# Build the image
docker build -t schoolsafeai-backend .

# Run the container
docker run -d \
  --name schoolsafeai-backend \
  -p 8080:8080 \
  --env-file .env \
  schoolsafeai-backend

# View logs
docker logs -f schoolsafeai-backend

# Stop the container
docker stop schoolsafeai-backend
docker rm schoolsafeai-backend
```

## Docker Commands Reference

### Build

```bash
# Build the image
docker-compose build

# Or with Docker directly
docker build -t schoolsafeai-backend .
```

### Run

```bash
# Start services
docker-compose up -d

# Start with rebuild
docker-compose up -d --build
```

### Monitor

```bash
# View logs
docker-compose logs -f

# Check health status
docker-compose ps

# Execute commands in container
docker-compose exec backend sh
```

### Stop

```bash
# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

## Health Check

The container includes a health check that runs every 30 seconds:

```bash
# Check container health
docker ps

# Manual health check
curl http://localhost:8080/health
```

Expected response:
```json
{"status":"ok"}
```

## Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `PORT` | Server port | No | 8080 |
| `AZURE_OPENAI_ENDPOINT` | Azure OpenAI endpoint URL | Yes* | - |
| `AZURE_OPENAI_DEPLOYMENT` | OpenAI deployment name | Yes* | - |
| `AZURE_OPENAI_API_VERSION` | API version | No | 2025-01-01-preview |
| `AZURE_OPENAI_API_KEY` | Azure OpenAI API key | Yes* | - |
| `AZURE_SQL_USER` | SQL username | Yes** | - |
| `AZURE_SQL_PASS` | SQL password | Yes** | - |
| `AZURE_SQL_SERVER` | SQL server address | Yes** | - |
| `AZURE_SQL_DB` | SQL database name | Yes** | - |

*Required for OpenAI features (fallback to demo mode if not provided)  
**Required for database persistence

## Troubleshooting

### Container won't start

```bash
# Check logs for errors
docker-compose logs backend

# Verify environment variables
docker-compose config
```

### Connection issues

```bash
# Check if container is running
docker-compose ps

# Check network connectivity
docker-compose exec backend ping google.com

# Verify SQL connectivity
docker-compose exec backend sh
```

### Port already in use

```bash
# Change port in .env file
PORT=8081

# Or specify when running
docker-compose up -d -e PORT=8081
```

### Database connection errors

Ensure:
- Azure SQL firewall allows Docker container IP
- Credentials are correct in `.env`
- SQL server is accessible from your network

## Production Deployment

### Security Best Practices

1. **Use secrets management**: Don't commit `.env` to version control
2. **Non-root user**: The container runs as a non-root user by default
3. **Minimal base image**: Uses Alpine Linux for smaller attack surface
4. **Multi-stage build**: Reduces final image size

### Recommended Docker Run Options

```bash
docker run -d \
  --name schoolsafeai-backend \
  -p 8080:8080 \
  --env-file .env \
  --restart unless-stopped \
  --memory="512m" \
  --cpus="1.0" \
  --read-only \
  --tmpfs /tmp \
  schoolsafeai-backend
```

## CI/CD Integration

### Build and push to registry

```bash
# Tag image
docker tag schoolsafeai-backend:latest your-registry/schoolsafeai-backend:latest

# Push to registry
docker push your-registry/schoolsafeai-backend:latest
```

### Example GitHub Actions workflow

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Docker image
        run: docker build -t schoolsafeai-backend .
      
      - name: Run tests
        run: docker run schoolsafeai-backend npm test
```

## Support

For issues or questions, refer to:
- [BACKEND_OVERVIEW.md](./docs/BACKEND_OVERVIEW.md) - Backend architecture
- Docker logs: `docker-compose logs -f`
- Health endpoint: `http://localhost:8080/health`

