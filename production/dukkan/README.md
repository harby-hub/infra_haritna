# Dukkan Infrastructure

Docker + Nginx + deploy configs for the Dukkan platform.

## Architecture

```
nginx (ports 80/443)
  ├── api.dukkan.haritna.net   → backend:9000 (PHP-FPM)
  ├── app.dukkan.haritna.net   → frontend:3000 (Bun SSR)
  └── *.dukkan.haritna.net     → backend:9000 (tenant domains)

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

```bash
bash /opt/dukkan/infra_haritna/scripts/setup.sh
nano /opt/dukkan/.env     # fill in secrets
bash /opt/dukkan/infra_haritna/scripts/deploy.sh
```

## Deploy / Update

```bash
bash /opt/dukkan/infra_haritna/scripts/deploy.sh
```

## Domains

| Domain | Purpose |
|--------|---------|
| `api.dukkan.haritna.net` | Backend API |
| `app.dukkan.haritna.net` | Frontend app |
| `media.dukkan.haritna.net` | R2 media storage |
| `*.dukkan.haritna.net` | Tenant domains |
