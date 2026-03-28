---
name: docker-local-dev
description: Add new services to Docker Compose for local development with hot reload. Use when setting up a new service to run in Docker locally, adding services to the compose configuration, or needing commands to run services individually or together.
---

# Docker Local Development

## Overview

This skill helps you add new services/apps to the Docker Compose setup for local development with hot reload support. The monorepo uses Docker Compose profiles to run services selectively.

## Quick Reference - Running Services

| Command | Description |
|---------|-------------|
| `docker compose up` | Start all services |
| `docker compose up --build` | Rebuild and start all services |
| `docker compose down` | Stop all services |

### Individual Services via Profiles

```bash
# Run specific service profiles
docker compose --profile <service-name> up

# Rebuild specific service
docker compose --profile <service-name> up --build

# Standalone debugging (service-specific compose)
cd services/<service-name> && docker compose up
```

---

## Adding a New Service

### Step 1: Create Dockerfile.local

Create `services/<service-name>/Dockerfile.local` based on the runtime:

#### Python/FastAPI Service

```dockerfile
# Local development Dockerfile with hot reload support
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

ENV UV_COMPILE_BYTECODE=0 \
    UV_LINK_MODE=copy \
    PYTHONUNBUFFERED=1 \
    PORT=<PORT>

WORKDIR /app

# Copy workspace root files for uv to resolve workspace dependencies
COPY pyproject.toml uv.lock ./

# Copy workspace members needed by this service
COPY packages/<dep1>/ ./packages/<dep1>/
COPY services/<service-name>/ ./services/<service-name>/

# Install all dependencies including dev deps
RUN uv sync --frozen --package <service-name>

WORKDIR /app/services/<service-name>

EXPOSE $PORT

# Run with --reload for hot reloading
CMD ["sh", "-c", "uv run uvicorn main:app --reload --host 0.0.0.0 --port $PORT"]
```

#### Node/NestJS Service

```dockerfile
# Local development Dockerfile with hot reload support
# Build context must be the monorepo root
FROM node:22-alpine

WORKDIR /app

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy workspace manifests for dependency resolution
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages/ ./packages/

# Copy service source
COPY services/<service-name>/ ./services/<service-name>/

# Install only the service's dependencies
# Adjust --filter to match your workspace package name
RUN pnpm install --frozen-lockfile --filter=<service-package-name>...

WORKDIR /app/services/<service-name>

EXPOSE <PORT>

# Start with hot reload
CMD ["pnpm", "run", "start:dev"]
```

---

### Step 2: Add to docker-compose.yml

```yaml
services:
  <service-name>:
    build:
      context: .
      dockerfile: services/<service-name>/Dockerfile.local
    profiles:
      - <profile-name>
      - backend
    ports:
      - "<PORT>:<PORT>"
    env_file:
      - services/<service-name>/.env
    volumes:
      # Hot reload: mount source code
      - ./services/<service-name>/src:/app/services/<service-name>/src
    depends_on:
      - db  # adjust to your service's dependencies
```

---

### Step 3: Add Environment Variables

Create `services/<service-name>/.env` with required variables:

```bash
PORT=<PORT>
NODE_ENV=development
DATABASE_URL=postgres://user:pass@db:5432/mydb
```

---

### Step 4: Verify Hot Reload

1. Start the service: `docker compose --profile <profile> up`
2. Edit a source file
3. Confirm the service reloads automatically in logs

---

## Checklists

### New Service Setup

- [ ] Create `Dockerfile.local` in service directory
- [ ] Add service to `docker-compose.yml` with appropriate profile
- [ ] Create `.env` file with required variables
- [ ] Add `.env` to `.gitignore` (only commit `.env.example`)
- [ ] Verify hot reload works with a test change
- [ ] Document the profile name in project README

### Volume Mount Strategy

- Python: Mount `src/` directory for hot reload
- Node: Mount `src/` directory; `node_modules` stays in container
- Static assets: Mount `public/` or `assets/` separately if needed
