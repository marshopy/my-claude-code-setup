---
name: codebase-analyst
description: Deeply analyzes a codebase to produce a structured context document covering project background, product behavior, and system architecture. Use this skill before writing specs, planning features, or starting implementation on an unfamiliar or complex codebase. Invoke when the user asks to "analyze the codebase", "understand this project", "create a context document", "document the architecture", or before any planning/spec task on an unfamiliar project.
---

# Codebase Analyst

To deeply analyze a codebase and produce a structured context document that can serve as grounding for any subsequent spec, planning, or implementation work.

## When to Use This Skill

- Before starting a spec or feature plan on an unfamiliar project
- When onboarding to a new codebase
- When asked to "analyze", "understand", or "document" a codebase
- Before any task where background context would prevent rework or misaligned decisions

## Output

Produces a `CODEBASE-CONTEXT.md` document saved to:
- `<project-root>/docs/CODEBASE-CONTEXT.md` — if a `docs/` directory exists
- `~/.temp/<project-name>/CODEBASE-CONTEXT.md` — otherwise

The document follows the structure in `references/output-template.md`.

---

## Workflow

### Phase 1: Parallel Discovery

Launch **3 Explore agents in parallel** (single message, 3 Agent tool calls). Each agent uses `references/analysis-checklist.md` as its guide for what to look for. Provide each agent with the absolute path to the project being analyzed.

**Agent A — Project Identity, Structure & Build**
- README, package manifests (package.json, Cargo.toml, go.mod, pyproject.toml), LICENSE
- **Project type classification first** (see checklist Step 0): NX monorepo, Turborepo, Next.js, Vite SPA, Angular, Remix, SvelteKit, Astro, library, CLI, edge function
- Monorepo detection: `nx.json` (NX), `turbo.json` (Turborepo), `pnpm-workspace.yaml`
- For **NX**: read `nx.json`, enumerate all `project.json` files, map `libs/` by NX tags, note path aliases in `tsconfig.base.json`
- Top-level directory enumeration and purpose inference; for monorepos list every app + lib
- Build scripts, package manager lockfile, `tsconfig.json`/`tsconfig.base.json`, linting config
- `.env.example` for full env var list

**Agent B — Domain Logic, Data Models & Product Behavior**
- Use the **project type** identified by Agent A to focus on the right framework signals
- **Frontend** (framework-specific): Next.js App/Pages Router routes, Vite SPA entry + router, Angular routes + modules, Remix routes + loaders, SvelteKit `+page` files, Astro pages; component structure, nav tree, feature flags, i18n
- **Backend** (framework-specific): NestJS modules/controllers/DTOs, Express/Fastify routes, tRPC routers, Hono/Elysia routes, serverless function files
- **Library/CLI** (if applicable): `package.json` exports, `src/index.ts` public API surface, build config (tsup/rollup)
- Data models: Prisma schema, TypeORM entities, Drizzle schema, Mongoose schemas, Zod contracts
- Service layer, state management (Zustand, Jotai, Redux, TanStack Query), custom hooks
- Test files — test names reveal user flows more reliably than documentation

**Agent C — Infrastructure, Integrations & Deployment**
- Dockerfile, docker-compose.yml — service topology
- CI/CD: `.github/workflows/`, Bitbucket Pipelines, CircleCI
- PaaS config: vercel.json, fly.toml, netlify.toml, wrangler.toml
- Auth library and enforcement points (middleware, guards)
- All env var names classified by integration type
- SDK dependencies cross-referenced with env vars

Each agent must return:
1. A summary of what it found (2–4 sentences)
2. Structured findings per checklist category
3. Any gaps or ambiguities it could not resolve

### Phase 2: Synthesis

After all 3 agents complete, synthesize their findings:

1. Map agent findings to the 7 sections of `references/output-template.md`
2. Identify any contradictions or gaps across agents
3. Infer product stage and team maturity from signals in `references/analysis-checklist.md`
4. Draft the complete context document

### Phase 3: Document Generation

Write the completed context document using the structure from `references/output-template.md`.

Rules for writing the document:
- Fill every section; use `_Unknown — needs investigation_` rather than omitting a field
- For the tech stack table, list every layer — even if the value is "None detected"
- For user flows, trace them from UI routes back through API handlers to data models
- For open questions, surface genuine ambiguities found during analysis (do not fabricate)
- Keep language precise and factual; avoid filler phrases like "robust" or "powerful"

Save the document:
```
# If docs/ directory exists at project root:
<project-root>/docs/CODEBASE-CONTEXT.md

# Otherwise:
~/.temp/<project-name>/CODEBASE-CONTEXT.md
```

### Phase 4: User Review

After saving the document, present a concise review summary to the user:

1. **3-line project summary** — what it is, who it's for, current status
2. **Architecture highlights** — the 3 most important architectural facts
3. **Product behavior highlights** — the 3 most important product behaviors
4. **Open questions** — list all items from Section 7 of the document
5. **Assumptions made** — list any inferences that may be incorrect

Then ask the user to confirm or correct:
- Any misidentified project purpose or target users
- Any architectural assumptions (e.g., inferred deployment topology)
- Any product behaviors that are incorrect or out of date
- Any open questions the user can immediately answer

Update the saved document based on the user's corrections before concluding.

---

## Key Principles

**Depth over breadth on critical sections.** Spend more time on data models and product behavior — these are the sections most likely to prevent rework. Tech stack can usually be re-verified quickly; domain logic cannot.

**Trust test files.** Test names and test files reveal actual product behavior more reliably than comments or README prose. An E2E test named `user can checkout with saved payment method` tells you more than a README section.

**Env vars are the integration map.** The `.env.example` file is often the fastest path to understanding all third-party dependencies. Classify every variable.

**Surface what you don't know.** A complete list of open questions is as valuable as the answers. Do not paper over ambiguity — put it in Section 7.

**Do not read every file.** Use targeted searches (Grep, Glob) rather than reading entire directories. The analysis checklist provides the right search targets.

**For NX repos, map the project graph before anything else.** Read `nx.json` + all `project.json` files first. NX tags (`scope:*`, `type:*`) reveal team and domain boundaries more accurately than directory names. The `tsconfig.base.json` `paths` entries are the canonical list of internal packages — use these as the map of shared libraries.

**Let the project type guide the investigation.** A Next.js standalone app and an NX monorepo with 20 projects need very different analyses. Agent A's Step 0 classification determines which checklist sections are relevant — skip sections that don't apply rather than filling them with "None detected".
