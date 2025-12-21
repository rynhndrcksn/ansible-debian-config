#!/usr/bin/env bash
# Attempts to renew the SSL certificate for the given domain.
# Primarily to be used in a cron job like so:
# Daily at 2:30 AM (staggered to avoid LE rate limits)
# 30 2 * * * /path/to/nginx-cert-renew.sh domain1.com >> /var/log/nginx-cert-renew.log 2>&1
# 35 2 * * * /path/to/nginx-cert-renew.sh domain2.com >> /var/log/nginx-cert-renew.log 2>&1

set -e

DOMAIN="$1"
if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <domain.com>"
    echo "Example: $0 example.com"
    exit 1
fi

echo "🔄 Renewing SSL certificates for $DOMAIN..."

# Check if certificate exists
if [ ! -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    echo "❌ Certificate for $DOMAIN not found at /etc/letsencrypt/live/$DOMAIN"
    echo "Run './nginx-cert-setup.sh $DOMAIN' first to generate initial certs"
    exit 1
fi

# Test renewal first (dry-run)
echo "🔍 Testing renewal (dry-run)..."
if sudo certbot renew --dry-run --cert-name "$DOMAIN" 2>/dev/null; then
    echo "✅ Dry-run passed, proceeding with actual renewal..."
else
    echo "ℹ️  Certificate doesn't need renewal yet (dry-run failed as expected)"
    exit 0
fi

# Force renewal for this specific domain
echo "🔓 Force renewing certificate for $DOMAIN..."
sudo certbot renew --force-renewal --cert-name "$DOMAIN" --quiet

# Reload nginx to pick up new certs
echo "🔄 Reloading nginx..."
if sudo nginx -t; then
    sudo systemctl reload nginx
    echo "✅ Nginx reloaded successfully"
else
    echo "❌ Nginx config test failed after renewal"
    exit 1
fi

echo "🎉 Certificate renewal complete for $DOMAIN!"
echo "   New cert: /etc/letsencrypt/live/$DOMAIN/fullchain.pem"

