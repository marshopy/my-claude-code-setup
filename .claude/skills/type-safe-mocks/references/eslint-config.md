# ESLint Configuration for Type-Safe Mocks

**Load this reference when:** configuring ESLint rules for test files or reviewing type assertions.

## Detecting `as unknown as` Pattern

Add to your `eslint.config.mjs` to flag `as unknown as` outside the boundary file:

```javascript
// eslint.config.mjs
import tseslint from 'typescript-eslint';

export default tseslint.config(
  // ... other configs

  // Flag "as unknown as" pattern in test files
  {
    files: ['**/*.spec.ts', '**/*.test.ts', '**/__tests__/**/*.ts'],
    rules: {
      'no-restricted-syntax': [
        'error',
        {
          // Matches: expr as unknown as Type
          selector: 'TSAsExpression[expression.type="TSAsExpression"][expression.typeAnnotation.type="TSUnknownKeyword"]',
          message: 'Use widenTo() from @your-org/test-utils instead of "as unknown as". See type-safe-mocks skill.',
        },
      ],
    },
  },

  // Allow in the boundary file itself
  {
    files: ['**/mock-boundary.ts', '**/test-utils/**/*.ts'],
    rules: {
      'no-restricted-syntax': 'off',
    },
  },
);
```

## Why This Rule

The `as unknown as` pattern:

1. **Bypasses type checking** - No compile-time validation
2. **Scatters type lies** - Hard to find and audit
3. **Hides breaking changes** - API changes don't trigger errors

By restricting to one file (`mock-boundary.ts`), we:

1. **Centralize the tradeoff** - One place to audit
2. **Document the intent** - `widenTo()` name explains purpose
3. **Enable grep-based review** - Find all boundary casts easily

## Alternative: TypeScript Configuration

For stricter projects, consider also enabling:

```json
// tsconfig.json
{
  "compilerOptions": {
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true
  }
}
```

These don't catch `as unknown as` directly but reduce overall type unsafety.

## Checking for Violations

```bash
# Find all "as unknown as" in test files
grep -rn "as unknown as" --include="*.spec.ts" --include="*.test.ts"

# Should only show results in mock-boundary.ts or test-utils
```

## Integration with CI

Add to your CI pipeline:

```yaml
- name: Check for scattered type casts
  run: |
    # Fail if "as unknown as" appears outside allowed files
    violations=$(grep -rn "as unknown as" --include="*.spec.ts" --include="*.test.ts" \
      | grep -v "mock-boundary" | grep -v "test-utils" || true)

    if [ -n "$violations" ]; then
      echo "Found 'as unknown as' outside mock-boundary.ts:"
      echo "$violations"
      exit 1
    fi
```

## Enforcing `fallbackMockImplementation`

For stricter enforcement, consider a custom ESLint rule or code review checklist:

```typescript
// ❌ Should flag: mockDeep() without fallbackMockImplementation
const mockClient = mockDeep<MockGlideClient>();

// ✅ Should pass: mockDeep() with fallbackMockImplementation
const mockClient = mockDeep<MockGlideClient>({
  fallbackMockImplementation: () => { throw new Error('unmocked'); },
});
```

**Note:** Use `mockDeep` (not `mock`) when using `fallbackMockImplementation`.

This is harder to enforce via ESLint selectors, so rely on code review and the skill documentation.

## Example Violation and Fix

**Before (ESLint error):**
```typescript
// connection.factory.spec.ts
mockFactory.createClientWithRetry.mockResolvedValue(
  adminClient as unknown as GlideClient  // ❌ ESLint: Use widenTo()
);
```

**After (passes):**
```typescript
// connection.factory.spec.ts
import { widenTo } from '@your-org/test-utils';

const asGlideClient = widenTo<GlideClient>();

mockFactory.createClientWithRetry.mockResolvedValue(
  asGlideClient(adminClient)  // ✅ Boundary cast
);
```
