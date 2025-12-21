#!/usr/bin/env bash
# Handles the initial certbot setup for a single domain.

set -e

DOMAIN="$1"
if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <domain.com>"
    echo "Example: $0 example.com"
    exit 1
fi

echo "🔄 Setting up SSL certs and cache for $DOMAIN..."

# Create cache directory
CACHE_DIR="/var/cache/nginx/$DOMAIN"
sudo mkdir -p "$CACHE_DIR"
sudo chown www-data:www-data "$CACHE_DIR"
sudo chmod 0755 "$CACHE_DIR"
echo "✅ Created cache directory $CACHE_DIR"

# Generate SSL certificates with certbot
echo "🔓 Generating SSL certificates for $DOMAIN..."
sudo certbot --nginx -d "$DOMAIN"

# Remove default site if it exists
if [ -L "/etc/nginx/sites-enabled/default" ]; then
    sudo rm "/etc/nginx/sites-enabled/default"
    echo "✅ Removed default site"
fi

# Test and reload nginx
echo "🔍 Testing nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx config test passed"
    echo "🔄 Reloading nginx..."
    sudo systemctl reload nginx
    echo "✅ Nginx reloaded successfully"

    echo ""
    echo "🎉 Setup complete for $DOMAIN!"
    echo "   Cache: $CACHE_DIR"
    echo "   Certs: /etc/letsencrypt/live/$DOMAIN/"
else
    echo "❌ Nginx config test failed"
    exit 1
fi

