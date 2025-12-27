#!/usr/bin/env bash
# Creates a symlink for the provided domain.

set -euo pipefail

# Configuration
SITES_AVAILABLE="/etc/nginx/sites-available"
SITES_ENABLED="/etc/nginx/sites-enabled"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Display usage information
usage() {
    echo "Usage: $0 <domain>"
    echo "Example: $0 example.com"
    exit 1
}

# Check if domain argument is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No domain specified${NC}"
    usage
fi

DOMAIN="$1"
SOURCE="${SITES_AVAILABLE}/${DOMAIN}"
TARGET="${SITES_ENABLED}/${DOMAIN}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
    exit 1
fi

# Check if source configuration exists
if [ ! -f "$SOURCE" ]; then
    echo -e "${RED}Error: Configuration file does not exist: ${SOURCE}${NC}"
    echo "Available configurations:"
    ls -1 "$SITES_AVAILABLE" 2>/dev/null || echo "  (none found)"
    exit 1
fi

# Check if symlink already exists
if [ -L "$TARGET" ]; then
    EXISTING_TARGET=$(readlink -f "$TARGET")
    if [ "$EXISTING_TARGET" = "$SOURCE" ]; then
        echo -e "${YELLOW}Warning: Symlink already exists and points to correct location${NC}"
        exit 0
    else
        echo -e "${YELLOW}Warning: Symlink exists but points to: ${EXISTING_TARGET}${NC}"
        read -p "Remove existing symlink and recreate? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted"
            exit 1
        fi
        rm "$TARGET"
    fi
elif [ -e "$TARGET" ]; then
    echo -e "${RED}Error: Target exists but is not a symlink: ${TARGET}${NC}"
    exit 1
fi

# Create symlink
if ln -s "$SOURCE" "$TARGET"; then
    echo -e "${GREEN}✓ Successfully enabled site: ${DOMAIN}${NC}"
    echo "  Source: $SOURCE"
    echo "  Target: $TARGET"
else
    echo -e "${RED}Error: Failed to create symlink${NC}"
    exit 1
fi

# Test nginx configuration
echo ""
echo "Testing nginx configuration..."
if nginx -t 2>&1 | grep -q "test is successful"; then
    echo -e "${GREEN}✓ Nginx configuration test passed${NC}"
    echo ""
    echo "To apply changes, run:"
    echo "  systemctl reload nginx"
else
    echo -e "${RED}✗ Nginx configuration test failed${NC}"
    echo "Removing symlink..."
    rm "$TARGET"
    echo "Please fix configuration errors before enabling this site"
    exit 1
fi
