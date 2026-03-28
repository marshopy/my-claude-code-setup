---
name: type-safe-mocks
description: Use when writing TypeScript tests that mock external dependencies, or when refactoring tests with scattered `as unknown as` casts. Type-safe mocking using jest-mock-extended and the widenTo boundary-cast pattern.
---

# Type-Safe Test Mocks

## Overview

Type-safe mocking using established libraries. Three layers of protection:

1. **Compile-time**: `mockDeep<T>()` + `satisfies` validate shape
2. **Runtime**: `fallbackMockImplementation` catches unmocked access
3. **Boundary**: `widenTo()` isolates `as unknown as` to one location

**Important:** Use `mockDeep<T>()` (not `mock<T>()`) when using `fallbackMockImplementation`.

**Core principle:** Keep function signatures honest. Cast values at boundaries, not types.

## When to Use

**Always for TypeScript tests that:**
- Mock external dependencies (database clients, HTTP clients, SDK classes)
- Create partial mocks of interfaces with many methods
- Pass mocks where full implementations are expected

**Load this skill when:**
- Writing new test files
- Refactoring tests with `as unknown as` casts
- Reviewing test code for type safety

## Dependencies

**Jest projects:**
```bash
pnpm add -D jest-mock-extended@^4
```

**Vitest projects:**
```bash
pnpm add -D vitest-mock-extended@^3.1
```

## The widenTo Utility

Copy this into your project's `test-utils` package (e.g., `packages/test-utils/src/mock-boundary.ts`):

```typescript
/**
 * Creates a boundary-cast function that widens a narrow mock type to a full type.
 * Isolates all `as unknown as` casts to a single location.
 *
 * Usage:
 *   const asFullType = widenTo<FullType>();
 *   factory.mockResolvedValue(asFullType(mockObject));
 */
export function widenTo<TWide>() {
  return <TNarrow extends object>(narrow: TNarrow): TWide =>
    narrow as unknown as TWide;
}
```

Then import it in your tests:
```typescript
import { widenTo } from '@your-org/test-utils';
// or inline if not using a shared package:
// const widenTo = <W>() => <N extends object>(n: N): W => n as unknown as W;
```

## The Pattern

### 1. Import the Tools

```typescript
import { mockDeep, type DeepMockProxy } from 'jest-mock-extended';  // or vitest-mock-extended
import { widenTo } from '@your-org/test-utils';
```

### 2. Create Type-Safe Partial Mock

```typescript
// Pick only methods you need - compiler validates they exist
type MockDbClient = Pick<DatabaseClient, 'query' | 'close' | 'transaction'>;

// Use mockDeep for fallbackMockImplementation support
const mockClient = mockDeep<MockDbClient>({
  fallbackMockImplementation: () => {
    throw new Error('Unmocked DatabaseClient member accessed');
  },
});

// Configure specific methods
mockClient.query.mockResolvedValue({ rows: [] });
```

### 3. Cast at Boundary Only

```typescript
// Create boundary caster - the ONLY place `as unknown as` lives
const asDatabaseClient = widenTo<DatabaseClient>();

// Use when passing mock where full type expected
jest.mocked(DatabaseClient.connect).mockResolvedValue(asDatabaseClient(mockClient));
```

## Complete Example

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { mockDeep, type DeepMockProxy } from 'jest-mock-extended';
import { widenTo } from '@your-org/test-utils';
import { DatabaseClient } from './database-client';
import { UserService } from './user.service';

// Step 1: Define narrow mock type
type MockDbClient = Pick<DatabaseClient, 'query' | 'close'>;

// Step 2: Create boundary caster
const asDatabaseClient = widenTo<DatabaseClient>();

describe('UserService', () => {
  let service: UserService;
  let mockClient: DeepMockProxy<MockDbClient>;

  beforeEach(async () => {
    // Step 3: Create type-safe mock with runtime guard
    mockClient = mockDeep<MockDbClient>({
      fallbackMockImplementation: () => {
        throw new Error('Unmocked DatabaseClient member accessed');
      },
    });
    mockClient.query.mockResolvedValue({ rows: [{ id: 1, name: 'Alice' }] });

    // Step 4: Cast at boundary when setting up mocked factory
    jest.mocked(DatabaseClient.connect)
      .mockResolvedValue(asDatabaseClient(mockClient));

    const module: TestingModule = await Test.createTestingModule({
      providers: [UserService],
    }).compile();

    service = module.get(UserService);
  });

  it('should return users', async () => {
    const users = await service.findAll();
    expect(users).toHaveLength(1);
    expect(mockClient.query).toHaveBeenCalled();
  });
});
```

## Decision Matrix

| Situation | Use |
|-----------|-----|
| Mock entire interface (simple) | `mock<T>()` |
| Mock entire interface + runtime guard | `mockDeep<T>()` with `fallbackMockImplementation` |
| Mock subset of methods | `mockDeep<Pick<T, 'a' \| 'b'>>()` |
| Validate mock shape at compile time | `satisfies` on object literal |
| Catch unmocked access at runtime | `mockDeep` + `fallbackMockImplementation` |
| Pass partial mock as full type | `widenTo<T>()` at boundary |
| Scattered `as unknown as` | Refactor to `widenTo()` |

## The Three Protections

### 1. Compile-Time: `mockDeep<T>()` + `Pick` + `satisfies`

```typescript
// Compiler ensures 'query' and 'close' exist on DatabaseClient
type MockDbClient = Pick<DatabaseClient, 'query' | 'close'>;

