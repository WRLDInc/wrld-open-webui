#!/bin/bash

# Volume Initialization Script for Coolify Deployment
# This script ensures proper permissions and initial setup for persistent volumes

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

# Default user and group IDs
USER_ID=${USER_ID:-1000}
GROUP_ID=${GROUP_ID:-1000}

# Function to create and set permissions for a directory
init_directory() {
    local container_name=$1
    local path=$2
    local owner_uid=${3:-$USER_ID}
    local owner_gid=${4:-$GROUP_ID}
    local permissions=${5:-755}
    
    print_message "$YELLOW" "📁 Initializing directory: $path"
    
    # Create directory if it doesn't exist
    docker exec $container_name mkdir -p "$path" 2>/dev/null || true
    
    # Set ownership
    docker exec $container_name chown -R ${owner_uid}:${owner_gid} "$path" 2>/dev/null || true
    
    # Set permissions
    docker exec $container_name chmod -R $permissions "$path" 2>/dev/null || true
    
    print_message "$GREEN" "✅ Directory initialized: $path (${owner_uid}:${owner_gid}, ${permissions})"
}

# Function to check volume mount
check_volume() {
    local volume_name=$1
    
    if docker volume ls | grep -q "$volume_name"; then
        print_message "$GREEN" "✅ Volume exists: $volume_name"
        
        # Get volume info
        volume_path=$(docker volume inspect $volume_name --format '{{ .Mountpoint }}' 2>/dev/null || echo "N/A")
        print_message "$BLUE" "   Mount point: $volume_path"
        
        return 0
    else
        print_message "$RED" "❌ Volume not found: $volume_name"
        return 1
    fi
}

# Function to initialize Open WebUI volumes
init_webui_volumes() {
    local container_name="open-webui"
    
    print_message "$BLUE" "🔧 Initializing Open WebUI volumes..."
    
    # Check if container is running
    if ! docker ps | grep -q "$container_name"; then
        print_message "$YELLOW" "⚠️  Container $container_name is not running. Starting temporarily..."
        docker run -d --name temp-init \
            -v open-webui-data:/app/backend/data \
            -v open-webui-cache:/app/backend/data/cache \
            -v open-webui-models:/app/backend/data/models \
            alpine:latest sleep 3600
        container_name="temp-init"
    fi
    
    # Initialize main data directory
    init_directory "$container_name" "/app/backend/data" $USER_ID $GROUP_ID 770
    
    # Initialize subdirectories
    local subdirs=(
        "/app/backend/data/cache"
        "/app/backend/data/models"
        "/app/backend/data/uploads"
        "/app/backend/data/vector_db"
        "/app/backend/data/logs"
        "/app/backend/data/config"
    )
    
    for dir in "${subdirs[@]}"; do
        init_directory "$container_name" "$dir" $USER_ID $GROUP_ID 770
    done
    
    # Clean up temporary container if created
    if [ "$container_name" = "temp-init" ]; then
        docker rm -f temp-init > /dev/null 2>&1
    fi
}

# Function to initialize Ollama volume
init_ollama_volume() {
    local container_name="ollama"
    
    print_message "$BLUE" "🔧 Initializing Ollama volume..."
    
    # Check if container is running
    if ! docker ps | grep -q "$container_name"; then
        print_message "$YELLOW" "⚠️  Container $container_name is not running. Starting temporarily..."
        docker run -d --name temp-ollama \
            -v ollama:/root/.ollama \
            alpine:latest sleep 3600
        container_name="temp-ollama"
    fi
    
    # Ollama runs as root, so use root permissions
    init_directory "$container_name" "/root/.ollama" 0 0 755
    init_directory "$container_name" "/root/.ollama/models" 0 0 755
    init_directory "$container_name" "/root/.ollama/logs" 0 0 755
    
    # Clean up temporary container if created
    if [ "$container_name" = "temp-ollama" ]; then
        docker rm -f temp-ollama > /dev/null 2>&1
    fi
}

