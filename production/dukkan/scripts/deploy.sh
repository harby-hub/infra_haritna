#!/bin/bash
set -euo pipefail

# ============================================
# Dukkan — Deploy / Redeploy Script
# Usage:
#   bash deploy.sh              # deploy all
#   bash deploy.sh backend      # deploy backend only
#   bash deploy.sh frontend     # deploy frontend only
#   bash deploy.sh infra        # deploy infra only
# ============================================

BASE_DIR="/opt/dukkan"
COMPOSE="docker compose -f $BASE_DIR/infra_haritna/production/dukkan/docker-compose.yml"

cd "$BASE_DIR"

TARGET="${1:-all}"

# --- Pull ---
echo "==> Pulling latest code..."
if [ "$TARGET" = "all" ] || [ "$TARGET" = "infra" ]; then
    cd infra_haritna && git pull && cd ..
fi
if [ "$TARGET" = "all" ] || [ "$TARGET" = "backend" ]; then
    cd backend_dukkan && git pull && cd ..
fi
if [ "$TARGET" = "all" ] || [ "$TARGET" = "frontend" ]; then
    cd frontend_dukkan && git pull && cd ..
fi

# --- Build ---
echo "==> Building and starting containers..."
if [ "$TARGET" = "all" ]; then
    $COMPOSE up -d --build
elif [ "$TARGET" = "backend" ]; then
    $COMPOSE up -d --build backend queue-worker scheduler
elif [ "$TARGET" = "frontend" ]; then
    $COMPOSE up -d --build frontend
elif [ "$TARGET" = "infra" ]; then
    $COMPOSE up -d --build nginx
fi

echo "==> Waiting for containers to be ready..."
sleep 5

# --- Backend post-deploy ---
if [ "$TARGET" = "all" ] || [ "$TARGET" = "backend" ]; then
    echo "==> Running migrations..."
    $COMPOSE exec -T backend php artisan migrate --force
    $COMPOSE exec -T backend php artisan tenants:migrate --force

    echo "==> Caching config and routes..."
    $COMPOSE exec -T backend php artisan config:cache
    $COMPOSE exec -T backend php artisan route:cache
    $COMPOSE exec -T backend php artisan view:cache
    $COMPOSE exec -T backend php artisan storage:link 2>/dev/null || true

    echo "==> Restarting queue worker..."
    $COMPOSE restart queue-worker
fi

echo ""
echo "==> Deploy complete! ($TARGET)"
echo ""
$COMPOSE ps
