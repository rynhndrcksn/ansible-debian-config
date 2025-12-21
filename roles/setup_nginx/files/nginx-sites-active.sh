#!/usr/bin/env bash
# Iterates over the Nginx configurations in /etc/nginx/sites-available
# and symlinks them to /etc/nginx/sites-enabled

set -e

echo "🔄 Activating nginx sites and reloading..."

# Ensure sites-available has files
if [ ! "$(ls -A /etc/nginx/sites-available)" ]; then
    echo "❌ No sites found in /etc/nginx/sites-available"
    exit 1
fi

# Symlink all sites from sites-available to sites-enabled
for site in /etc/nginx/sites-available/*; do
    site_name=$(basename "$site")

    # Remove existing symlink if present
    if [ -L "/etc/nginx/sites-enabled/$site_name" ]; then
        rm "/etc/nginx/sites-enabled/$site_name"
    fi

    # Create symlink
    ln -s "../sites-available/$site_name" "/etc/nginx/sites-enabled/$site_name"
    echo "✅ Symlinked $site_name"
done

# Test nginx config
echo "🔍 Testing nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx config test passed"
    echo "🔄 Reloading nginx..."
    sudo systemctl reload nginx
    echo "✅ Nginx reloaded successfully"
else
    echo "❌ Nginx config test failed. Please check your config files."
    exit 1
fi

