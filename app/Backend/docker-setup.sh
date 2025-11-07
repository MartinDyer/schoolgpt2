#!/bin/bash

# SchoolSafeAI Backend - Docker Setup Script

set -e

echo "🚀 SchoolSafeAI Backend - Docker Setup"
echo "======================================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed."
    echo "Please install Docker from https://www.docker.com/get-started"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Error: Docker Compose is not installed."
    echo "Please install Docker Compose from https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker is installed"
echo "✅ Docker Compose is installed"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  Warning: .env file not found"
    echo ""
    echo "Please create a .env file with the following variables:"
    echo ""
    echo "# Server Configuration"
    echo "PORT=8080"
    echo ""
    echo "# Azure OpenAI Configuration"
    echo "AZURE_OPENAI_ENDPOINT=https://your-openai-resource.openai.azure.com"
    echo "AZURE_OPENAI_DEPLOYMENT=your-deployment-name"
    echo "AZURE_OPENAI_API_VERSION=2025-01-01-preview"
    echo "AZURE_OPENAI_API_KEY=your-api-key-here"
    echo ""
    echo "# Azure SQL Configuration"
    echo "AZURE_SQL_USER=your-sql-username"
    echo "AZURE_SQL_PASS=your-sql-password"
    echo "AZURE_SQL_SERVER=your-server.database.windows.net"
    echo "AZURE_SQL_DB=your-database-name"
    echo ""
    read -p "Do you want to create a template .env file now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cat > .env << 'EOF'
# Server Configuration
PORT=8080

# Azure OpenAI Configuration
AZURE_OPENAI_ENDPOINT=https://your-openai-resource.openai.azure.com
AZURE_OPENAI_DEPLOYMENT=your-deployment-name
AZURE_OPENAI_API_VERSION=2025-01-01-preview
AZURE_OPENAI_API_KEY=your-api-key-here

# Azure SQL Configuration
AZURE_SQL_USER=your-sql-username
AZURE_SQL_PASS=your-sql-password
AZURE_SQL_SERVER=your-server.database.windows.net
AZURE_SQL_DB=your-database-name
EOF
        echo "✅ Created .env template file"
        echo "⚠️  Please edit .env and add your actual credentials before continuing"
        exit 0
    else
        echo "Please create .env file manually before proceeding"
        exit 1
    fi
else
    echo "✅ .env file found"
fi

echo ""
echo "Building Docker image..."
docker-compose build

echo ""
echo "Starting container..."
docker-compose up -d

echo ""
echo "✅ Container started successfully!"
echo ""
echo "Health check in progress..."
sleep 5

# Check health
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Backend is healthy and running!"
    echo ""
    echo "📊 Container Status:"
    docker-compose ps
    echo ""
    echo "🌐 API is available at: http://localhost:8080"
    echo "🏥 Health endpoint: http://localhost:8080/health"
    echo ""
    echo "📝 Useful commands:"
    echo "  - View logs:        docker-compose logs -f"
    echo "  - Stop container:   docker-compose down"
    echo "  - Restart:          docker-compose restart"
    echo "  - Rebuild:          docker-compose up -d --build"
else
    echo "⚠️  Health check failed. Checking logs..."
    echo ""
    docker-compose logs --tail=50
    echo ""
    echo "❌ Container may not be healthy. Please check the logs above."
    echo "   Try: docker-compose logs -f"
fi

