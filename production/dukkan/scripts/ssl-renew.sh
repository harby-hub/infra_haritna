#!/bin/bash
set -euo pipefail

# ============================================
# Dukkan — SSL Certificate Renewal
# Cron: 0 3 */15 * *  (every 15 days at 3 AM)
# ============================================

COMPOSE="docker compose -f /opt/dukkan/infra_haritna/production/dukkan/docker-compose.yml"
LOG="/var/log/dukkan-ssl-renew.log"

echo "[$(date)] Starting SSL renewal..." >> "$LOG"

if $COMPOSE run --rm certbot >> "$LOG" 2>&1; then
    $COMPOSE exec -T nginx nginx -s reload >> "$LOG" 2>&1
    echo "[$(date)] SSL renewal complete." >> "$LOG"
else
    echo "[$(date)] SSL renewal failed!" >> "$LOG"
    exit 1
fi
