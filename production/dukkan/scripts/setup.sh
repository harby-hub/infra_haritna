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

echo "==> Setting up .env..."
if [ ! -f ".env" ]; then
    cp infra_haritna/.env.example .env
    echo ""
    echo "!!! IMPORTANT: Edit /opt/dukkan/.env with your production secrets !!!"
    echo "    nano /opt/dukkan/.env"
    echo ""
else
    echo ".env already exists, skipping."
fi

echo ""
echo "=========================================="
echo "  Setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Edit /opt/dukkan/.env with your production secrets"
echo "  2. Run: cd /opt/dukkan && bash infra_haritna/scripts/deploy.sh"
