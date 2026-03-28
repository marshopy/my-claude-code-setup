# Codebase Analysis Checklist

Reference guide for what signals and files to look for when analyzing a codebase. Use this to ensure thorough, consistent coverage across all analysis categories.

---

## Agent A — Project Identity, Structure & Build

### Step 0: Classify the Project Type First

Before anything else, determine the project type — this shapes what to look for throughout the analysis.

| Signal | Project Type |
|--------|-------------|
| `nx.json` present | NX monorepo |
| `turbo.json` present | Turborepo monorepo |
| `pnpm-workspace.yaml` / `lerna.json` (no nx/turbo) | Generic pnpm/Lerna monorepo |
| Single `package.json` + `next.config.*` | Next.js app (standalone) |
| Single `package.json` + `vite.config.*` | Vite SPA (React/Vue/Svelte/Solid) |
| Single `package.json` + `angular.json` | Angular app (standalone) |
| `remix.config.*` / `vite.config.ts` + `@remix-run` dep | Remix app |
| `svelte.config.*` + `@sveltejs/kit` dep | SvelteKit app |
| `astro.config.*` | Astro site |
| `package.json` with `"main"` / `"exports"` + no `app/` or `pages/` | Library / npm package |
| `src/index.ts` exporting a CLI entry + `bin` field in package.json | CLI tool |
| `wrangler.toml` + no frontend | Cloudflare Worker / edge function |

**Record the project type prominently** — it determines which checklist sections below are most relevant.

### Project Identity
- [ ] `README.md` / `README.rst` — project name, description, badges, setup instructions
- [ ] `package.json` / `Cargo.toml` / `go.mod` / `pyproject.toml` / `Gemfile` — name, description, version
- [ ] `LICENSE` — open source vs. proprietary
- [ ] Root-level docs (`docs/`, `wiki/`) — any architecture docs or ADRs
- [ ] `.env.example` / `.env.sample` — environment variable names (reveals integrations and feature flags)
- [ ] `CHANGELOG.md` — version history and release cadence signal

### Repository Structure
- [ ] Is this a **monorepo**? Look for: `nx.json`, `turbo.json`, `pnpm-workspace.yaml`, `lerna.json`
- [ ] Enumerate top-level directories and their apparent purpose
- [ ] `apps/` vs `packages/` vs `services/` vs `libs/` — understand the split
- [ ] Any `shared/`, `common/`, `tools/`, `e2e/` directories

### NX Monorepo (when `nx.json` detected)
- [ ] `nx.json` — `defaultBase`, `targetDefaults`, `tasksRunnerOptions` (cache config), `affected` config
- [ ] `workspace.json` (NX < v15) or `project.json` per project (NX ≥ v15) — project targets and executors
- [ ] Each project's `project.json`: `name`, `projectType` (`application` vs `library`), `targets`, `tags`
- [ ] `libs/` directory: NX convention for shared libraries — enumerate by `scope:*` and `type:*` tags
- [ ] `.eslintrc.json` at root + per-project overrides — NX module boundary lint rules (`@nx/enforce-module-boundaries`)
- [ ] `tools/generators/` — any custom NX generators (reveals automation patterns)
- [ ] `nx affected` usage in CI — understand what triggers rebuilds
- [ ] Path aliases in `tsconfig.base.json` (root) — NX auto-generates `@scope/lib-name` aliases; map these
- [ ] NX project graph mental model: run `nx graph` conceptually from `project.json` files

### Build & Package Management
- [ ] `package.json` scripts — `dev`, `build`, `test`, `lint` commands
- [ ] `turbo.json` pipeline OR `nx.json` `targetDefaults` — task dependency graph
- [ ] Package manager lockfile: `package-lock.json` = npm, `yarn.lock` = yarn, `pnpm-lock.yaml` = pnpm, `bun.lockb` = bun
- [ ] `tsconfig.json` / `tsconfig.base.json` — TypeScript `compilerOptions`, `paths` aliases, `strict` mode
- [ ] `.biomerc` / `.eslintrc.*` / `prettier.config.*` — linting/formatting tool and config
- [ ] `Makefile` / `justfile` — any automation targets
- [ ] `vitest.config.ts` / `jest.config.ts` at root — test runner setup

