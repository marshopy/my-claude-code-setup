# Migration Guide: Type-Safe Mocks

**Load this reference when:** refactoring existing tests to use type-safe mocking patterns.

## Prerequisites

1. Install dependencies:
   ```bash
   pnpm add -D jest-mock-extended@^4  # or vitest-mock-extended@^3.1
   ```

2. Ensure `@your-org/test-utils` is available (see package-setup.md)

## Step-by-Step Migration

### Step 1: Identify Scattered Casts

```bash
# Find all "as unknown as" in test files
grep -rn "as unknown as" --include="*.spec.ts" --include="*.test.ts"
```

### Step 2: Group by Target Type

For each unique target type (e.g., `GlideClient`, `ValkeyConnectionService`), you'll create:
- One `Pick<T, ...>` type alias
- One `widenTo<T>()` caster

### Step 3: Create Narrow Mock Type

**Before:**
```typescript
const mockClient = {
  ping: jest.fn().mockResolvedValue('PONG'),
  close: jest.fn(),
} as unknown as GlideClient;  // Scattered cast
```

**After:**
```typescript
import { mockDeep, type DeepMockProxy } from 'jest-mock-extended';
import { widenTo } from '@your-org/test-utils';

// Narrow type - only methods we mock
type MockGlideClient = Pick<GlideClient, 'ping' | 'close'>;

// Boundary caster - defined once per target type
const asGlideClient = widenTo<GlideClient>();

// Type-safe mock with runtime guard
const mockClient = mockDeep<MockGlideClient>({
  fallbackMockImplementation: () => {
    throw new Error('Unmocked GlideClient member accessed');
  },
});
mockClient.ping.mockResolvedValue('PONG');
```

### Step 4: Replace All Casts with Boundary Caster

**Before (multiple casts):**
```typescript
mockFactory.mockResolvedValue(mockClient as unknown as GlideClient);
mockFactory.mockResolvedValueOnce(adminClient as unknown as GlideClient);
mockCallback(mockClient as unknown as GlideClient);
```

**After (single caster):**
```typescript
const asGlideClient = widenTo<GlideClient>();

mockFactory.mockResolvedValue(asGlideClient(mockClient));
mockFactory.mockResolvedValueOnce(asGlideClient(adminClient));
mockCallback(asGlideClient(mockClient));
```

### Step 5: Add Runtime Guards

**Before:**
```typescript
const mockClient = {
  ping: jest.fn(),
  close: jest.fn(),
};
// If code calls xadd(), silent undefined
```

**After:**
```typescript
const mockClient = mockDeep<MockGlideClient>({
  fallbackMockImplementation: () => {
    throw new Error('Unmocked GlideClient member accessed - add to Pick<> type');
  },
});
// If code calls xadd(), test fails fast with clear message
```

## Common Patterns

### Pattern 1: Mocked Module Functions

**Before:**
```typescript
jest.mock('@valkey/valkey-glide');

type CreateClientMock = jest.MockedFunction<
  (options: any) => Promise<MockGlideClient>  // Redefined return type
>;

const mockCreateClient = GlideClient.createClient as unknown as CreateClientMock;
mockCreateClient.mockResolvedValue(mockClient);
```

**After:**
```typescript
jest.mock('@valkey/valkey-glide');

const asGlideClient = widenTo<GlideClient>();

// Keep real function signature
jest.mocked(GlideClient.createClient).mockResolvedValue(asGlideClient(mockClient));
```

### Pattern 2: Service Mocks for DI

**Before:**
```typescript
const mockService = {
  isEnabled: jest.fn().mockReturnValue(true),
  executeWithRecovery: jest.fn().mockImplementation(async (fn) => fn(mockClient)),
} as unknown as ValkeyConnectionService;
```

**After:**
```typescript
type MockValkeyService = Pick<ValkeyConnectionService, 'isEnabled' | 'executeWithRecovery'>;

const asValkeyService = widenTo<ValkeyConnectionService>();

const mockService = mockDeep<MockValkeyService>({
  fallbackMockImplementation: () => { throw new Error('unmocked'); },
});
mockService.isEnabled.mockReturnValue(true);
mockService.executeWithRecovery.mockImplementation(async (fn) =>
  fn(asGlideClient(mockClient))
);

// When providing to NestJS module
{
  provide: ValkeyConnectionService,
  useValue: asValkeyService(mockService),
}
```

### Pattern 3: Slow Promises for Concurrency Tests

**Before:**
```typescript
let resolveCreation: (value: MockGlideClient) => void;
const slowCreation = new Promise<MockGlideClient>((resolve) => {
  resolveCreation = resolve;
});

mockCreateClient.mockReturnValue(slowCreation);  // Type mismatch if signature preserved
```

**After:**
```typescript
type GlideClientReturn = Awaited<ReturnType<typeof GlideClient.createClient>>;

let resolveCreation: (value: GlideClientReturn) => void;
const slowCreation = new Promise<GlideClientReturn>((resolve) => {
  resolveCreation = resolve;
});

jest.mocked(GlideClient.createClient).mockReturnValue(slowCreation);

// When resolving, cast at boundary
resolveCreation!(asGlideClient(mockClient));
```

### Pattern 4: Admin/Special Clients

**Before:**
```typescript
const adminClient = {
  ...mockClient,
  customCommand: jest.fn().mockResolvedValueOnce(response),
} as unknown as GlideClient;
```

**After:**
```typescript
// Extend narrow type with additional method
type MockAdminClient = Pick<GlideClient, 'ping' | 'close' | 'customCommand'>;

const adminClient = mockDeep<MockAdminClient>({
  fallbackMockImplementation: () => { throw new Error('unmocked'); },
});
adminClient.customCommand.mockResolvedValueOnce(response);

mockFactory.mockResolvedValueOnce(asGlideClient(adminClient));
```

## Migration Checklist

For each test file:

- [ ] Install `jest-mock-extended` or `vitest-mock-extended`
- [ ] Import `widenTo` from `@your-org/test-utils`
- [ ] Create `Pick<T, ...>` type for each mocked interface
- [ ] Create `widenTo<T>()` caster for each target type
- [ ] Replace manual mock objects with `mockDeep<T>()` calls (use `mockDeep` for `fallbackMockImplementation`)
- [ ] Add `fallbackMockImplementation` to all `mockDeep()` calls
- [ ] Replace all `as unknown as T` with caster function
- [ ] Run tests to verify behavior unchanged
- [ ] Run ESLint to verify no remaining `as unknown as`

## Rollback Strategy

If migration causes issues:

1. Keep both patterns temporarily
2. Use feature flag or gradual rollout
3. The old pattern still works - migration is improvement, not breaking change

## Validation

After migration:

```bash
# Should find no results outside test-utils
grep -rn "as unknown as" --include="*.spec.ts" --include="*.test.ts" | grep -v "mock-boundary"

# Run tests
pnpm test

# Run typecheck
pnpm typecheck
```
