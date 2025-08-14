# Coolify Configuration - Changes Summary

## Files Created/Modified for Coolify Deployment

### 1. **docker-compose.coolify.yaml** (NEW)
   - Dedicated Docker Compose configuration optimized for Coolify
   - Added Coolify-specific labels for service management
   - Configured health checks for monitoring
   - Enhanced volume configuration with persistent storage labels
   - Added network configuration with labels
   - Included resource limits (2GB RAM, 2 CPU cores - adjustable)
   - Port mapping: 3000:8080 (external:internal)

### 2. **.env.coolify** (NEW)
   - Environment variables template for Coolify deployment
   - Pre-configured with all necessary variables
   - Includes documentation for each setting
   - Security reminder for WEBUI_SECRET_KEY generation

### 3. **COOLIFY_DEPLOYMENT.md** (NEW)
   - Comprehensive deployment guide for Coolify
   - Step-by-step instructions
   - Troubleshooting section
   - Production recommendations
   - Coolify-specific features explained

### 4. **validate-coolify-config.sh** (NEW)
   - Validation script to check deployment readiness
   - Verifies all required files exist
   - Checks configuration completeness
   - Provides colored output with clear status indicators

### 5. **docker-compose.yaml** (MODIFIED)
   - Added comment directing users to use docker-compose.coolify.yaml for Coolify deployments
   - Original configuration preserved for standard Docker deployments

## Key Configuration Features

### Port Configuration
- Default mapping: **3000:8080**
- External port (3000) is configurable via `OPEN_WEBUI_PORT` environment variable
- Internal port (8080) is fixed

### Volumes for Persistent Storage
1. **ollama**: Stores Ollama models
2. **open-webui-data**: Main application data
3. **open-webui-cache**: Cache for models and temporary files
4. **open-webui-models**: Additional model storage

### Coolify Labels Added
- `coolify.managed=true`: Marks resources as Coolify-managed
- `coolify.proxy=true`: Enables Coolify's reverse proxy
- `coolify.proxy.port=8080`: Specifies internal port for proxy
- `coolify.healthcheck.*`: Configures health monitoring
- `coolify.resources.limits.*`: Sets resource constraints
- `coolify.volume.type=persistent`: Ensures data persistence

### Health Checks
- Endpoint: `/health`
- Interval: 30 seconds
- Timeout: 10 seconds
- Retries: 3
- Start period: 40 seconds

### Security Enhancements
- `WEBUI_SECRET_KEY` environment variable for session security
- CORS configuration for domain restrictions
- Telemetry disabled by default
- Production environment setting

## Next Steps for Deployment

1. **Configure Environment Variables**
   ```bash
   cp .env.coolify .env
   # Edit .env and set your values
   ```

2. **Generate Secret Key**
   ```bash
   openssl rand -hex 32
   # Add this to WEBUI_SECRET_KEY in .env
   ```

3. **Validate Configuration** (Linux/Mac)
   ```bash
   bash validate-coolify-config.sh
   ```

4. **Push to Repository**
   ```bash
   git add docker-compose.coolify.yaml .env.coolify COOLIFY_DEPLOYMENT.md
   git commit -m "Add Coolify deployment configuration"
   git push
   ```

5. **Deploy in Coolify**
   - Add new Docker Compose resource
   - Specify `docker-compose.coolify.yaml` as compose file
   - Configure environment variables in Coolify UI
   - Deploy and monitor logs

## Configuration Compatibility

✅ **Port Mapping**: Properly configured (3000:8080)  
✅ **Volumes**: Multiple volumes for persistent storage  
✅ **Health Checks**: Configured for monitoring  
✅ **Labels**: All Coolify-specific labels added  
✅ **Networks**: Dedicated network with proper configuration  
✅ **Environment**: All necessary variables templated  
✅ **Documentation**: Complete deployment guide provided  

## Notes

- The configuration maintains compatibility with the original Open WebUI setup
- All Coolify-specific configurations are isolated in separate files
- Original docker-compose.yaml remains unchanged for standard deployments
- Resource limits are suggestions and can be adjusted based on server capacity
