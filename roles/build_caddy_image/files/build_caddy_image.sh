#!/usr/bin/env bash
set -euo pipefail

podman build --dns=8.8.8.8 -t caddy-custom -f /srv/caddy/Dockerfile.caddy /srv/caddy
sudo systemctl restart caddy.service

