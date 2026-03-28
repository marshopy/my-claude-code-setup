---
name: tsconfig-reviewer
description: Expert code review skill for validating TypeScript project references configuration in monorepo projects. Use this skill when reviewing PRs that touch tsconfig.json files, package.json workspace dependencies, or when migrating new services/packages into the monorepo. Enforces the TypeScript Project References Policy to ensure type graph correctness.
---

# TypeScript Config Reviewer

## Overview

Review TypeScript configuration for compliance with the monorepo's TypeScript architecture. This skill identifies
configuration issues that can cause build failures, type resolution problems, and maintainability issues.

## Architecture Summary

The monorepo uses a **simplified 2-layer tsconfig hierarchy** that separates type checking from building:

```
tsconfig.base.json          # Shared compiler options (target, lib, strict settings)
├── tsconfig.json           # Root workspace config (baseUrl: ".")
├── tsconfig.lib.json       # For libraries: adds declaration, declarationMap
├── tsconfig.app.json       # For applications: relaxed strictness
└── Project tsconfig.json   # Extends lib or app, sets rootDir/outDir
```

### Key Principles

1. **Type checking uses `tsc --noEmit`** - Simple, no composite/references needed
2. **Building uses existing tools** - `nest build`, esbuild, Next.js, etc.
3. **Package manager handles `@your-org/*` resolution** - No workspace paths in tsconfigs (local `src/*` paths allowed)
4. **ESLint uses projectService** - Reads source directly, no dist/ needed

## When to Use This Skill

- When reviewing PRs that modify `tsconfig.json` or `tsconfig*.json` files
- When reviewing PRs that add/modify workspace dependencies in `package.json`
- When migrating new packages or services into the monorepo
- When debugging type resolution issues
- When a user asks "is this tsconfig configuration correct?"

## Configuration Templates

### Package/Library tsconfig.json

Libraries that emit declarations for consumers:

```json
{
  "extends": "../../tsconfig.lib.json",
  "compilerOptions": {
    "rootDir": "./src",
    "outDir": "./dist"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.spec.ts", "**/*.test.ts"]
}
```

### NestJS Service tsconfig.json

Services that use `nest build` for runtime:

```json
{
  "extends": "../../tsconfig.app.json",
  "compilerOptions": {
    "rootDir": "./src",
    "outDir": "./dist",
    "baseUrl": "./",
    "paths": { "src/*": ["src/*"] }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

Note: NestJS services use `tsconfig.app.json` (not lib) and typically include local `src/*` path mappings. They may also have a separate `tsconfig.build.json` for `nest build` runtime compilation.

### CLI/Tool tsconfig.json

Tools with NodeNext module resolution (for ESM/CJS interop):

```json
{
  "extends": "../../../tsconfig.lib.json",
  "compilerOptions": {
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "rootDir": "src",
    "outDir": "../../../dist/path/to/tool"
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist", "**/*.spec.ts", "**/*.test.ts"]
}
```

### Next.js App

Not part of the type graph - uses local `@/*` alias:

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

## Policy Violations

### STOP-THE-LINE Violations

#### 1. Workspace Paths in tsconfig

**Detect:**

```json
{
  "compilerOptions": {
    "paths": {
      "@your-org/*": ["packages/*/src"]
    }
  }
}
```

**Why it's wrong:** Creates dual resolution (package manager workspace + TS paths), causes rootDir issues.

**Fix:** Remove paths for `@your-org/*`. The package manager workspace handles resolution automatically.

---

#### 2. Extending tsconfig.base.json for libraries

**Detect:**

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "declaration": true,
    "declarationMap": true
  }
}
```

**Why it's wrong:** Manually adding declaration settings instead of extending tsconfig.lib.json.

**Fix:**

```json
{
  "extends": "../../tsconfig.lib.json",
  "compilerOptions": {
    "rootDir": "./src",
    "outDir": "./dist"
  }
}
```

---

#### 3. noEmit with composite

**Detect:**

```json
{
  "compilerOptions": {
    "composite": true,
    "noEmit": true
  }
}
```

**Why it's wrong:** `composite: true` requires emit. This causes TS5053 error.

**Fix:** Remove `composite: true` if using `noEmit`, or remove `noEmit` if composite is needed.

---

#### 4. Using useDefineForClassFields: true with NestJS

**Detect:**

```json
{
  "compilerOptions": {
    "useDefineForClassFields": true
  }
}
```

**Why it's wrong:** Breaks NestJS class-validator DTOs that depend on property initializers.

**Fix:** Set `useDefineForClassFields: false` in tsconfig.base.json (already configured).

---

### Warnings

#### Wrong projectType for CLI tools

**Detect:** CLI tool with `projectType: "library"` in project.json

**Issue:** Causes deprecation warnings when using `generatePackageJson: true` with library projects.

**Fix:** Change to `projectType: "application"` for CLIs that have bin entries.

---

#### Missing rootDir/outDir

**Detect:**

```json
{
  "extends": "../../tsconfig.lib.json"
  // Missing rootDir and outDir
}
```

**Issue:** Output structure may be unpredictable.

**Fix:** Always specify `rootDir` and `outDir` in project tsconfigs.

## Nx Target Configuration (if using Nx)

### Typecheck Target

For standard packages:

```json
{
  "typecheck": {
    "executor": "nx:run-commands",
    "options": {
      "command": "tsc --noEmit",
      "cwd": "{projectRoot}"
    }
  }
}
```

## Verification Commands

```bash
# Check no workspace org paths exist in tsconfig (must return empty)
grep -r "paths" --include="tsconfig*.json" | grep "@your-org"

# Typecheck all projects
pnpm nx run-many -t typecheck   # Nx monorepo
# or: tsc --noEmit               # single project

# Build all projects
pnpm run build

# Test all projects
pnpm run test
```

## Review Checklist

- [ ] No workspace org paths (`@your-org/*`) in any `compilerOptions.paths`
- [ ] Libraries extend `tsconfig.lib.json`, not `tsconfig.base.json`
- [ ] All project tsconfigs have `rootDir` and `outDir`
- [ ] `useDefineForClassFields` is `false` in base config (for NestJS)
- [ ] CLI tools use `projectType: "application"` in project.json (if using Nx)
- [ ] Typecheck targets use `tsc --noEmit`

## Common Issues

### Canvas/Native Module Test Failures

For native modules (like node-canvas), create a proper Jest mock:

1. Create `__mocks__/canvas.ts` with types imported from the actual package
2. Add to jest config: `moduleNameMapper: { "^canvas$": "<rootDir>/../__mocks__/canvas.ts" }`

### ES Module Spy Failures

When `jest.spyOn()` fails on ES modules, use `jest.mock()` at the module level:

```typescript
jest.mock('fs', () => ({
  ...jest.requireActual('fs'),
  createWriteStream: jest.fn(),
}));

// Then in tests:
(fs.createWriteStream as jest.Mock).mockReturnValue(...);
```

## References

- [TypeScript Compiler Options](https://www.typescriptlang.org/tsconfig/)
- [Nx - TypeScript Monorepos](https://nx.dev/docs/features/maintain-typescript-monorepos)
- [Jest Module Mocking](https://jestjs.io/docs/manual-mocks)
