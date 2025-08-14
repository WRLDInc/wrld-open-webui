#!/bin/bash

# Coolify Configuration Validation Script
# This script checks if your Docker configuration is ready for Coolify deployment

echo "========================================="
echo "Coolify Configuration Validation"
echo "========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validation counters
ERRORS=0
WARNINGS=0

# Function to check if file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $2 found"
        return 0
    else
        echo -e "${RED}✗${NC} $2 not found"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Function to check for required labels in docker-compose
check_labels() {
    if grep -q "coolify.managed" "$1" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Coolify labels found in $1"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} No Coolify labels found in $1 (using standard compose)"
        WARNINGS=$((WARNINGS + 1))
        return 1
    fi
}

# Function to check port configuration
check_ports() {
    if grep -q "3000:8080" "$1" 2>/dev/null || grep -q "OPEN_WEBUI_PORT" "$1" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Port mapping configured correctly"
        return 0
    else
        echo -e "${RED}✗${NC} Port mapping issue detected"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Function to check volumes
check_volumes() {
    if grep -q "volumes:" "$1" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Volume configuration found"
        return 0
    else
        echo -e "${RED}✗${NC} No volume configuration found"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Function to check health checks
check_healthcheck() {
    if grep -q "healthcheck" "$1" 2>/dev/null || grep -q "/health" "$1" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Health check configuration found"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} No health check configuration found (recommended for Coolify)"
        WARNINGS=$((WARNINGS + 1))
        return 1
    fi
}

echo "1. Checking required files..."
echo "------------------------------"
check_file "docker-compose.coolify.yaml" "Coolify Docker Compose file"
check_file ".env.coolify" "Coolify environment template"
check_file "Dockerfile" "Dockerfile"
check_file "COOLIFY_DEPLOYMENT.md" "Deployment documentation"
echo ""

echo "2. Checking Coolify-specific configuration..."
echo "----------------------------------------------"
if [ -f "docker-compose.coolify.yaml" ]; then
    check_labels "docker-compose.coolify.yaml"
    check_ports "docker-compose.coolify.yaml"
    check_volumes "docker-compose.coolify.yaml"
    check_healthcheck "docker-compose.coolify.yaml"
else
    echo -e "${RED}✗${NC} Cannot validate - docker-compose.coolify.yaml not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

echo "3. Checking environment configuration..."
echo "-----------------------------------------"
if [ -f ".env.coolify" ]; then
    if grep -q "WEBUI_SECRET_KEY=" ".env.coolify" 2>/dev/null; then
        if grep -q "WEBUI_SECRET_KEY=$" ".env.coolify" 2>/dev/null || grep -q "WEBUI_SECRET_KEY= *$" ".env.coolify" 2>/dev/null; then
            echo -e "${YELLOW}⚠${NC} WEBUI_SECRET_KEY is empty - remember to generate one for production"
            WARNINGS=$((WARNINGS + 1))
        else
            echo -e "${GREEN}✓${NC} WEBUI_SECRET_KEY configured"
        fi
    fi
    
    if grep -q "OPEN_WEBUI_PORT" ".env.coolify" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Port configuration found in environment"
    else
        echo -e "${YELLOW}⚠${NC} No port configuration in environment file"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠${NC} .env.coolify not found - using defaults"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

echo "4. Checking Docker images..."
echo "-----------------------------"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker is installed"
    
    # Check if we can pull the images (optional)
    echo -e "${YELLOW}ℹ${NC} Note: Coolify will pull images during deployment"
else
    echo -e "${YELLOW}⚠${NC} Docker not found locally (OK if validating before deployment)"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

echo "========================================="
echo "Validation Summary"
echo "========================================="

if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✓ Configuration is ready for Coolify deployment!${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Copy .env.coolify to .env and configure your values"
        echo "2. Generate a secret key: openssl rand -hex 32"
        echo "3. Push to your Git repository"
        echo "4. Configure in Coolify using docker-compose.coolify.yaml"
    else
        echo -e "${YELLOW}⚠ Configuration is ready with $WARNINGS warning(s)${NC}"
        echo ""
        echo "Review the warnings above and proceed with deployment."
        echo "Most warnings are optional optimizations."
    fi
    exit 0
else
    echo -e "${RED}✗ Configuration has $ERRORS error(s) that need to be fixed${NC}"
    echo ""
    echo "Please fix the errors above before deploying to Coolify."
    exit 1
fi
