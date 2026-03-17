#!/bin/bash
set -euo pipefail

# ============================================
# Dukkan — Deploy / Redeploy Script
# Run from anywhere: bash /opt/dukkan/dukkan-infra/scripts/deploy.sh
# ============================================

BASE_DIR="/opt/dukkan"

cd "$BASE_DIR"

echo "==> Pulling latest code..."
cd dukkan-backend && git pull && cd ..
cd dukkan-frontend && git pull && cd ..
cd dukkan-infra && git pull

echo "==> Building and starting containers..."
# docker-compose.yml is in dukkan-infra/
docker compose -f dukkan-infra/docker-compose.yml up -d --build

echo "==> Waiting for containers to be ready..."
sleep 5

echo "==> Running migrations..."
docker compose -f dukkan-infra/docker-compose.yml exec -T backend php artisan migrate --force
docker compose -f dukkan-infra/docker-compose.yml exec -T backend php artisan tenants:migrate --force

echo "==> Caching config and routes..."
docker compose -f dukkan-infra/docker-compose.yml exec -T backend php artisan config:cache
docker compose -f dukkan-infra/docker-compose.yml exec -T backend php artisan route:cache
docker compose -f dukkan-infra/docker-compose.yml exec -T backend php artisan view:cache
docker compose -f dukkan-infra/docker-compose.yml exec -T backend php artisan storage:link 2>/dev/null || true

echo "==> Restarting queue worker..."
docker compose -f dukkan-infra/docker-compose.yml restart queue-worker

echo ""
echo "==> Deploy complete!"
echo ""
docker compose -f dukkan-infra/docker-compose.yml ps
