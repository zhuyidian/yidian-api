# Yidian API production deployment

This directory is the production overlay for the Hong Kong server. It keeps
upstream NEW API files unchanged and pins the deployed application version.

## Server prerequisites

- Ubuntu 24.04 LTS
- Docker Engine with the Compose plugin
- A public IPv4 address
- DNS `A` record for the API domain pointing to the server
- Inbound TCP 80/443 and UDP 443 allowed

## First deployment

```bash
cd /opt/yidian-api/deploy
cp .env.production.example .env.production
chmod 600 .env.production
nano .env.production

docker compose \
  --env-file .env.production \
  -f compose.production.yml \
  config

docker compose \
  --env-file .env.production \
  -f compose.production.yml \
  up -d
```

Generate URL-safe secrets with `openssl rand -hex 32`. Use a different value
for every password and secret. Caddy obtains and renews the HTTPS certificate
after the domain resolves to the server.

## Upgrade

1. Back up PostgreSQL.
2. Change only `NEW_API_VERSION` (or `NEW_API_IMAGE` for a customized build).
3. Pull and recreate the application.
4. Verify `/api/status` and a streaming API request.

```bash
docker compose --env-file .env.production -f compose.production.yml pull
docker compose --env-file .env.production -f compose.production.yml up -d
docker compose --env-file .env.production -f compose.production.yml ps
docker compose --env-file .env.production -f compose.production.yml logs --tail=100 new-api
```

Rollback by restoring the previous `NEW_API_VERSION` and running `up -d` again.
Database migrations can make application-only rollback unsafe, so retain a
database backup for every upgrade.

## PostgreSQL backup

```bash
mkdir -p /opt/yidian-api/backups
docker compose --env-file .env.production -f compose.production.yml exec -T postgres \
  pg_dump -U newapi -d newapi -Fc > /opt/yidian-api/backups/newapi.dump
```

Store a second encrypted copy outside this server. A backup that has never been
restored in a test environment is not yet a verified backup.

