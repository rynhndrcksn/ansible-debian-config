#!/usr/bin/env bash
# Handles the initial certbot setup for a single domain.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CACHE_BASE_DIR="/var/cache/nginx"
LETSENCRYPT_DIR="/etc/letsencrypt/live"

# Display usage information
usage() {
    echo "Usage: $0 <domain> [options]"
    echo ""
    echo "Options:"
    echo "  -e, --email EMAIL    Email address for Let's Encrypt notifications"
    echo "  -w, --webroot PATH   Use webroot mode instead of nginx plugin"
    echo ""
    echo "Example: $0 example.com"
    echo "Example: $0 example.com --email admin@example.com"
    exit 1
}

# Parse arguments
EMAIL=""
WEBROOT=""
DOMAIN=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--email)
            EMAIL="$2"
            shift 2
            ;;
        -w|--webroot)
            WEBROOT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            if [ -z "$DOMAIN" ]; then
                DOMAIN="$1"
            else
                echo -e "${RED}Error: Unknown argument: $1${NC}"
                usage
            fi
            shift
            ;;
    esac
done

# Validate domain argument
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Error: No domain specified${NC}"
    usage
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
    exit 1
fi

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    echo -e "${RED}Error: certbot is not installed${NC}"
    echo "Install with: apt install certbot python3-certbot-nginx"
    exit 1
fi

# Check if nginx is installed and running
if ! command -v nginx &> /dev/null; then
    echo -e "${RED}Error: nginx is not installed${NC}"
    exit 1
fi

if ! systemctl is-active --quiet nginx; then
    echo -e "${YELLOW}Warning: nginx is not running${NC}"
    read -p "Start nginx now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl start nginx
    else
        echo "Aborted"
        exit 1
    fi
fi

# Check if certificate already exists
CERT_PATH="${LETSENCRYPT_DIR}/${DOMAIN}"
if [ -d "$CERT_PATH" ]; then
    echo -e "${YELLOW}Warning: Certificate already exists for ${DOMAIN}${NC}"
    echo "Certificate location: $CERT_PATH"
    read -p "Continue and renew/reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted"
        exit 0
    fi
fi

echo "Setting up SSL certificates and cache for ${DOMAIN}..."
echo ""

# Create cache directory
CACHE_DIR="${CACHE_BASE_DIR}/${DOMAIN}"
echo "Creating cache directory..."
if mkdir -p "$CACHE_DIR"; then
    chown www-data:www-data "$CACHE_DIR"
    chmod 0755 "$CACHE_DIR"
    echo -e "${GREEN}✓ Created cache directory: ${CACHE_DIR}${NC}"
else
    echo -e "${RED}Error: Failed to create cache directory${NC}"
    exit 1
fi

# Build certbot command
CERTBOT_CMD="certbot"
CERTBOT_ARGS=()

if [ -n "$WEBROOT" ]; then
    # Webroot mode
    if [ ! -d "$WEBROOT" ]; then
        echo -e "${RED}Error: Webroot directory does not exist: ${WEBROOT}${NC}"
        exit 1
    fi
    CERTBOT_ARGS+=("certonly" "--webroot" "-w" "$WEBROOT")
else
    # Nginx plugin mode
    CERTBOT_ARGS+=("--nginx")
fi

CERTBOT_ARGS+=("-d" "$DOMAIN")

if [ -n "$EMAIL" ]; then
    CERTBOT_ARGS+=("--email" "$EMAIL" "--agree-tos")
else
    CERTBOT_ARGS+=("--register-unsafely-without-email" "--agree-tos")
fi

# Non-interactive mode
CERTBOT_ARGS+=("--non-interactive")

# Generate SSL certificates with certbot
echo ""
echo "Generating SSL certificates for ${DOMAIN}..."
if $CERTBOT_CMD "${CERTBOT_ARGS[@]}"; then
    echo -e "${GREEN}✓ SSL certificates generated successfully${NC}"
else
    echo -e "${RED}Error: Failed to generate SSL certificates${NC}"
    echo ""
    echo "Common issues:"
    echo "  - Domain DNS not pointing to this server"
    echo "  - Port 80/443 not accessible"
    echo "  - Nginx configuration errors"
    echo "  - Rate limiting (Let's Encrypt has limits)"
    exit 1
fi

# Test nginx configuration
echo ""
echo "Testing nginx configuration..."
if nginx -t 2>&1 | grep -q "test is successful"; then
    echo -e "${GREEN}✓ Nginx configuration test passed${NC}"

    echo ""
    echo "Reloading nginx..."
    if systemctl reload nginx; then
        echo -e "${GREEN}✓ Nginx reloaded successfully${NC}"
    else
        echo -e "${RED}Error: Failed to reload nginx${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Nginx configuration test failed${NC}"
    echo "Certificate was generated but nginx configuration has errors"
    exit 1
fi

# Display summary
echo ""
echo -e "${GREEN}Setup complete for ${DOMAIN}!${NC}"
echo "  Cache directory: $CACHE_DIR"
echo "  Certificate: ${CERT_PATH}/fullchain.pem"
echo "  Private key: ${CERT_PATH}/privkey.pem"
echo ""
echo "Certificate will auto-renew via certbot timer"
echo "Check renewal status: certbot renew --dry-run"
