# Codebase Context Document — Output Template

Use this template to structure the output of a codebase analysis. Fill in every section; use `_Unknown — needs investigation_` for genuinely missing information rather than leaving blanks.

---

# [Project Name] — Codebase Context

> **Status:** [Active / In Development / Prototype / Archived]
> **Last analyzed:** [Date]
> **Analyzed by:** Claude Code (codebase-analyst skill)

---

## 1. Project Overview

**One-line purpose:**
> [What this project does, in a single sentence]

**Repository:** `[repo path or URL]`
**Primary language(s):** [e.g., TypeScript, Swift, Python]
**Type:** [Web app / Mobile app / API / CLI / Library / Monorepo / Config/tooling]

---

## 2. Background & Problem Context

**Problem being solved:**
[2–4 sentences describing the real-world problem or need this project addresses]

**Target users:**
- [User type 1] — [brief description of their need]
- [User type 2] — [brief description of their need]

**Key product goals:**
1. [Goal 1]
2. [Goal 2]
3. [Goal 3]

**Origin / motivation:**
[Why was this built? What prompted it? Any key constraints (deadline, compliance, team size)?]

---

## 3. Product Behavior

### Core Features
| Feature | Description | Status |
|---------|-------------|--------|
| [Feature 1] | [What it does] | [Implemented / Partial / Planned] |
| [Feature 2] | [What it does] | [Implemented / Partial / Planned] |

### Key User Flows

**Flow 1: [Name]**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Flow 2: [Name]**
1. [Step 1]
2. [Step 2]

### Notable UX / Behavioral Patterns
- [e.g., "All forms use optimistic updates"]
- [e.g., "Auth is session-based; no JWT"]
- [e.g., "Mobile-first responsive layout throughout"]

---

## 4. System Architecture

### Project Type
**[One of: NX Monorepo / Turborepo Monorepo / pnpm Workspace / Next.js App / Vite SPA / Angular App / Remix App / SvelteKit App / Astro Site / NestJS API / Express API / tRPC API / Library / CLI / Cloudflare Worker / Other]**

### Tech Stack
| Layer | Technology | Version / Notes |
|-------|-----------|-----------------|
| Repo / build orchestration | [e.g., NX, Turborepo, none] | [e.g., NX v20, affected builds enabled] |
| Package manager | [e.g., pnpm] | [e.g., v10, workspace protocol] |
| Language | TypeScript | [e.g., v5.4, strict mode on] |
| Frontend framework | [e.g., Next.js, React+Vite, Angular, SvelteKit] | [e.g., Next.js v15, App Router] |
| Backend framework | [e.g., NestJS, Express, tRPC, Remix loaders] | [e.g., NestJS v11] |
| Database | [e.g., PostgreSQL, MySQL, SQLite, MongoDB] | [e.g., via Prisma ORM v6] |
| ORM / query layer | [e.g., Prisma, TypeORM, Drizzle, Kysely, Mongoose] | |
| Auth | [e.g., NextAuth.js, Clerk, Auth0, Passport, custom JWT] | |
| Styling | [e.g., Tailwind CSS, CSS Modules, styled-components] | |
| UI component library | [e.g., shadcn/ui, HeroUI, MUI, Ant Design, none] | |
| State management | [e.g., Zustand, Jotai, Redux Toolkit, TanStack Query] | |
| Testing | [e.g., Vitest, Jest, Playwright, Cypress] | |
| Linting / formatting | [e.g., Biome, ESLint + Prettier] | |
| Infra / hosting | [e.g., Vercel + Railway, AWS, Cloudflare] | |

### Repository Structure
```
[project-root]/
├── [dir/]         — [purpose]
├── [dir/]         — [purpose]
└── [dir/]         — [purpose]
```

### Monorepo Topology _(omit for single-app repos)_

**Build system:** [NX / Turborepo / pnpm workspaces]

**Applications:**
| App | Type | Framework | Entry point |
|-----|------|-----------|-------------|
| `apps/[name]` | [Web / API / Mobile / CLI / Docs] | [framework] | `apps/[name]/src/main.ts` |

**Shared Libraries:**
| Library | NX Tags | Consumers | Purpose |
|---------|---------|-----------|---------|
| `libs/[name]` | `[scope:x, type:y]` | [which apps] | [what it provides] |

**NX Module Boundaries** _(if NX)_:
```
[Describe enforced import rules, e.g.:]
- feature libs can import data-access, ui, util libs
- ui libs cannot import feature or data-access libs
- app projects can import any lib
```

**Task dependency graph** _(key relationships)_:
```
build → [depends on] → lint, typecheck
test  → [depends on] → typecheck
```

### Key Components / Services
| Component | Responsibility | Location |
|-----------|---------------|----------|
| [e.g., AuthModule] | [Handles login, sessions, JWT] | `apps/api/src/auth/` |
| [e.g., Dashboard page] | [User stats overview] | `apps/web/app/dashboard/` |
| [e.g., @scope/ui] | [Shared component library] | `libs/ui/` |

### Core Data Models
```
[Entity name]
  - [field]: [type] — [description]
  - [field]: [type] — [description]

[Entity name]
  - [field]: [type] — [description]
```

### External Integrations
| Service | Purpose | How integrated |
|---------|---------|----------------|
| [e.g., Stripe] | [Payments] | [SDK via env var STRIPE_SECRET_KEY] |
| [e.g., SendGrid] | [Transactional email] | [REST API] |

### Deployment Topology
```
[Describe how the system is deployed: e.g., "Vercel (frontend) + Railway (API + DB)"]
[Note any CI/CD pipeline, environment stages (dev/staging/prod)]
[For NX: note whether affected builds are used in CI]
```

---

## 5. Code Conventions & Patterns

### Language & Framework Patterns
- [e.g., "All API responses wrapped in `{ data, meta }` envelope"]
- [e.g., "React 19 — uses ref-as-prop, no forwardRef"]
- [e.g., "NestJS dependency injection throughout; no singletons"]

### Folder / File Organization
- [e.g., "Feature-based folders: `src/features/<name>/{controller,service,module}.ts`"]
- [e.g., "Shared types in `packages/types/`"]

### Testing Approach
- [e.g., "E2E with Playwright in `tests/`; unit tests co-located as `*.spec.ts`"]
- [e.g., "Coverage target: 80% backend, 70% frontend"]

### Linting / Formatting
- [e.g., "Biome for lint + format; runs pre-commit via Husky"]

---

## 6. Key Decisions & Constraints

| Decision | Rationale | Impact |
|----------|-----------|--------|
| [e.g., Monorepo with Turborepo] | [Shared types, co-deploy frontend+backend] | [All packages versioned together] |
| [e.g., No Redux, use React Query] | [Server state only; avoids boilerplate] | [All async state via React Query hooks] |

### Known Limitations / Tech Debt
- [e.g., "No pagination on the activity feed — will break at scale"]
- [e.g., "Auth tokens stored in localStorage; needs migration to httpOnly cookies"]

---

## 7. Open Questions

Items to clarify before starting spec / planning / implementation work:

- [ ] [Question 1: e.g., "Is multi-tenancy in scope for the next phase?"]
- [ ] [Question 2: e.g., "What's the expected peak concurrent users?"]
- [ ] [Question 3]

---

_Generated by the `codebase-analyst` skill. Update this document as the codebase evolves._
