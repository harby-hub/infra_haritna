#!/bin/bash
set -euo pipefail

# ============================================
# Dukkan — Deploy / Redeploy Script
# ============================================

BASE_DIR="/opt/dukkan"

cd "$BASE_DIR"

echo "==> Pulling latest code..."
cd backend_dukkan && git pull && cd ..
cd frontend_dukkan && git pull && cd ..
cd infra_haritna && git pull && cd ..

echo "==> Building and starting containers..."
docker compose -f infra_haritna/production/dukkan/docker-compose.yml up -d --build

echo "==> Waiting for containers to be ready..."
sleep 5

echo "==> Running migrations..."
docker compose -f infra_haritna/production/dukkan/docker-compose.yml exec -T backend php artisan migrate --force
docker compose -f infra_haritna/production/dukkan/docker-compose.yml exec -T backend php artisan tenants:migrate --force

echo "==> Caching config and routes..."
docker compose -f infra_haritna/production/dukkan/docker-compose.yml exec -T backend php artisan config:cache
docker compose -f infra_haritna/production/dukkan/docker-compose.yml exec -T backend php artisan route:cache
docker compose -f infra_haritna/production/dukkan/docker-compose.yml exec -T backend php artisan view:cache
docker compose -f infra_haritna/production/dukkan/docker-compose.yml exec -T backend php artisan storage:link 2>/dev/null || true

echo "==> Restarting queue worker..."
docker compose -f infra_haritna/production/dukkan/docker-compose.yml restart queue-worker

echo ""
echo "==> Deploy complete!"
echo ""
docker compose -f infra_haritna/production/dukkan/docker-compose.yml ps
