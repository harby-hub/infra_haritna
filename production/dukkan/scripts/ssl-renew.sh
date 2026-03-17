#!/bin/bash
set -euo pipefail

# ============================================
# Renew Let's Encrypt wildcard certificate
# Run via cron: 0 3 1 * * bash /opt/dukkan/infra_haritna/production/dukkan/scripts/ssl-renew.sh
# ============================================

COMPOSE="docker compose -f /opt/dukkan/infra_haritna/production/dukkan/docker-compose.yml"

echo "==> Renewing SSL certificate..."
$COMPOSE run --rm certbot

echo "==> Reloading nginx..."
$COMPOSE exec -T nginx nginx -s reload

echo "==> SSL renewal complete!"
