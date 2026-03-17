#!/bin/bash
set -euo pipefail

# ============================================
# Dukkan — VPS Initial Setup Script
# Contabo VPS S — Ubuntu 24.04
# ============================================

echo "==> Updating system..."
apt update && apt upgrade -y

echo "==> Installing essentials..."
apt install -y git curl ufw

echo "==> Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    echo "Docker installed successfully."
else
    echo "Docker already installed."
fi

echo "==> Configuring firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
echo "Firewall configured."

echo "==> Creating app directory..."
mkdir -p /opt/dukkan
cd /opt/dukkan

echo "==> Cloning repositories..."
if [ ! -d "infra_haritna" ]; then
    git clone git@github.com:harby-hub/infra_haritna.git
fi
if [ ! -d "backend_dukkan" ]; then
    git clone git@github.com:harby-hub/backend_dukkan.git
fi
if [ ! -d "frontend_dukkan" ]; then
    git clone git@github.com:harby-hub/frontend_dukkan.git
fi

echo "==> Copying .dockerignore to build context..."
cp infra_haritna/production/dukkan/.dockerignore .dockerignore

echo "==> Setting up .env files..."
ENVS_DIR="infra_haritna/production/dukkan/envs"

if [ ! -f ".env" ]; then
    cp infra_haritna/production/dukkan/.env.example .env
fi
if [ ! -f "backend_dukkan/.env" ]; then
    cp "$ENVS_DIR/backend.env" backend_dukkan/.env
fi
if [ ! -f "frontend_dukkan/.env" ]; then
    cp "$ENVS_DIR/frontend.env" frontend_dukkan/.env
fi

echo ""
echo "=========================================="
echo "  Setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Fill in secrets:"
echo "     nano /opt/dukkan/.env"
echo "     nano /opt/dukkan/backend_dukkan/.env"
echo "  2. Run: cd /opt/dukkan && bash infra_haritna/production/dukkan/scripts/deploy.sh"
