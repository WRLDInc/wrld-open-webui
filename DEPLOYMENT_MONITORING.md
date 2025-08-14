# Coolify Deployment Monitoring Guide

## Deployment Checklist

### 1. Pre-Deployment Setup ✅
- [x] Docker Compose Coolify configuration created
- [x] Health check endpoints configured at `/health`
- [x] Persistent volumes configured for data storage
- [x] Resource limits defined (2GB RAM, 2 CPU cores)
- [x] Generated secure WEBUI_SECRET_KEY: `e32c4d6483d699b168a00a81226b399e7463aa1bf714760bb13e4f177c3466de`
- [x] Pushed configuration to GitHub repository

### 2. Coolify Configuration Steps

#### Step 1: Access Coolify Dashboard
1. Navigate to your Coolify instance URL
2. Log in with your credentials
3. Go to Projects > Your Project

#### Step 2: Create New Application
1. Click "New Resource" > "Docker Compose"
2. Select your GitHub repository: `WRLDInc/wrld-open-webui`
3. Set branch to `main`
4. Set Docker Compose file to `docker-compose.coolify.yaml`

#### Step 3: Configure Environment Variables
Add the following environment variables in Coolify:

```
WEBUI_SECRET_KEY=e32c4d6483d699b168a00a81226b399e7463aa1bf714760bb13e4f177c3466de
OPEN_WEBUI_PORT=3000
OLLAMA_DOCKER_TAG=latest
WEBUI_DOCKER_TAG=main
CORS_ALLOW_ORIGIN=*
FORWARDED_ALLOW_IPS=*
WHISPER_MODEL=base
RAG_EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
```

**Important**: Mark `WEBUI_SECRET_KEY` as a secret!

#### Step 4: Configure Domains
1. Set your application domain (e.g., `open-webui.yourdomain.com`)
2. Enable HTTPS with Let's Encrypt
3. Configure proxy settings (port 8080)

### 3. Deployment Monitoring

#### During Build
Monitor these items in the build logs:
- [ ] Docker image pull successful
- [ ] Dependencies installed correctly
- [ ] Application built without errors
- [ ] Volumes mounted properly
- [ ] Network created successfully

#### Common Build Issues to Watch For:
- Memory constraints during build
- Network connectivity issues
- Docker registry access problems
- Volume permission errors

### 4. Post-Deployment Verification

#### Container Status Checks
```bash
# Check if containers are running
docker ps | grep -E "open-webui|ollama"

# Check container logs
docker logs open-webui --tail 50
docker logs ollama --tail 50

# Check resource usage
docker stats open-webui ollama --no-stream
```

#### Health Check Verification
1. **Internal Health Check**:
   ```bash
   curl http://localhost:8080/health
   ```
   Expected response: `{"status": "healthy"}` or similar

2. **External Health Check**:
   ```bash
   curl https://your-domain.com/health
   ```

3. **Application Endpoints**:
   - Main UI: `https://your-domain.com/`
   - API Docs: `https://your-domain.com/docs`
   - Ollama API: `https://your-domain.com/ollama/api/tags`

### 5. Monitoring Setup

#### Coolify Built-in Monitoring
1. Navigate to Application > Monitoring
2. Enable monitoring toggles:
   - [ ] Container monitoring
   - [ ] Resource usage tracking
   - [ ] Health check monitoring
   - [ ] Log aggregation

#### Alert Configuration
Set up alerts for:
- [ ] Container restart events
- [ ] High memory usage (>80%)
- [ ] High CPU usage (>90%)
- [ ] Health check failures
- [ ] Volume space warnings

#### Recommended Alert Thresholds:
```yaml
alerts:
  memory_warning: 1.6GB (80% of 2GB limit)
  memory_critical: 1.9GB (95% of 2GB limit)
  cpu_warning: 180% (90% of 2 cores)
  health_check_failures: 3 consecutive
  restart_count: 3 in 10 minutes
```

### 6. Testing Checklist

#### Functional Tests
- [ ] Access main UI at assigned URL
- [ ] Create a test user account
- [ ] Send a test message to Ollama
- [ ] Upload a test document for RAG
- [ ] Test model switching
- [ ] Verify persistent data storage

#### Performance Tests
- [ ] Page load time < 3 seconds
- [ ] API response time < 1 second
- [ ] Model loading time reasonable
- [ ] No memory leaks after extended use

### 7. Troubleshooting Guide

#### If Deployment Fails:
1. Check Coolify build logs for errors
2. Verify GitHub webhook is configured
3. Ensure environment variables are set
4. Check Docker Compose syntax
5. Verify resource availability on host

#### If Health Checks Fail:
1. Check container logs: `docker logs open-webui`
2. Verify port 8080 is accessible internally
3. Check database connection
4. Verify Ollama connectivity
5. Review application logs in `/app/backend/data/logs/`

#### If Performance Issues:
1. Monitor resource usage in Coolify
2. Check container stats: `docker stats`
3. Review slow query logs
4. Optimize model loading settings
5. Consider scaling resources

### 8. Rollback Plan

If issues occur:
1. In Coolify, go to Deployments
2. Select previous successful deployment
3. Click "Rollback to this deployment"
4. Monitor rollback process
5. Verify application functionality

### 9. Post-Deployment Tasks

- [ ] Document deployment URL and credentials
- [ ] Set up backup schedule for volumes
- [ ] Configure log rotation
- [ ] Set up uptime monitoring
- [ ] Create user documentation
- [ ] Schedule regular health reviews

## Important URLs and Commands

### Coolify Dashboard Access
- URL: `https://coolify.yourdomain.com`
- Project: Open WebUI
- Application: open-webui

### Quick Commands
```bash
# View logs
docker logs open-webui -f

# Restart application
docker-compose -f docker-compose.coolify.yaml restart

# Check volumes
docker volume ls | grep open-webui

# Backup data
docker run --rm -v open-webui-data:/data -v $(pwd):/backup alpine tar czf /backup/webui-backup.tar.gz /data
```

## Security Notes

1. **Secret Key**: Never commit the WEBUI_SECRET_KEY to version control
2. **CORS**: Update CORS_ALLOW_ORIGIN for production
3. **Firewall**: Ensure only necessary ports are exposed
4. **Updates**: Regularly update Docker images for security patches

## Support Contacts

- Coolify Issues: Check Coolify logs and documentation
- Application Issues: Review Open WebUI GitHub issues
- Infrastructure: Contact your hosting provider

---

**Last Updated**: January 14, 2025
**Deployment Version**: main branch
**Configuration**: docker-compose.coolify.yaml
