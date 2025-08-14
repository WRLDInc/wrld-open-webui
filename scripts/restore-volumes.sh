#!/bin/bash

# Coolify Persistent Volume Restore Script
# This script restores volumes from backups for the Open WebUI application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -b, --backup-dir DIR     Backup directory (default: /backups/open-webui)"
    echo "  -v, --volume NAME        Specific volume to restore (optional)"
    echo "  -t, --timestamp TIME     Backup timestamp to restore (optional)"
    echo "  -l, --list              List available backups"
    echo "  -f, --force             Force restore without confirmation"
    echo "  -h, --help              Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --list"
    echo "  $0 --volume open-webui-data --timestamp 20240115_120000"
    echo "  $0 --backup-dir /custom/backup/path --force"
}

# Default values
BACKUP_DIR="/backups/open-webui"
SPECIFIC_VOLUME=""
SPECIFIC_TIMESTAMP=""
LIST_ONLY=false
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -v|--volume)
            SPECIFIC_VOLUME="$2"
            shift 2
            ;;
        -t|--timestamp)
            SPECIFIC_TIMESTAMP="$2"
            shift 2
            ;;
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_message "$RED" "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Function to list available backups
list_backups() {
    print_message "$BLUE" "========================================="
    print_message "$BLUE" "       Available Backup Files"
    print_message "$BLUE" "========================================="
    echo
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_message "$RED" "❌ Backup directory does not exist: $BACKUP_DIR"
        exit 1
    fi
    
    # Group backups by timestamp
    timestamps=$(ls -1 ${BACKUP_DIR}/*.tar.gz 2>/dev/null | sed -n 's/.*_\([0-9]\{8\}_[0-9]\{6\}\)\.tar\.gz/\1/p' | sort -u)
    
    if [ -z "$timestamps" ]; then
        print_message "$YELLOW" "No backups found in $BACKUP_DIR"
        exit 0
    fi
    
    for ts in $timestamps; do
        date_formatted=$(echo $ts | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)_\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
        print_message "$GREEN" "📅 Timestamp: $ts ($date_formatted)"
        
        for backup in ${BACKUP_DIR}/*_${ts}.tar.gz; do
            if [ -f "$backup" ]; then
                volume_name=$(basename $backup | sed "s/_${ts}.tar.gz//")
                size=$(du -h "$backup" | cut -f1)
                echo "    - $volume_name ($size)"
            fi
        done
        echo
    done
}

# Function to verify backup integrity
verify_backup() {
    local backup_file=$1
    
    print_message "$YELLOW" "🔍 Verifying backup integrity..."
    
    if docker run --rm \
        -v $(dirname $backup_file):/backup:ro \
        alpine tar tzf /backup/$(basename $backup_file) > /dev/null 2>&1; then
        print_message "$GREEN" "✅ Backup verified successfully"
        return 0
    else
        print_message "$RED" "❌ Backup verification failed!"
        return 1
    fi
}

# Function to restore a volume
restore_volume() {
    local backup_file=$1
    local volume_name=$2
    
    print_message "$YELLOW" "📦 Restoring volume: $volume_name from $(basename $backup_file)..."
    
    # Verify backup first
    if ! verify_backup "$backup_file"; then
        print_message "$RED" "❌ Cannot restore from corrupted backup"
        return 1
    fi
    
    # Check if volume exists and create backup of current state
    if docker volume ls | grep -q "$volume_name"; then
        print_message "$YELLOW" "⚠️  Volume $volume_name exists. Creating safety backup..."
        
        safety_backup="/tmp/${volume_name}_safety_$(date +%Y%m%d_%H%M%S).tar.gz"
        docker run --rm \
            -v ${volume_name}:/data:ro \
            -v /tmp:/backup \
            alpine tar czf /backup/$(basename $safety_backup) -C / data
        
        print_message "$GREEN" "✅ Safety backup created: $safety_backup"
        
        # Remove existing volume
        print_message "$YELLOW" "🗑️  Removing existing volume..."
        docker volume rm $volume_name
    fi
    
    # Create new volume
    print_message "$YELLOW" "🆕 Creating new volume..."
    docker volume create $volume_name
    
    # Restore from backup
    print_message "$YELLOW" "📥 Extracting backup data..."
    if docker run --rm \
        -v ${volume_name}:/data \
        -v $(dirname $backup_file):/backup:ro \
        alpine tar xzf /backup/$(basename $backup_file) -C / 2>/dev/null; then
        
        print_message "$GREEN" "✅ Volume $volume_name restored successfully"
        
        # Set proper permissions
        print_message "$YELLOW" "🔧 Setting permissions..."
        if [[ "$volume_name" == "ollama" ]]; then
            docker run --rm -v ${volume_name}:/data alpine chown -R 0:0 /data
        else
            docker run --rm -v ${volume_name}:/data alpine chown -R 1000:1000 /data
        fi
        
        return 0
    else
        print_message "$RED" "❌ Failed to restore $volume_name"
        
        # Attempt to restore safety backup
        if [ -f "$safety_backup" ]; then
            print_message "$YELLOW" "🔄 Attempting to restore safety backup..."
            docker volume create $volume_name
            docker run --rm \
                -v ${volume_name}:/data \
                -v /tmp:/backup:ro \
                alpine tar xzf /backup/$(basename $safety_backup) -C /
        fi
        
        return 1
    fi
}

# Main execution
print_message "$GREEN" "========================================="
print_message "$GREEN" "   Open WebUI Volume Restore Script"
print_message "$GREEN" "========================================="
echo

# Check Docker availability
if ! command -v docker &> /dev/null; then
    print_message "$RED" "❌ Docker is not installed or not in PATH"
    exit 1
fi

# List only mode
if [ "$LIST_ONLY" = true ]; then
    list_backups
    exit 0
fi

# Check backup directory
if [ ! -d "$BACKUP_DIR" ]; then
    print_message "$RED" "❌ Backup directory does not exist: $BACKUP_DIR"
    exit 1
fi

# Find backup files
if [ -n "$SPECIFIC_VOLUME" ] && [ -n "$SPECIFIC_TIMESTAMP" ]; then
    # Restore specific volume from specific timestamp
    backup_file="${BACKUP_DIR}/${SPECIFIC_VOLUME}_${SPECIFIC_TIMESTAMP}.tar.gz"
    
    if [ ! -f "$backup_file" ]; then
        print_message "$RED" "❌ Backup file not found: $backup_file"
        exit 1
    fi
    
    volumes_to_restore=("$SPECIFIC_VOLUME")
    backup_files=("$backup_file")
    
elif [ -n "$SPECIFIC_TIMESTAMP" ]; then
    # Restore all volumes from specific timestamp
    backup_files=(${BACKUP_DIR}/*_${SPECIFIC_TIMESTAMP}.tar.gz)
    volumes_to_restore=()
    
    for bf in "${backup_files[@]}"; do
        if [ -f "$bf" ]; then
            volume_name=$(basename $bf | sed "s/_${SPECIFIC_TIMESTAMP}.tar.gz//")
            volumes_to_restore+=("$volume_name")
        fi
    done
    
elif [ -n "$SPECIFIC_VOLUME" ]; then
    # Restore specific volume from latest backup
    latest_backup=$(ls -t ${BACKUP_DIR}/${SPECIFIC_VOLUME}_*.tar.gz 2>/dev/null | head -1)
    
    if [ -z "$latest_backup" ]; then
        print_message "$RED" "❌ No backups found for volume: $SPECIFIC_VOLUME"
        exit 1
    fi
    
    volumes_to_restore=("$SPECIFIC_VOLUME")
    backup_files=("$latest_backup")
    
else
    # Restore all volumes from latest complete backup set
    latest_timestamp=$(ls -1 ${BACKUP_DIR}/*.tar.gz 2>/dev/null | sed -n 's/.*_\([0-9]\{8\}_[0-9]\{6\}\)\.tar\.gz/\1/p' | sort -u | tail -1)
    
    if [ -z "$latest_timestamp" ]; then
        print_message "$RED" "❌ No backups found in $BACKUP_DIR"
        exit 1
    fi
    
    backup_files=(${BACKUP_DIR}/*_${latest_timestamp}.tar.gz)
    volumes_to_restore=()
    
    for bf in "${backup_files[@]}"; do
        if [ -f "$bf" ]; then
            volume_name=$(basename $bf | sed "s/_${latest_timestamp}.tar.gz//")
            volumes_to_restore+=("$volume_name")
        fi
    done
fi

# Check if we found anything to restore
if [ ${#volumes_to_restore[@]} -eq 0 ]; then
    print_message "$RED" "❌ No volumes found to restore"
    exit 1
fi

# Display restore plan
print_message "$BLUE" "📋 Restore Plan:"
echo
for i in "${!volumes_to_restore[@]}"; do
    echo "  • ${volumes_to_restore[$i]} from $(basename ${backup_files[$i]})"
done
echo

# Check if containers are running
if docker ps | grep -q "open-webui\|ollama"; then
    print_message "$YELLOW" "⚠️  Warning: Containers are running and should be stopped before restore!"
    
    if [ "$FORCE" != true ]; then
        read -p "Stop containers and proceed? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_message "$RED" "Restore cancelled."
            exit 1
        fi
    fi
    
    print_message "$YELLOW" "🛑 Stopping containers..."
    docker-compose -f docker-compose.coolify.yaml down
fi

# Confirmation
if [ "$FORCE" != true ]; then
    print_message "$YELLOW" "⚠️  This will replace existing volume data!"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "$RED" "Restore cancelled."
        exit 1
    fi
fi

# Perform restore
failed_restores=()
for i in "${!volumes_to_restore[@]}"; do
    if ! restore_volume "${backup_files[$i]}" "${volumes_to_restore[$i]}"; then
        failed_restores+=("${volumes_to_restore[$i]}")
    fi
    echo
done

# Summary
print_message "$GREEN" "========================================="
print_message "$GREEN" "            RESTORE SUMMARY"
print_message "$GREEN" "========================================="

if [ ${#failed_restores[@]} -gt 0 ]; then
    print_message "$RED" "⚠️  Failed restores:"
    for failed in "${failed_restores[@]}"; do
        print_message "$RED" "  - $failed"
    done
    echo
    print_message "$YELLOW" "Please check the logs and try manual restoration if needed."
    exit_code=1
else
    print_message "$GREEN" "✅ All volumes restored successfully!"
    exit_code=0
fi

# Offer to start containers
if [ "$exit_code" -eq 0 ]; then
    echo
    if [ "$FORCE" != true ]; then
        read -p "Start containers now? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            print_message "$YELLOW" "🚀 Starting containers..."
            docker-compose -f docker-compose.coolify.yaml up -d
            
            # Wait for containers to be healthy
            print_message "$YELLOW" "⏳ Waiting for containers to be healthy..."
            sleep 10
            
            # Check container status
            if docker ps | grep -q "open-webui.*healthy"; then
                print_message "$GREEN" "✅ Containers are running and healthy!"
            else
                print_message "$YELLOW" "⚠️  Containers are starting. Check status with: docker ps"
            fi
        fi
    fi
fi

exit $exit_code
