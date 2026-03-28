# Test Utils Package Setup

**Load this reference when:** setting up a shared test utilities package or troubleshooting imports.

## Package Location

```
packages/test-utils/
├── src/
│   ├── index.ts           # Main exports
│   └── mock-boundary.ts   # widenTo function
├── package.json
└── tsconfig.json
```

## Installation

The package is a workspace dependency. Add to any service's `package.json`:

```json
{
  "devDependencies": {
    "@your-org/test-utils": "workspace:*"
  }
}
```

Then run:
```bash
pnpm install  # or npm install / yarn install
```

## The `widenTo` Function

```typescript
// packages/test-utils/src/mock-boundary.ts

/**
 * Creates a boundary caster for widening narrow mock types to full types.
 *
 * This is the ONLY place in the codebase where `as unknown as` is allowed
 * for test mocking. All other test files should use this function instead
 * of inline casts.
 *
 * @example
 * const asClient = widenTo<DatabaseClient>();
 * mockFactory.mockResolvedValue(asClient(mockClient));
 *
 * @template TWide - The full type expected by the API
 * @returns A function that casts a narrow mock to the wide type
 */
export function widenTo<TWide>() {
  return <TNarrow extends object>(narrow: TNarrow): TWide =>
    narrow as unknown as TWide;
}
```

## TypeScript Configuration

```json
// packages/test-utils/tsconfig.json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "declaration": true,
    "declarationMap": true,
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

## Package.json

```json
// packages/test-utils/package.json
{
  "name": "@your-org/test-utils",
  "version": "0.0.1",
  "private": true,
  "main": "./dist/src/index.js",
  "types": "./dist/src/index.d.ts",
  "exports": {
    ".": {
      "types": "./dist/src/index.d.ts",
      "import": "./dist/src/index.js",
      "require": "./dist/src/index.js"
    }
  },
  "scripts": {
    "build": "tsc -p tsconfig.build.json",
    "clean": "rm -rf dist"
  },
  "devDependencies": {
    "typescript": "^5.7.0"
  }
}
```

## Path Mapping (tsconfig.base.json)

```json
{
  "compilerOptions": {
    "paths": {
      "@your-org/test-utils": ["packages/test-utils/src/index.ts"],
      "@your-org/test-utils/*": ["packages/test-utils/src/*"]
    }
  }
}
```

## Import Style

```typescript
import { widenTo } from '@your-org/test-utils';
```

## Alternative: Inline the Function

If you don't want a shared package, inline `widenTo` directly in a test utility file:

```typescript
// src/__tests__/utils/mock-boundary.ts
export function widenTo<TWide>() {
  return <TNarrow extends object>(narrow: TNarrow): TWide =>
    narrow as unknown as TWide;
}
```

Then import locally:
```typescript
import { widenTo } from '../utils/mock-boundary';
```

## Troubleshooting

### "Cannot find module '@your-org/test-utils'"

1. Verify `pnpm install` was run
2. Check path mapping in `tsconfig.base.json`
3. Rebuild the package: `pnpm run build` (from package root)

### "widenTo is not a function"

1. Check import path is correct
2. Verify package was built
3. Check `exports` field in package.json
