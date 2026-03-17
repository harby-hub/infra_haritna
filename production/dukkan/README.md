# Dukkan Infrastructure

Docker + Nginx + deploy configs for the Dukkan platform.

## Architecture

```
nginx (ports 80/443)
  ├── dukkan-api.haritna.net   → backend:9000 (PHP-FPM)    [Cloudflare Proxy]
  ├── dukkan-app.haritna.net   → frontend:3000 (Bun SSR)   [Cloudflare Proxy]
  └── *.dukkan.haritna.net     → backend:9000 (tenants)    [Let's Encrypt]

backend (PHP-FPM :9000)  ←→  redis (:6379)
queue-worker              ←→  redis (:6379)
scheduler                 ←→  redis (:6379)
frontend (Bun :3000)      →   nginx → backend

External:
  → Neon PostgreSQL (database)
  → Cloudflare R2 (media storage)
```

## Services

| Service | Image | Purpose |
|---------|-------|---------|
| nginx | nginx:alpine | Reverse proxy + static files |
| certbot | certbot/dns-cloudflare | Let's Encrypt wildcard SSL |
| backend | php:8.4-fpm-alpine | Laravel API |
| queue-worker | (same as backend) | Background jobs |
| scheduler | (same as backend) | Cron / scheduled tasks |
| frontend | oven/bun:1-alpine | Vue 3 SSR + SEO meta injection |
| redis | redis:7-alpine | Cache, sessions, queues |

## VPS Layout

```
/opt/dukkan/
├── infra_haritna/        ← this repo
├── backend_dukkan/       ← Laravel source
├── frontend_dukkan/      ← Vue source
└── .env                  ← production secrets (not in git)
```

## Setup (first time)

### 1. Install dependencies & Docker
```bash
apt update && apt upgrade -y && apt install -y git curl ufw
curl -fsSL https://get.docker.com | sh && systemctl enable docker && systemctl start docker
```

### 2. Configure firewall
```bash
ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp && ufw --force enable
```

### 3. Clone repos
```bash
mkdir -p /opt/dukkan && cd /opt/dukkan
git clone git@github.com:harby-hub/infra_haritna.git
git clone git@github.com:harby-hub/backend_dukkan.git
git clone git@github.com:harby-hub/frontend_dukkan.git
```

### 4. Run setup script
```bash
bash infra_haritna/production/dukkan/scripts/setup.sh
```

### 5. Fill in secrets
```bash
nano /opt/dukkan/.env
```

### 6. Deploy
```bash
bash infra_haritna/production/dukkan/scripts/deploy.sh
```

## Deploy / Update

```bash
bash /opt/dukkan/infra_haritna/production/dukkan/scripts/deploy.sh
```

## Domains

| Domain | SSL | Purpose |
|--------|-----|---------|
| `dukkan-api.haritna.net` | Cloudflare Proxy | Backend API |
| `dukkan-app.haritna.net` | Cloudflare Proxy | Frontend app |
| `dukkan-media.haritna.net` | R2 Custom Domain | Media storage |
| `*.dukkan.haritna.net` | Let's Encrypt | Tenant domains |

## SSL Renewal

Tenant wildcard cert renews automatically. Manual renewal:
```bash
bash /opt/dukkan/infra_haritna/production/dukkan/scripts/ssl-renew.sh
```
