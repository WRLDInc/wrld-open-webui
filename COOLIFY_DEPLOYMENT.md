# Coolify Deployment Guide for Open WebUI

This guide provides instructions for deploying Open WebUI with Ollama using Coolify.

## Prerequisites

- A Coolify instance up and running
- Docker and Docker Compose installed on your Coolify server
- Sufficient server resources (minimum 4GB RAM, 2 CPU cores recommended)
- Domain name configured (optional but recommended)

## Deployment Steps

### 1. Prepare Your Repository

If deploying from a Git repository:

1. Fork or clone this repository to your Git provider (GitHub, GitLab, etc.)
2. Ensure the following files are present:
   - `docker-compose.coolify.yaml` (Coolify-optimized configuration)
   - `.env.coolify` (environment variables template)
   - `Dockerfile` (for building the Open WebUI image)

### 2. Configure Coolify Application

1. **Create New Application in Coolify:**
   - Navigate to your Coolify dashboard
   - Click "Add New Resource" → "Docker Compose"
   - Select your server and project

2. **Configure Source:**
   - Choose "GitHub/GitLab/Bitbucket" for Git deployment
   - Or choose "Direct Docker Compose" for manual configuration
   - If using Git, connect your repository

3. **Set Docker Compose File:**
   - Specify `docker-compose.coolify.yaml` as the compose file
   - Or paste the contents directly if using manual configuration

### 3. Configure Environment Variables

In Coolify's environment variables section, add the following:

```env
# Required
OPEN_WEBUI_PORT=3000
WEBUI_SECRET_KEY=your-generated-secret-key-here

# Optional - OpenAI Integration
OPENAI_API_BASE_URL=
OPENAI_API_KEY=

# Production Settings
CORS_ALLOW_ORIGIN=https://your-domain.com
FORWARDED_ALLOW_IPS=127.0.0.1

# Model Configuration
WHISPER_MODEL=base
RAG_EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
```

**Important:** Generate a secure secret key using:
```bash
openssl rand -hex 32
```

### 4. Configure Persistent Storage

The configuration includes several volumes for persistent data:

- `ollama`: Stores Ollama models
- `open-webui-data`: Main application data
- `open-webui-cache`: Cache for models and temporary files
- `open-webui-models`: Additional model storage

Coolify will automatically manage these volumes with the labels provided.

### 5. Network Configuration

The default configuration exposes Open WebUI on port 3000:

- External Port: 3000 (configurable via `OPEN_WEBUI_PORT`)
- Internal Port: 8080 (fixed)

If you need to change the external port, update the `OPEN_WEBUI_PORT` environment variable.

### 6. Domain and SSL Configuration

1. **Configure Domain in Coolify:**
   - In your application settings, add your domain
   - Enable "Generate SSL Certificate" for automatic Let's Encrypt SSL

2. **Update CORS Settings:**
   - Set `CORS_ALLOW_ORIGIN` to your domain (e.g., `https://chat.yourdomain.com`)

### 7. Resource Limits (Optional)

The configuration includes suggested resource limits:

- Memory: 2GB (adjustable)
- CPU: 2 cores (adjustable)

To modify these, update the labels in the compose file or override in Coolify:

```yaml
labels:
  - "coolify.resources.limits.memory=4G"
  - "coolify.resources.limits.cpu=4"
```

### 8. Deploy the Application

1. Click "Deploy" in Coolify
2. Monitor the deployment logs for any issues
3. Wait for both services (ollama and open-webui) to be healthy

### 9. Verify Deployment

1. **Check Health Status:**
   - The application includes health checks
   - Coolify will show green status when healthy

2. **Access the Application:**
   - Navigate to `http://your-server-ip:3000` or your configured domain
   - Create your first admin account

3. **Test Ollama Integration:**
   - The Ollama service should be automatically connected
   - Try downloading a model through the UI

## Coolify-Specific Features

### Labels Explained

The configuration includes several Coolify-specific labels:

- `coolify.managed=true`: Marks resources as Coolify-managed
- `coolify.proxy=true`: Enables Coolify's reverse proxy
- `coolify.proxy.port=8080`: Specifies the internal port for proxy
- `coolify.healthcheck.*`: Configures health monitoring
- `coolify.resources.limits.*`: Sets resource constraints
- `coolify.volume.type=persistent`: Ensures data persistence

### Health Checks

The configuration includes automatic health checks:

- Path: `/health`
- Interval: 30 seconds
- Timeout: 10 seconds
- Retries: 3

### Automatic Restarts

Both services are configured with `restart: unless-stopped` for resilience.

## Troubleshooting

### Common Issues

1. **Port Conflicts:**
   - Ensure port 3000 is not in use
   - Change `OPEN_WEBUI_PORT` if needed

2. **Memory Issues:**
   - Increase memory limits if models fail to load
   - Consider using smaller models initially

3. **Ollama Connection:**
   - Verify ollama service is running
   - Check network connectivity between services

4. **Volume Permissions:**
   - Coolify should handle permissions automatically
   - If issues persist, check Docker volume permissions

### Logs

View logs in Coolify:
- Application logs: Available in Coolify dashboard
- Container logs: `docker logs open-webui` or `docker logs ollama`

### Rollback

Coolify supports easy rollback:
1. Go to Deployments tab
2. Select a previous deployment
3. Click "Rollback"

## Production Recommendations

1. **Security:**
   - Always set a strong `WEBUI_SECRET_KEY`
   - Use HTTPS with a valid SSL certificate
   - Restrict CORS origins to your domain

2. **Backup:**
   - Regularly backup the persistent volumes
   - Use Coolify's backup features if available

3. **Monitoring:**
   - Set up alerts for health check failures
   - Monitor resource usage

4. **Scaling:**
   - Start with base models and upgrade as needed
   - Monitor memory usage when adding models

## Updates

To update the application:

1. **Via Git (Recommended):**
   - Push changes to your repository
   - Trigger deployment in Coolify

2. **Manual Update:**
   - Update Docker images tags in environment variables
   - Redeploy in Coolify

## Support

- [Open WebUI Documentation](https://docs.openwebui.com)
- [Coolify Documentation](https://coolify.io/docs)
- [GitHub Issues](https://github.com/open-webui/open-webui/issues)

## Additional Notes

- The Ollama service is included for local model execution
- You can also connect to external Ollama instances or OpenAI
- Model downloads may take time on first deployment
- Consider pre-pulling Docker images for faster deployment
