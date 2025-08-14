# Coolify Deployment - Next Steps

## ✅ Completed Preparation Steps

1. **Docker Compose Configuration** (`docker-compose.coolify.yaml`)
   - Configured Open WebUI and Ollama services
   - Added health checks at `/health` endpoint
   - Set up persistent volumes for data storage
   - Configured resource limits (2GB RAM, 2 CPU cores)
   - Added Coolify-specific labels for monitoring

2. **Secret Key Generated**
   ```
   WEBUI_SECRET_KEY: e32c4d6483d699b168a00a81226b399e7463aa1bf714760bb13e4f177c3466de
   ```

3. **Documentation Created**
   - Deployment monitoring guide (DEPLOYMENT_MONITORING.md)
   - Health check testing script (test-deployment.ps1)
   - Environment configuration guide

4. **GitHub Repository Updated**
   - All configurations pushed to main branch
   - Ready for Coolify webhook deployment

## 🚀 Action Required in Coolify

### Step 1: Create New Application in Coolify
1. Log into your Coolify dashboard
2. Navigate to your project
3. Click "New Resource" → "Docker Compose"
4. Configure source:
   - Repository: `https://github.com/WRLDInc/wrld-open-webui`
   - Branch: `main`
   - Docker Compose file: `docker-compose.coolify.yaml`

### Step 2: Configure Environment Variables
Add these environment variables in Coolify's environment section:

| Variable | Value | Secret |
|----------|-------|--------|
| WEBUI_SECRET_KEY | e32c4d6483d699b168a00a81226b399e7463aa1bf714760bb13e4f177c3466de | ✅ Yes |
| OPEN_WEBUI_PORT | 3000 | No |
| OLLAMA_DOCKER_TAG | latest | No |
| WEBUI_DOCKER_TAG | main | No |
| CORS_ALLOW_ORIGIN | * | No |
| FORWARDED_ALLOW_IPS | * | No |
| WHISPER_MODEL | base | No |
| RAG_EMBEDDING_MODEL | sentence-transformers/all-MiniLM-L6-v2 | No |

### Step 3: Configure Domain & Proxy
1. Set your application domain (e.g., `open-webui.yourdomain.com`)
2. Enable HTTPS with Let's Encrypt
3. Configure proxy settings:
   - Port: 8080
   - Type: HTTP

### Step 4: Deploy Application
1. Click "Deploy" button
2. Monitor build logs for any errors
3. Wait for containers to start

## 📊 Monitoring During Deployment

### Build Phase Checklist
Watch for these in the build logs:
- [ ] Cloning repository successful
- [ ] Docker Compose file parsed correctly
- [ ] Images pulled successfully
- [ ] Networks created
- [ ] Volumes mounted
- [ ] Containers started

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Build fails | Check Docker Compose syntax, verify image availability |
| Port conflict | Change OPEN_WEBUI_PORT to unused port |
| Memory issues | Increase server resources or reduce limits |
| Network errors | Check firewall rules and Docker network configuration |
| Volume permissions | Ensure proper permissions for persistent storage |

## 🧪 Post-Deployment Testing

### Quick Test Commands

1. **From Coolify Server (SSH)**:
   ```bash
   # Check containers
   docker ps | grep -E "open-webui|ollama"
   
   # Test health endpoint
   curl http://localhost:8080/health
   
   # View logs
   docker logs open-webui --tail 50
   ```

2. **From Your Local Machine**:
   ```powershell
   # Run the test script (replace with your domain)
   .\test-deployment.ps1 -AppUrl "https://open-webui.yourdomain.com"
   ```

## 📈 Enable Monitoring in Coolify

### Configure Monitoring
1. Go to Application → Monitoring tab
2. Enable:
   - Container monitoring
   - Resource usage tracking
   - Health check monitoring (interval: 30s)
   - Log aggregation

### Set Up Alerts
Configure alerts for:
- Container restarts (>3 in 10 minutes)
- Memory usage (>80%)
- CPU usage (>90%)
- Health check failures (3 consecutive)
- Disk space (volumes >80% full)

## 🔄 Webhook Configuration (Optional)

To enable automatic deployments on git push:
1. Go to Application → Webhooks
2. Copy the webhook URL
3. Add to GitHub repository:
   - Settings → Webhooks → Add webhook
   - Paste Coolify webhook URL
   - Content type: application/json
   - Events: Push events (main branch only)

## 📝 Final Verification Checklist

- [ ] Application accessible at configured domain
- [ ] HTTPS working with valid certificate
- [ ] Health check returning 200 OK
- [ ] Can log in and create user account
- [ ] Ollama models loading correctly
- [ ] Chat functionality working
- [ ] Data persisting across container restarts
- [ ] Monitoring dashboard showing metrics
- [ ] Alerts configured and tested

## 🆘 Support Resources

- **Coolify Documentation**: https://coolify.io/docs
- **Open WebUI Issues**: https://github.com/open-webui/open-webui/issues
- **Deployment Guide**: See DEPLOYMENT_MONITORING.md
- **Test Script**: Run `.\test-deployment.ps1 -Verbose`

## 📊 Expected Resource Usage

After successful deployment, expect:
- Memory: 500MB-1.5GB (normal operation)
- CPU: 5-20% (idle), 50-100% (model loading)
- Disk: ~2GB initial, grows with models/data
- Network: Minimal, unless downloading models

---

**Ready to Deploy!** 🚀

Follow these steps in Coolify to complete the deployment. The application is fully configured and ready to be deployed.
