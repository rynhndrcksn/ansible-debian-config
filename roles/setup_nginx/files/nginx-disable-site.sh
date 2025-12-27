#!/usr/bin/env bash
# Remove a symlink for the provided domain.

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

# Check if target exists
if [ ! -e "$TARGET" ]; then
    echo -e "${YELLOW}Warning: Site is not enabled: ${DOMAIN}${NC}"
    echo "Currently enabled sites:"
    ls -1 "$SITES_ENABLED" 2>/dev/null || echo "  (none found)"
    exit 0
fi

# Check if target is actually a symlink
if [ ! -L "$TARGET" ]; then
    echo -e "${RED}Error: Target exists but is not a symlink: ${TARGET}${NC}"
    echo "This may be a regular file that should be reviewed manually"
    exit 1
fi

# Verify it points to sites-available (optional safety check)
ACTUAL_SOURCE=$(readlink -f "$TARGET")
if [[ "$ACTUAL_SOURCE" != "$SITES_AVAILABLE"* ]]; then
    echo -e "${YELLOW}Warning: Symlink points outside sites-available: ${ACTUAL_SOURCE}${NC}"
    read -p "Remove anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted"
        exit 1
    fi
fi

# Remove symlink
if rm "$TARGET"; then
    echo -e "${GREEN}✓ Successfully disabled site: ${DOMAIN}${NC}"
    echo "  Removed: $TARGET"
    if [ -f "$SOURCE" ]; then
        echo "  Configuration still available at: $SOURCE"
    fi
else
    echo -e "${RED}Error: Failed to remove symlink${NC}"
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
    echo -e "${YELLOW}Note: This may indicate issues with other enabled sites${NC}"
    exit 1
fi
