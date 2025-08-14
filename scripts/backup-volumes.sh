#!/bin/bash

# Coolify Persistent Volume Backup Script
# This script backs up critical volumes for the Open WebUI application

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/backups/open-webui}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS="${RETENTION_DAYS:-30}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to backup a volume
backup_volume() {
    local volume_name=$1
    local backup_name="${volume_name}_${TIMESTAMP}.tar.gz"
    
    print_message "$YELLOW" "📦 Backing up volume: $volume_name..."
    
    # Check if volume exists
    if ! docker volume ls | grep -q "$volume_name"; then
        print_message "$RED" "❌ Volume $volume_name does not exist!"
        return 1
    fi
    
    # Create backup using Docker
    if docker run --rm \
        -v ${volume_name}:/data:ro \
        -v ${BACKUP_DIR}:/backup \
        alpine tar czf /backup/${backup_name} -C / data 2>/dev/null; then
        
        # Get backup size
        size=$(du -h "${BACKUP_DIR}/${backup_name}" | cut -f1)
        print_message "$GREEN" "✅ Backup completed: ${backup_name} (${size})"
        
        # Calculate checksum
        checksum=$(docker run --rm -v ${BACKUP_DIR}:/backup alpine sha256sum /backup/${backup_name} | cut -d' ' -f1)
        echo "${checksum}  ${backup_name}" >> "${BACKUP_DIR}/checksums_${TIMESTAMP}.txt"
        
    else
        print_message "$RED" "❌ Failed to backup $volume_name"
        return 1
    fi
}

# Function to verify backup
verify_backup() {
    local backup_file=$1
    
    print_message "$YELLOW" "🔍 Verifying backup: $backup_file..."
    
    if docker run --rm \
        -v ${BACKUP_DIR}:/backup:ro \
        alpine tar tzf /backup/${backup_file} > /dev/null 2>&1; then
        print_message "$GREEN" "✅ Backup verified successfully"
    else
        print_message "$RED" "❌ Backup verification failed!"
        return 1
    fi
}

# Main backup process
print_message "$GREEN" "========================================="
print_message "$GREEN" "    Open WebUI Volume Backup Script"
print_message "$GREEN" "========================================="
echo

print_message "$YELLOW" "📅 Backup timestamp: ${TIMESTAMP}"
print_message "$YELLOW" "📁 Backup directory: ${BACKUP_DIR}"
echo

# Check if containers are running
if docker ps | grep -q "open-webui"; then
    print_message "$YELLOW" "⚠️  Warning: Containers are running. For consistency, consider stopping them before backup."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "$RED" "Backup cancelled."
        exit 1
    fi
fi

# Backup critical volumes
VOLUMES=(
    "open-webui-data"
    "open-webui-models"
    "ollama"
)

# Optional: backup cache if needed
if [[ "${BACKUP_CACHE}" == "true" ]]; then
    VOLUMES+=("open-webui-cache")
fi

# Perform backups
failed_backups=()
for volume in "${VOLUMES[@]}"; do
    if ! backup_volume "$volume"; then
        failed_backups+=("$volume")
    else
        # Verify the backup
        verify_backup "${volume}_${TIMESTAMP}.tar.gz"
    fi
    echo
done

# Clean old backups
print_message "$YELLOW" "🧹 Cleaning old backups (older than ${RETENTION_DAYS} days)..."
old_count=$(find ${BACKUP_DIR} -type f -name "*.tar.gz" -mtime +${RETENTION_DAYS} 2>/dev/null | wc -l)

if [ "$old_count" -gt 0 ]; then
    find ${BACKUP_DIR} -type f -name "*.tar.gz" -mtime +${RETENTION_DAYS} -delete
    find ${BACKUP_DIR} -type f -name "checksums_*.txt" -mtime +${RETENTION_DAYS} -delete
    print_message "$GREEN" "✅ Removed $old_count old backup(s)"
else
    print_message "$GREEN" "✅ No old backups to remove"
fi

# Summary
echo
print_message "$GREEN" "========================================="
print_message "$GREEN" "              BACKUP SUMMARY"
print_message "$GREEN" "========================================="

# List current backups
echo
print_message "$YELLOW" "📊 Current backups in ${BACKUP_DIR}:"
ls -lh ${BACKUP_DIR}/*.tar.gz 2>/dev/null | tail -5

# Show disk usage
echo
print_message "$YELLOW" "💾 Backup directory size:"
du -sh ${BACKUP_DIR}

# Report failed backups
if [ ${#failed_backups[@]} -gt 0 ]; then
    echo
    print_message "$RED" "⚠️  Failed backups:"
    for failed in "${failed_backups[@]}"; do
        print_message "$RED" "  - $failed"
    done
    exit 1
else
    echo
    print_message "$GREEN" "✅ All backups completed successfully!"
fi

# Optional: Upload to remote storage
if [[ -n "${S3_BUCKET}" ]]; then
    echo
    print_message "$YELLOW" "☁️  Uploading to S3..."
    for volume in "${VOLUMES[@]}"; do
        if [[ ! " ${failed_backups[@]} " =~ " ${volume} " ]]; then
            aws s3 cp "${BACKUP_DIR}/${volume}_${TIMESTAMP}.tar.gz" \
                "s3://${S3_BUCKET}/backups/${TIMESTAMP}/" \
                --storage-class GLACIER_IR
        fi
    done
    print_message "$GREEN" "✅ S3 upload completed"
fi

exit 0