---

## Agent B — Domain Logic, Data Models & Product Behavior

### Step 0: Identify All Apps/Packages in the Repo

For monorepos, enumerate every app and library before diving into domain logic:
- List each entry in `apps/`, `packages/`, `libs/`, `services/`
- For each: check its `package.json` `name` + framework signals to classify it
- Distinguish: web app, mobile app, API server, shared library, CLI, docs site, E2E test app

### Frontend / UI

**Next.js (App Router):**
- [ ] `app/` directory — map routes via folder structure; `(group)` = route group (not URL segment)
- [ ] `app/layout.tsx` — global providers, fonts, auth wrappers
- [ ] `app/api/` — Route Handlers (server-side API endpoints within Next.js)
- [ ] `middleware.ts` — request interception, auth redirects
- [ ] Server Components vs Client Components (`"use client"` directives)

**Next.js (Pages Router):**
- [ ] `pages/` directory — map all routes
- [ ] `pages/api/` — API routes
- [ ] `_app.tsx` / `_document.tsx` — global wrappers

**Vite SPA (React / Vue / Svelte / Solid):**
- [ ] `vite.config.ts` — framework plugin, proxy config, aliases
- [ ] `src/App.tsx` / `src/main.tsx` — entry point and router setup
- [ ] Router: `react-router-dom`, `@tanstack/router`, `vue-router`, `svelte-kit` routing
- [ ] `src/routes/` or `src/pages/` — page-level components

**Angular:**
- [ ] `angular.json` — project configuration, build/serve/test targets
- [ ] `src/app/app-routing.module.ts` / `app.routes.ts` — route definitions
- [ ] Feature modules (`*.module.ts`) or standalone components
- [ ] `src/environments/` — environment configs

**Remix:**
- [ ] `app/routes/` — file-based routing; `_index.tsx`, nested routes
- [ ] `app/root.tsx` — root layout and error boundary
- [ ] `loader` / `action` exports in route files — server-side data fetching

**SvelteKit:**
- [ ] `src/routes/` — file-based routing; `+page.svelte`, `+layout.svelte`, `+page.server.ts`
- [ ] `src/lib/` — shared utilities and components
- [ ] `svelte.config.js` — adapter (Vercel, Cloudflare, Node)

**Astro:**
- [ ] `src/pages/` — file-based routes; `.astro`, `.md`, `.mdx` pages
- [ ] `src/content/` — content collections
- [ ] `astro.config.mjs` — integrations (React, Vue, Tailwind, etc.)

**All Frontend:**
- [ ] Component structure — feature-based vs. type-based (`components/`, `features/`, `modules/`)
- [ ] `navigation.*` / `routes.*` / `sidebar.*` — full nav tree
- [ ] Feature flags / conditional renders — reveals planned/hidden features
- [ ] i18n files (`locales/`, `messages/`, `i18n/`) — internationalization scope
- [ ] UI library: shadcn/ui, HeroUI, Material UI, Ant Design, Chakra UI, Radix, Headless UI

### Backend / API

**NestJS:**
- [ ] `src/app.module.ts` — root module, imported feature modules
- [ ] Each `*.module.ts` = one feature domain; enumerate all of them
- [ ] `*.controller.ts` — HTTP endpoints per module
- [ ] `*.service.ts` — business logic
- [ ] `*.dto.ts` — request/response shapes (input validation)
- [ ] `*.guard.ts` / `*.interceptor.ts` / `*.pipe.ts` — cross-cutting concerns
- [ ] `main.ts` — bootstrap config (port, CORS, Swagger, validation pipe)

**Express / Fastify:**
- [ ] `src/routes/` or `routes/` — enumerate all route files
- [ ] `src/middleware/` — middleware chain
- [ ] `src/controllers/` — request handlers
- [ ] Entry file (`app.ts`, `server.ts`, `index.ts`) — plugin/middleware registration order

