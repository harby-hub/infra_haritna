# Haritna Infrastructure

Infrastructure, Docker, and deployment configurations for all Haritna projects.

## Projects

### Dukkan — E-commerce Platform
Multi-tenant e-commerce SaaS (Laravel API + Vue 3 frontend).

| Repo | Stack |
|------|-------|
| [backend_dukkan](https://github.com/harby-hub/backend_dukkan) | Laravel 12, PHP 8.4, PostgreSQL |
| [frontend_dukkan](https://github.com/harby-hub/frontend_dukkan) | Vue 3, TypeScript, Bun |
| [infra_haritna](https://github.com/harby-hub/infra_haritna) | Docker, Nginx, deploy scripts |

**Details:** [production/dukkan/README.md](production/dukkan/README.md)

## Structure

```
infra_haritna/
└── production/
    └── dukkan/
        ├── docker-compose.yml      # 6 services (nginx, backend, queue, scheduler, frontend, redis)
        ├── .env.example            # Environment template
        ├── backend/
        │   ├── Dockerfile          # PHP 8.4 FPM Alpine
        │   ├── php.ini             # PHP production config
        │   └── www.conf            # PHP-FPM pool config
        ├── frontend/
        │   └── Dockerfile          # Bun Alpine (SSR + SEO)
        ├── nginx/
        │   └── conf.d/
        │       └── default.conf    # Reverse proxy (API + App + Tenants)
        └── scripts/
            ├── setup.sh            # First-time VPS setup
            └── deploy.sh           # Build + migrate + cache
```

## Hosting

| Service | Provider | Cost |
|---------|----------|------|
| VPS | Contabo VPS S (4 vCPU, 8GB RAM) | ~$7/month |
| Database | Neon PostgreSQL | Free |
| Storage | Cloudflare R2 | Free (up to 10GB) |
| CDN / SSL | Cloudflare | Free |

## Quick Start

```bash
# On the VPS
bash /opt/dukkan/infra_haritna/scripts/setup.sh
nano /opt/dukkan/.env
bash /opt/dukkan/infra_haritna/scripts/deploy.sh
```

## Domains

| Domain | Purpose |
|--------|---------|
| `haritna.net` | Landing page (Cloudflare Pages) |
| `api.dukkan.haritna.net` | Dukkan API |
| `app.dukkan.haritna.net` | Dukkan frontend |
| `media.dukkan.haritna.net` | Media storage (R2) |
| `*.dukkan.haritna.net` | Tenant subdomains |
