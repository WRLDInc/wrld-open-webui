# Coolify Persistent Storage Configuration

This document provides detailed instructions for configuring and managing persistent storage volumes in Coolify for the Open WebUI application.

## Table of Contents
- [Volume Configuration](#volume-configuration)
- [Permissions Setup](#permissions-setup)
- [Backup Strategies](#backup-strategies)
- [Volume Management](#volume-management)
- [Troubleshooting](#troubleshooting)

## Volume Configuration

### Currently Configured Volumes

The application uses the following persistent volumes:

1. **Ollama Data Volume** (`ollama`)
   - Mount path: `/root/.ollama`
   - Purpose: Stores downloaded LLM models and Ollama configuration
   - Size recommendation: 50-200GB depending on model usage

2. **Open WebUI Data Volume** (`open-webui-data`)
   - Mount path: `/app/backend/data`
   - Purpose: Primary application data, user configurations, and database
   - Size recommendation: 10-50GB

3. **Open WebUI Cache Volume** (`open-webui-cache`)
   - Mount path: `/app/backend/data/cache`
   - Purpose: Temporary cache files for improved performance
   - Size recommendation: 5-20GB

4. **Open WebUI Models Volume** (`open-webui-models`)
   - Mount path: `/app/backend/data/models`
   - Purpose: Stores custom models and embeddings
   - Size recommendation: 20-100GB

### Coolify Volume Configuration

In your Coolify dashboard, configure the volumes as follows:

```yaml
# Volume definitions in docker-compose.coolify.yaml
volumes:
  ollama:
    driver: local
    labels:
      - "coolify.managed=true"
      - "coolify.volume.type=persistent"
      - "coolify.volume.backup=true"
      - "coolify.volume.retention=7d"
  
  open-webui-data:
    driver: local
    labels:
      - "coolify.managed=true"
      - "coolify.volume.type=persistent"
      - "coolify.volume.backup=true"
      - "coolify.volume.retention=30d"
      - "coolify.volume.critical=true"
  
  open-webui-cache:
    driver: local
    labels:
      - "coolify.managed=true"
      - "coolify.volume.type=persistent"
      - "coolify.volume.backup=false"  # Cache can be regenerated
  
  open-webui-models:
    driver: local
    labels:
      - "coolify.managed=true"
      - "coolify.volume.type=persistent"
      - "coolify.volume.backup=true"
      - "coolify.volume.retention=14d"
```

### Coolify UI Configuration Steps

1. **Navigate to your application** in Coolify dashboard
2. **Go to Storage tab**
3. **Add persistent volumes** with the following settings:

   ```
   Volume 1:
   - Name: ollama-data
   - Mount Path: /root/.ollama
   - Size: 100GB (adjust based on needs)
   - Type: Persistent
   
   Volume 2:
   - Name: webui-data
   - Mount Path: /app/backend/data
   - Size: 20GB
   - Type: Persistent
   
   Volume 3:
   - Name: webui-cache
   - Mount Path: /app/backend/data/cache
   - Size: 10GB
   - Type: Persistent
   
   Volume 4:
   - Name: webui-models
   - Mount Path: /app/backend/data/models
   - Size: 50GB
   - Type: Persistent
   ```

## Permissions Setup

### Setting Correct Permissions

Create an initialization script to ensure proper permissions:

```bash
#!/bin/bash
# init-volumes.sh

# Function to set permissions for a volume
set_volume_permissions() {
    local volume_path=$1
    local user_id=${2:-1000}
    local group_id=${3:-1000}
    
    echo "Setting permissions for $volume_path..."
    
    # Create directory if it doesn't exist
    mkdir -p "$volume_path"
    
    # Set ownership
    chown -R $user_id:$group_id "$volume_path"
    
    # Set permissions (read/write for owner, read for group, no access for others)
    chmod -R 750 "$volume_path"
    
    # Set special permissions for data directory
    if [[ "$volume_path" == *"/data"* ]]; then
        chmod -R 770 "$volume_path"
    fi
}

# Set permissions for each volume
set_volume_permissions "/app/backend/data"
set_volume_permissions "/app/backend/data/cache"
set_volume_permissions "/app/backend/data/models"
set_volume_permissions "/root/.ollama" 0 0  # Root ownership for Ollama
```

### Docker Compose Permission Configuration

Add user configuration to your services:

```yaml
services:
  open-webui:
    # ... other configuration ...
    user: "${USER_ID:-1000}:${GROUP_ID:-1000}"
    environment:
      - PUID=${USER_ID:-1000}
      - PGID=${GROUP_ID:-1000}
```

## Backup Strategies

### Automated Backup Script

Create a backup script for critical data:

```bash
#!/bin/bash
# backup-volumes.sh

# Configuration
BACKUP_DIR="/backups/open-webui"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to backup a volume
backup_volume() {
    local volume_name=$1
    local backup_name="${volume_name}_${TIMESTAMP}.tar.gz"
    
    echo "Backing up $volume_name..."
    
    # Create backup using Docker
    docker run --rm \
        -v ${volume_name}:/data:ro \
        -v ${BACKUP_DIR}:/backup \
        alpine tar czf /backup/${backup_name} -C / data
    
    echo "Backup completed: ${backup_name}"
}

# Backup critical volumes
backup_volume "open-webui-data"
backup_volume "open-webui-models"
backup_volume "ollama"

# Remove old backups
echo "Removing backups older than ${RETENTION_DAYS} days..."
find ${BACKUP_DIR} -type f -name "*.tar.gz" -mtime +${RETENTION_DAYS} -delete

echo "Backup process completed!"
```

### Coolify Backup Integration

Configure automated backups in Coolify:

1. **In Coolify Dashboard:**
   - Navigate to Settings → Backups
   - Configure S3 or local backup destination
   - Set backup schedule (recommended: daily at 2 AM)

2. **Add backup labels to volumes:**
   ```yaml
   volumes:
     open-webui-data:
       labels:
         - "coolify.backup.enabled=true"
         - "coolify.backup.schedule=0 2 * * *"
         - "coolify.backup.retention=30"
   ```

### Database-Specific Backup

For SQLite database backup (if using):

```bash
#!/bin/bash
# backup-database.sh

DB_PATH="/app/backend/data/webui.db"
BACKUP_PATH="/backups/database"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_PATH"

# Backup SQLite database
docker exec open-webui sqlite3 $DB_PATH ".backup '${BACKUP_PATH}/webui_${TIMESTAMP}.db'"

# Compress backup
gzip "${BACKUP_PATH}/webui_${TIMESTAMP}.db"

echo "Database backup completed: webui_${TIMESTAMP}.db.gz"
```

## Volume Management

### Monitoring Volume Usage

Create a monitoring script:

```bash
#!/bin/bash
# monitor-volumes.sh

echo "=== Volume Usage Report ==="
echo

# Check each volume
for volume in ollama open-webui-data open-webui-cache open-webui-models; do
    echo "Volume: $volume"
    docker run --rm -v ${volume}:/data:ro alpine df -h /data
    echo "---"
done

# Alert if usage exceeds threshold
THRESHOLD=80

check_usage() {
    local volume=$1
    local usage=$(docker run --rm -v ${volume}:/data:ro alpine df /data | awk 'NR==2 {print int($5)}')
    
    if [ $usage -gt $THRESHOLD ]; then
        echo "WARNING: Volume $volume is ${usage}% full!"
        # Send alert (email, webhook, etc.)
    fi
}

for volume in ollama open-webui-data open-webui-cache open-webui-models; do
    check_usage $volume
done
```

### Volume Maintenance

Regular maintenance tasks:

```bash
#!/bin/bash
# maintain-volumes.sh

# Clean cache volume
echo "Cleaning cache volume..."
docker exec open-webui find /app/backend/data/cache -type f -mtime +7 -delete

# Remove orphaned model files
echo "Cleaning orphaned files..."
docker exec open-webui find /app/backend/data/models -type f -size 0 -delete

# Optimize SQLite database
echo "Optimizing database..."
docker exec open-webui sqlite3 /app/backend/data/webui.db "VACUUM;"

echo "Maintenance completed!"
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Permission Denied Errors

**Problem:** Container cannot write to volume
**Solution:**
```bash
# Fix permissions
docker exec -u root open-webui chown -R 1000:1000 /app/backend/data
docker exec -u root open-webui chmod -R 755 /app/backend/data
```

#### 2. Volume Full

**Problem:** No space left on device
**Solution:**
```bash
# Check volume usage
docker system df -v

# Clean unused data
docker system prune -a --volumes

# Expand volume in Coolify UI or migrate to larger volume
```

#### 3. Data Loss After Update

**Problem:** Data missing after container update
**Solution:**
- Ensure volumes are properly mounted in docker-compose.yaml
- Check volume labels for persistence
- Restore from backup if needed

#### 4. Slow Performance

**Problem:** Application running slowly
**Solution:**
```bash
# Move cache to faster storage
# Or increase cache volume size
# Clear old cache files
docker exec open-webui rm -rf /app/backend/data/cache/*
```

### Volume Migration

To migrate volumes to new storage:

```bash
#!/bin/bash
# migrate-volume.sh

OLD_VOLUME="open-webui-data"
NEW_VOLUME="open-webui-data-new"

# Create new volume
docker volume create $NEW_VOLUME

# Copy data
docker run --rm \
    -v ${OLD_VOLUME}:/source:ro \
    -v ${NEW_VOLUME}:/dest \
    alpine cp -av /source/. /dest/

# Update docker-compose.yaml to use new volume
# Then restart containers
```

## Best Practices

1. **Regular Backups:** Schedule daily backups for critical data
2. **Monitor Usage:** Set up alerts for volume usage above 80%
3. **Test Restores:** Regularly test backup restoration procedures
4. **Document Changes:** Keep track of volume configuration changes
5. **Use Labels:** Properly label volumes in Coolify for management
6. **Separate Concerns:** Keep cache, data, and models in separate volumes
7. **Security:** Restrict volume access permissions appropriately

## Recovery Procedures

### Full Recovery from Backup

```bash
#!/bin/bash
# restore-from-backup.sh

BACKUP_FILE=$1
VOLUME_NAME=$2

if [ -z "$BACKUP_FILE" ] || [ -z "$VOLUME_NAME" ]; then
    echo "Usage: $0 <backup-file> <volume-name>"
    exit 1
fi

# Stop containers
docker-compose -f docker-compose.coolify.yaml down

# Remove existing volume
docker volume rm $VOLUME_NAME

# Create new volume
docker volume create $VOLUME_NAME

# Restore from backup
docker run --rm \
    -v ${VOLUME_NAME}:/data \
    -v $(dirname $BACKUP_FILE):/backup:ro \
    alpine tar xzf /backup/$(basename $BACKUP_FILE) -C /

# Start containers
docker-compose -f docker-compose.coolify.yaml up -d

echo "Restoration completed!"
```

## Coolify-Specific Commands

Use these commands in Coolify's terminal or SSH:

```bash
# List all volumes
coolify volume list

# Backup specific volume
coolify volume backup open-webui-data

# Restore volume
coolify volume restore open-webui-data backup-file.tar.gz

# Check volume status
coolify volume status open-webui-data

# Resize volume (if supported)
coolify volume resize open-webui-data 50G
```

## Contact and Support

For issues with persistent storage:
1. Check Coolify logs: `coolify logs open-webui`
2. Review volume status in Coolify dashboard
3. Consult this documentation
4. Contact support with volume diagnostics

---

*Last updated: January 2025*
*Version: 1.0.0*
