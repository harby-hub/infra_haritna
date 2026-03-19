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
INFRA_DIR="$BASE_DIR/infra_haritna/production/dukkan"
COMPOSE="docker compose -f $INFRA_DIR/docker-compose.yml"

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

# --- Copy env files ---
echo "==> Syncing env files..."

# .dockerignore
cp "$INFRA_DIR/.dockerignore" "$BASE_DIR/.dockerignore"

# Backend .env — copy template then inject secrets from main .env
if [ ! -f "$BASE_DIR/backend_dukkan/.env" ]; then
    cp "$INFRA_DIR/envs/backend.env" "$BASE_DIR/backend_dukkan/.env"
    echo "    Created backend_dukkan/.env from template"
fi

# Inject secrets from main .env into backend .env
if [ -f "$BASE_DIR/.env" ]; then
    # Read secrets from main .env and update backend .env
    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        # Only update if key exists in backend .env and value is empty there
        if grep -q "^${key}=$" "$BASE_DIR/backend_dukkan/.env" 2>/dev/null; then
            sed -i "s|^${key}=$|${key}=${value}|" "$BASE_DIR/backend_dukkan/.env"
        fi
    done < "$BASE_DIR/.env"
    echo "    Injected secrets into backend_dukkan/.env"
fi

# Frontend .env
cp "$INFRA_DIR/envs/frontend.env" "$BASE_DIR/frontend_dukkan/.env"
echo "    Copied frontend_dukkan/.env"

# Passport keys
cp "$INFRA_DIR/keys/oauth-private.key" "$BASE_DIR/backend_dukkan/storage/oauth-private.key"
cp "$INFRA_DIR/keys/oauth-public.key" "$BASE_DIR/backend_dukkan/storage/oauth-public.key"
chmod 600 "$BASE_DIR/backend_dukkan/storage/oauth-private.key" "$BASE_DIR/backend_dukkan/storage/oauth-public.key"
echo "    Copied Passport keys"

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
    echo "==> Copying .env into containers..."
    for svc in backend queue-worker scheduler; do
        docker cp "$BASE_DIR/backend_dukkan/.env" "$($COMPOSE ps -q $svc)":/var/www/.env 2>/dev/null || true
    done

    echo "==> Running migrations..."
    $COMPOSE exec -T backend php artisan migrate --force
    $COMPOSE exec -T backend php artisan tenants:migrate --force

    echo "==> Caching config and routes..."
    $COMPOSE exec -T backend php artisan config:cache
    $COMPOSE exec -T backend php artisan route:cache
    $COMPOSE exec -T backend php artisan view:cache
    $COMPOSE exec -T backend php artisan storage:link 2>/dev/null || true

    echo "==> Restarting queue worker and nginx..."
    $COMPOSE restart queue-worker nginx
fi

# --- SSL auto-renewal cron ---
SSL_CRON="0 3 */15 * * bash /opt/dukkan/infra_haritna/production/dukkan/scripts/ssl-renew.sh"
if ! crontab -l 2>/dev/null | grep -qF "ssl-renew.sh"; then
    (crontab -l 2>/dev/null; echo "$SSL_CRON") | crontab -
    echo "==> SSL renewal cron job installed (every 15 days at 3 AM)"
else
    echo "==> SSL renewal cron job already exists"
fi

echo ""
echo "==> Deploy complete! ($TARGET)"
echo ""
$COMPOSE ps