// mockDeep<T>() returns DeepMockProxy<T> with full type safety
const mockClient = mockDeep<MockDbClient>();

// satisfies validates object literal shape
const manualMock = {
  query: jest.fn().mockResolvedValue({ rows: [] }),
  close: jest.fn(),
} satisfies MockDbClient;
```

### 2. Runtime: `fallbackMockImplementation`

```typescript
// IMPORTANT: Use mockDeep (not mock) for fallbackMockImplementation
const mockClient = mockDeep<MockDbClient>({
  fallbackMockImplementation: () => {
    throw new Error('Unmocked member accessed - add to Pick<> type');
  },
});

// Now if code calls mockClient.transaction() (not in Pick), test fails fast
// Instead of silent undefined behavior
```

### 3. Boundary: `widenTo<T>()`

```typescript
// The ONLY place type widening happens
const asDatabaseClient = widenTo<DatabaseClient>();
jest.mocked(factory).mockResolvedValue(asDatabaseClient(mockClient));
```

## Anti-Patterns

### DON'T: Scatter `as unknown as` Throughout Tests

```typescript
// ❌ BAD - type lie at every call site
mockFactory.mockResolvedValue(mockClient as unknown as DatabaseClient);
mockFactory.mockResolvedValueOnce(adminClient as unknown as DatabaseClient);
```

```typescript
// ✅ GOOD - single boundary caster
const asDbClient = widenTo<DatabaseClient>();
mockFactory.mockResolvedValue(asDbClient(mockClient));
mockFactory.mockResolvedValueOnce(asDbClient(adminClient));
```

### DON'T: Redefine Function Signatures

```typescript
// ❌ BAD - lying about what connect returns
type ConnectMock = jest.MockedFunction<
  (options: any) => Promise<MockDbClient>  // Changed return type!
>;
const mockConnect = fn as unknown as ConnectMock;
```

```typescript
// ✅ GOOD - keep real signature, cast value at boundary
jest.mocked(DatabaseClient.connect)  // Real signature preserved
  .mockResolvedValue(asDatabaseClient(mockClient));  // Cast only the value
```

### DON'T: Skip Runtime Guards

```typescript
// ❌ BAD - no runtime protection
const mockClient = mock<MockDbClient>();
// If code calls unmocked method, silent failure
```

```typescript
// ✅ GOOD - fail fast on unmocked access (use mockDeep for this feature)
const mockClient = mockDeep<MockDbClient>({
  fallbackMockImplementation: () => {
    throw new Error('Unmocked member accessed');
  },
});
```

## ESLint Enforcement

See [references/eslint-config.md](./references/eslint-config.md) for configuration to:
- Flag `as unknown as` outside of `mock-boundary.ts`
- Require `fallbackMockImplementation` in `mock<T>()` calls

## Migration Guide

See [references/migration-guide.md](./references/migration-guide.md) for:
- Step-by-step migration from scattered casts
- Common patterns and their replacements
- Checklist for refactoring existing tests

## Package Setup

See [references/package-setup.md](./references/package-setup.md) for instructions on setting up a shared `test-utils` package in your monorepo.

## Quick Reference

```typescript
// Imports
import { mockDeep, type DeepMockProxy } from 'jest-mock-extended';
import { widenTo } from '@your-org/test-utils';

// Type definition
type MockT = Pick<FullType, 'methodA' | 'methodB'>;

// Boundary caster
const asFullType = widenTo<FullType>();

// Create mock with guard (use mockDeep for fallbackMockImplementation)
const mockT = mockDeep<MockT>({
  fallbackMockImplementation: () => { throw new Error('unmocked'); },
});

// Configure methods
mockT.methodA.mockResolvedValue(result);

// Use at boundary
mockFactory.mockResolvedValue(asFullType(mockT));
```