# Function to create initial configuration files
create_initial_configs() {
    print_message "$BLUE" "📝 Creating initial configuration files..."
    
    # Create a temporary container to write config files
    docker run -d --name temp-config \
        -v open-webui-data:/app/backend/data \
        alpine:latest sleep 3600
    
    # Create initial config.json if it doesn't exist
    docker exec temp-config sh -c "
        if [ ! -f /app/backend/data/config/config.json ]; then
            cat > /app/backend/data/config/config.json <<EOF
{
    \"version\": \"1.0.0\",
    \"initialized\": true,
    \"deployment\": \"coolify\",
    \"features\": {
        \"auth\": true,
        \"rag\": true,
        \"web_search\": true,
        \"image_generation\": false
    }
}
EOF
            chown ${USER_ID}:${GROUP_ID} /app/backend/data/config/config.json
            chmod 644 /app/backend/data/config/config.json
        fi
    "
    
    # Clean up
    docker rm -f temp-config > /dev/null 2>&1
    
    print_message "$GREEN" "✅ Configuration files created"
}

# Function to verify volume setup
verify_setup() {
    print_message "$BLUE" "🔍 Verifying volume setup..."
    
    local all_good=true
    
    # Check each volume
    for volume in ollama open-webui-data open-webui-cache open-webui-models; do
        if ! check_volume "$volume"; then
            all_good=false
        fi
    done
    
    if [ "$all_good" = true ]; then
        print_message "$GREEN" "✅ All volumes verified successfully"
    else
        print_message "$RED" "❌ Some volumes are missing. Please check your Docker Compose configuration."
        return 1
    fi
}

# Function to display volume usage
show_volume_usage() {
    print_message "$BLUE" "📊 Volume Usage Report:"
    echo
    
    for volume in ollama open-webui-data open-webui-cache open-webui-models; do
        if docker volume ls | grep -q "$volume"; then
            print_message "$YELLOW" "Volume: $volume"
            docker run --rm -v ${volume}:/data:ro alpine df -h /data 2>/dev/null | tail -1 | awk '{printf "  Size: %s, Used: %s, Available: %s, Usage: %s\n", $2, $3, $4, $5}'
        fi
    done
}

# Main execution
print_message "$GREEN" "========================================="
print_message "$GREEN" "    Volume Initialization Script"
print_message "$GREEN" "========================================="
echo

# Check Docker availability
if ! command -v docker &> /dev/null; then
    print_message "$RED" "❌ Docker is not installed or not in PATH"
    exit 1
fi

# Parse command line arguments
case "${1:-}" in
    --verify)
        verify_setup
        show_volume_usage
        exit $?
        ;;
    --help)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --verify    Only verify existing setup"
        echo "  --help      Display this help message"
        echo ""
        echo "Environment variables:"
        echo "  USER_ID     User ID for file ownership (default: 1000)"
        echo "  GROUP_ID    Group ID for file ownership (default: 1000)"
        exit 0
        ;;
esac

print_message "$YELLOW" "🔄 Starting volume initialization..."
echo

# Create volumes if they don't exist
print_message "$BLUE" "📦 Creating volumes if needed..."
docker volume create ollama 2>/dev/null || true
docker volume create open-webui-data 2>/dev/null || true
docker volume create open-webui-cache 2>/dev/null || true
docker volume create open-webui-models 2>/dev/null || true
echo

# Verify volumes exist
verify_setup || exit 1
echo

# Initialize volumes
init_webui_volumes
echo
init_ollama_volume
echo

# Create initial configuration
create_initial_configs
echo

# Show final status
print_message "$GREEN" "========================================="
print_message "$GREEN" "         Initialization Complete"
print_message "$GREEN" "========================================="
echo

show_volume_usage
echo

print_message "$GREEN" "✅ All volumes have been initialized with proper permissions!"
print_message "$YELLOW" "📌 Next steps:"
print_message "$YELLOW" "   1. Start your containers: docker-compose -f docker-compose.coolify.yaml up -d"
print_message "$YELLOW" "   2. Set up regular backups: ./scripts/backup-volumes.sh"
print_message "$YELLOW" "   3. Monitor volume usage regularly"

exit 0