**tRPC:**
- [ ] `src/router/` or `src/trpc/` — router definitions
- [ ] `appRouter` type export — the full API surface
- [ ] `createTRPCRouter` / `publicProcedure` / `protectedProcedure` — procedure types

**Hono / Elysia (Bun):**
- [ ] Route definitions via method chaining (`.get()`, `.post()`)
- [ ] Middleware registration
- [ ] Entry file for runtime target (Bun, Cloudflare Workers, Node)

**Serverless / Edge:**
- [ ] `api/` directory (Vercel Functions) — each file = one endpoint
- [ ] `functions/` (Netlify) — similar pattern
- [ ] `wrangler.toml` + `src/index.ts` — Cloudflare Worker entry
- [ ] `handler` exports in AWS Lambda pattern

**All Backend:**
- [ ] API contracts: `*.dto.ts`, `*.schema.ts`, Zod schemas, `*.types.ts`
- [ ] Swagger/OpenAPI files (`swagger.json`, `openapi.yaml`) — auto-generated API docs
- [ ] Error handling patterns — custom exception classes, error middleware

### Library / Package (when project type = library)
- [ ] `package.json` `"exports"` field — what the package publicly exposes
- [ ] `src/index.ts` — public API surface (exports)
- [ ] Build config: `tsup.config.ts`, `rollup.config.ts`, `vite.config.ts` (lib mode)
- [ ] `src/types/` or `*.d.ts` files — type definitions
- [ ] Peer dependencies — what the consumer must provide

### CLI Tool (when project type = CLI)
- [ ] Entry file with `bin` reference
- [ ] Command framework: `commander`, `yargs`, `oclif`, `@clack/prompts`
- [ ] Enumerate commands and subcommands
- [ ] Config file loading patterns

### Data Models

**TypeScript ORMs & Schema Tools:**
- [ ] **Prisma:** `prisma/schema.prisma` — all models, relations, enums, datasource
- [ ] **TypeORM:** `*.entity.ts` files — all entities and relations
- [ ] **Drizzle:** `src/db/schema.ts` or `drizzle/schema.ts` — table definitions
- [ ] **Mongoose:** `*.schema.ts` / `*.model.ts` — document schemas
- [ ] **Kysely:** `src/db/types.ts` — database type definitions
- [ ] **Zod schemas** used as data contracts: `*.schema.ts`, `schemas/`

