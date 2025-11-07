# Docker Setup for SchoolSafeAI Frontend

This document explains how to build and run the SchoolSafeAI frontend using Docker.

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Build and start the container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the container
docker-compose down
```

The application will be available at `http://localhost:3000`

### Using Docker CLI

```bash
# Build the image
docker build -t schoolsafeai-frontend .

# Run the container
docker run -d -p 3000:80 --name schoolsafeai-frontend schoolsafeai-frontend

# View logs
docker logs -f schoolsafeai-frontend

# Stop the container
docker stop schoolsafeai-frontend

# Remove the container
docker rm schoolsafeai-frontend
```

## Build Arguments

You can pass build arguments to customize the build:

```bash
docker build --build-arg NODE_ENV=production -t schoolsafeai-frontend .
```

## Environment Variables

### Build-time Variables

Vite environment variables (prefixed with `VITE_`) are baked into the build at build time. Add them to `.env.production` or pass them during build:

```bash
docker build \
  --build-arg VITE_API_URL=https://api.example.com \
  -t schoolsafeai-frontend .
```

### Runtime Variables

For variables that need to change at runtime without rebuilding, you would need to implement a runtime configuration strategy (e.g., loading config from a JSON file).

## Multi-Architecture Build

To build for multiple architectures (e.g., AMD64 and ARM64):

```bash
# Setup buildx
docker buildx create --use

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t schoolsafeai-frontend:latest \
  --push .
```

## Production Deployment

### Optimize Image Size

The multi-stage Dockerfile is already optimized:
- Stage 1: Builds the application (~500MB)
- Stage 2: Final nginx image (~30MB)

### Health Checks

The container includes a health check that runs every 30 seconds:

```bash
# Check container health
docker inspect --format='{{.State.Health.Status}}' schoolsafeai-frontend
```

### Performance Tips

1. **Use .dockerignore**: Already configured to exclude unnecessary files
2. **Layer Caching**: Dependencies are copied before source code for better caching
3. **Nginx Compression**: Gzip is enabled for text assets
4. **Static Asset Caching**: Long cache headers for versioned assets

## Troubleshooting

### Container won't start

```bash
# Check logs
docker logs schoolsafeai-frontend

# Access container shell
docker exec -it schoolsafeai-frontend sh
```

### Port already in use

Change the port mapping in `docker-compose.yml` or use a different port:

```bash
docker run -d -p 8080:80 --name schoolsafeai-frontend schoolsafeai-frontend
```

### Build fails

```bash
# Clean build with no cache
docker build --no-cache -t schoolsafeai-frontend .
```

## Development vs Production

This Docker setup is for **production deployment**. For development, continue using:

```bash
npm run dev
```

The development server provides HMR (Hot Module Replacement) which is not available in the containerized version.

## CI/CD Integration

### GitHub Actions Example

```yaml
- name: Build Docker image
  run: docker build -t schoolsafeai-frontend .

- name: Push to registry
  run: |
    echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
    docker push schoolsafeai-frontend
```

### GitLab CI Example

```yaml
docker-build:
  stage: build
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```

## Security Considerations

1. **Nginx Configuration**: Security headers are already configured
2. **Non-root User**: Consider adding a non-root user in nginx
3. **Regular Updates**: Keep the base images updated
4. **Secrets**: Never commit secrets to the repository

## Customization

### Custom Nginx Configuration

Edit `nginx.conf` to customize server behavior.

### Different Base Image

You can change the nginx base image in the Dockerfile:
- `nginx:alpine` - Smallest (default)
- `nginx:mainline-alpine` - Latest features
- `nginx:stable-alpine` - Most stable

### Add SSL/TLS

For HTTPS support, mount certificates and update nginx.conf:

```yaml
volumes:
  - ./certs:/etc/nginx/certs:ro
```

