# Yidian API development and release workflow

## Upstream baseline

- Repository: `https://github.com/QuantumNous/new-api.git`
- Release: `v1.0.0-rc.15`
- Commit: `69b0f0b56f528efa292a2893feb0c55c37399f4b`
- Local customization branch: `yidian-main`
- Git remote for the official project: `upstream`

The application is based on a signed release tag rather than the moving
`upstream/main` branch. Production must use an explicit image version.

## Local development

Install Docker Desktop with Docker Compose. The upstream development stack
starts the Go backend, PostgreSQL, and Redis:

On Windows, if Docker reports that WSL 2 is missing, open PowerShell as
Administrator and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
& .\scripts\enable-wsl-for-docker.ps1
```

Restart Windows after the script completes, then start Docker Desktop once and
finish its first-run setup.

```powershell
docker compose `
  -f docker-compose.dev.yml `
  -f deploy/compose.local.yml `
  up -d --build

docker compose `
  -f docker-compose.dev.yml `
  -f deploy/compose.local.yml `
  logs -f new-api frontend
```

Open `http://localhost:3001`. The Yidian local override runs Bun and the
hot-reloading frontend in Docker, so a separate host installation of Go or Bun
is not required. Never connect a local environment to the production database
or use production provider/payment secrets locally.

Before a release, test at least:

1. Administrator and normal-user login.
2. Token creation and quota enforcement.
3. A normal and a streaming chat request.
4. Tool calls for every enabled provider protocol.
5. Recharge creation and payment webhook idempotency.
6. Channel failover and upstream error handling.

## Build a customized image

Use an immutable version. Replace the sample registry with the project's own
registry after its remote repository has been created.

```powershell
docker build -t ghcr.io/OWNER/yidian-api:0.1.0 .
docker push ghcr.io/OWNER/yidian-api:0.1.0
```

On the server, set these values in `deploy/.env.production`:

```dotenv
NEW_API_IMAGE=ghcr.io/OWNER/yidian-api
NEW_API_VERSION=0.1.0
```

The exact same image should pass local testing and then be deployed to the
server. Do not rebuild source code on the production server.

## Upgrade the official baseline

Keep local work committed before starting an upgrade. Fetch the official tags,
inspect release notes and security advisories, then merge the selected release
into a dedicated upgrade branch:

```powershell
git fetch upstream --tags
git switch -c upgrade/new-api-vNEXT yidian-main
git merge vNEXT
```

Resolve and test the upgrade locally. Do not merge `upstream/main` directly
into production. Back up PostgreSQL before deploying any version that changes
the database schema.

## License

NEW API is licensed under AGPL-3.0. Preserve required notices and review the
source-availability obligations before offering a modified build as a network
service. The upstream project also advertises a commercial licensing contact.