**Database:**
- [ ] Migrations folder — schema evolution history
- [ ] Seed files — contain realistic domain data, reveal entity relationships
- [ ] `DATABASE_URL` in env — database type (postgres://, mysql://, sqlite:)

### Business Logic
- [ ] Service layer files (`*.service.ts`, `services/`, `use-cases/`, `domain/`)
- [ ] State management: `zustand`, `jotai`, `valtio`, `@tanstack/query`, `redux-toolkit`, `xstate`
- [ ] Custom hooks (`hooks/`, `use*.ts`) — business logic abstractions
- [ ] Utilities / helpers (`utils/`, `lib/`, `helpers/`) — shared functions
- [ ] Event system: EventEmitter patterns, message queues (Bull, BullMQ, Redis Streams)

---

## Agent C — Infrastructure, Integrations & Deployment

### Deployment & Infrastructure
- [ ] `Dockerfile` / `docker-compose.yml` — containerization, service topology
- [ ] `.github/workflows/` — CI/CD pipeline (build, test, deploy steps)
- [ ] `vercel.json` / `netlify.toml` / `fly.toml` — PaaS configuration
- [ ] `terraform/` / `infra/` / `pulumi/` — infrastructure as code
- [ ] `kubernetes/` / `k8s/` / Helm charts — container orchestration
- [ ] `wrangler.toml` — Cloudflare Workers deployment
- [ ] `app.yaml` — Google App Engine

### External Integrations
- [ ] `.env.example` — every env var is a potential integration; categorize:
  - `*_API_KEY` / `*_SECRET` — third-party services
  - `DATABASE_URL` — database type and connection
  - `REDIS_URL` — caching layer
  - `S3_*` / `STORAGE_*` — file storage
  - `SMTP_*` / `SENDGRID_*` / `RESEND_*` — email
  - `STRIPE_*` — payments
  - `SENTRY_*` — error monitoring
  - `ANALYTICS_*` — analytics platform
- [ ] SDK imports in `package.json` dependencies — cross-reference with env vars
- [ ] Webhook routes (`/webhooks/`, `/api/webhooks/`) — inbound integrations

### Auth & Security
- [ ] Auth library: `next-auth`, `passport`, `jwt`, `clerk`, `auth0`, `supabase/auth`
- [ ] `middleware.ts` (Next.js) / `*.guard.ts` (NestJS) — auth enforcement points
- [ ] Role/permission definitions (`roles.ts`, `permissions.ts`, `CASL`, `casbin`)
- [ ] Session configuration — cookie vs. JWT vs. token

### Testing
- [ ] Test runner config: `vitest.config.ts`, `jest.config.ts`, `playwright.config.ts`
- [ ] Test directory structure: co-located vs. `__tests__/` vs. `tests/` vs. `spec/`
- [ ] Coverage thresholds — check config files
- [ ] E2E test files — trace user flows from test names

### Mobile (iOS/Android)
- [ ] `*.xcodeproj` / `*.xcworkspace` — iOS project
- [ ] `Info.plist` — app name, bundle ID, permissions requested
- [ ] `Package.swift` / SPM packages — dependencies
- [ ] `AndroidManifest.xml` — permissions, activities
- [ ] `build.gradle` — Android dependencies

---

## Cross-Cutting Signals

### Infer Product Stage
| Signal | Interpretation |
|--------|---------------|
| Comprehensive README with badges | Mature/public-facing |
| TODO/FIXME comments everywhere | Active early development |
| Many feature branches or recent commits | Active development |
| Sparse README, no tests | Prototype/spike |
| Archived / no recent commits | Maintenance mode |

### Infer Team Size & Process
| Signal | Interpretation |
|--------|---------------|
| PR templates, CODEOWNERS | Organized team process |
| Conventional commits enforced | Mature engineering practices |
| Husky + lint-staged | Enforced code quality gates |
| Multiple `apps/` in monorepo | Multiple teams or products |

### Common Gotchas

**NX-specific:**
- `nx.json` `targetDefaults` applies to ALL projects — look here for global test/build config before checking per-project
- NX `project.json` `tags` like `"scope:auth"` / `"type:feature"` reveal team/domain boundaries — map these
- NX path aliases in `tsconfig.base.json` `paths` are auto-generated; `@myorg/ui` = `libs/ui/src/index.ts`
- NX `affected` commands only rebuild changed projects + dependents — CI may not run all tests on every commit
- `libs/` in NX ≠ npm packages; they're internal libraries consumed via TypeScript path aliases, not published

**TypeScript / Monorepo:**
- `apps/web` ≠ the only frontend — check for `apps/admin`, `apps/docs`, `apps/mobile`, `apps/storybook`
- `.env.example` may be incomplete — check import statements for additional SDK usage
- `tsconfig.base.json` path aliases (e.g. `@scope/*`) are internal imports — don't mistake them for npm packages
- `packages/types` or `packages/shared` often holds the canonical data model — check here before ORM files
- Turborepo `pipeline` / NX `targetDefaults` show the build dependency graph, not the product architecture

**Framework-specific:**
- Next.js `app/` folders named `(group)` are route groups — not URL segments
- Next.js Server Components don't ship JS to the client — look for `"use client"` to find the interactive boundary
- NestJS modules don't always map 1:1 to product features — check controller routes, not just module names
- tRPC `appRouter` type is the single source of truth for the API surface — always check it
- Vite SPA projects may have a separate API server — check for a `server/` or `api/` directory alongside `src/`
- Angular standalone components (v15+) no longer need `NgModule` — don't assume all logic is in modules
