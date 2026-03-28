---
name: api-development
description: Guide for API development with NestJS, FastAPI, and OpenAPI. Use when creating new endpoints, migrating APIs, generating clients for cross-service communication, or ensuring API consistency. Covers schema-first design with Zod, NestJS endpoints, FastAPI endpoints, and OpenAPI client generation.
---

# API Development Guide

## Overview

This skill provides everything needed for API development:

- Creating new API endpoints (NestJS and FastAPI)
- **Using Zod schemas** as the single source of truth for shared types
- Generating clients for cross-service communication
- Exporting OpenAPI specs via `zod-to-openapi`
- Following API style conventions

**Key Principle:** Use Zod schemas as the single source of truth. Don't duplicate types — infer them from schemas.

## When to Use This Skill

- Creating a new API endpoint
- Adding a proxy or gateway endpoint for frontend access
- Migrating or refactoring an existing API
- Adding cross-service communication
- Reviewing API code for consistency
- Generating OpenAPI specs or clients
- Questions about API patterns in this codebase

---

## Quick Reference

| Task | Command |
|------|---------|
| Build shared types | `pnpm run build` (or project equivalent) |
| Export OpenAPI (Zod) | `pnpm run openapi:export` |
| Export OpenAPI (FastAPI) | `uv run python scripts/openapi/export-fastapi.py <path> <module>` |
| Generate Python client | `./scripts/openapi/generate-python-client.sh <spec> <output>` |
| Generate TS client | `./scripts/openapi/generate-ts-client.sh <spec> <output>` |
| Lint OpenAPI spec | `npx @stoplight/spectral-cli lint <spec> --ruleset .spectral.yaml` |

---

## API Style Guide

| Convention | Rule | Example |
|------------|------|---------|
| URL paths | kebab-case | `/intel-items`, `/detection-rules` |
| Query params | snake_case | `?page_size=20&sort_by=created_at` |
| Response fields | snake_case | `{ "user_id": "abc", "created_at": "..." }` |
| Enum values | lowercase | `'active'`, `'pending'` |
| Pagination | page-based | `?page=1&page_size=20` |
| **Shared types** | **Zod schemas** | `z.object({ ... }).openapi('Name')` |

### Response Wrappers

All responses use standard wrappers:

```typescript
// Single item
{ "data": { ... }, "meta": { "timestamp": "..." } }

// Paginated list
{ "data": [...], "meta": { "total": 100, "page": 1, "page_size": 20, "total_pages": 5 } }

// Error
{ "errors": [{ "code": "VALIDATION_ERROR", "message": "...", "details": { ... } }] }
```

---

## Detailed Guides

| Task | Guide |
|------|-------|
| Define shared Zod schemas | [references/zod-schemas.md](./references/zod-schemas.md) |
| Create NestJS endpoint | [references/nestjs-endpoints.md](./references/nestjs-endpoints.md) |
| Create FastAPI endpoint | [references/fastapi-endpoints.md](./references/fastapi-endpoints.md) |
| Migrate class-validator → Zod | [references/migration-guide.md](./references/migration-guide.md) |
| Generate cross-language clients | [references/client-generation.md](./references/client-generation.md) |
| Debug common issues | [references/troubleshooting.md](./references/troubleshooting.md) |

---

## Checklists

### New API Endpoint

- [ ] Check shared types package for existing Zod schemas
- [ ] **Define new shared types as Zod schemas** (not class-validator)
- [ ] Use shared response wrappers (`ApiResponseSchema`, `ErrorResponseSchema`)
- [ ] Infer types from schemas (`z.infer<typeof Schema>`)
- [ ] Follow naming conventions (kebab-case paths, snake_case params)
- [ ] Add OpenAPI metadata via `.openapi()` method
- [ ] Run linting

### API Migration (class-validator → Zod)

- [ ] Create Zod schema in shared types package
- [ ] Export inferred type alongside schema
- [ ] Update imports in all consumers
- [ ] Delete local class-validator DTOs
- [ ] Run build and tests
- [ ] Regenerate OpenAPI and clients

### Client Generation

- [ ] Export OpenAPI spec
- [ ] Lint spec with Spectral
- [ ] Generate client (Python or TypeScript)
- [ ] Add client as dependency to consumer
- [ ] Commit generated client with source changes

---

## File Locations

| Purpose | Location |
|---------|----------|
| Shared Zod schemas | `packages/api-types/src/` (adjust to your project) |
| API style guide | `docs/api-style-guide.md` |
| Spectral config | `.spectral.yaml` |
| OpenAPI scripts | `scripts/openapi/` |
