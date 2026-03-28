# Troubleshooting

Common issues and solutions for API development.

## "Module not found: @your-org/api-types"

```bash
# Rebuild the package
pnpm run build  # from packages/api-types/

# Or rebuild all
pnpm install && pnpm run build
```

## "Enum values don't match between services"

Check for case inconsistency:

```bash
# Find all enum definitions
grep -r "enum ItemType" services/*/src/ packages/*/src/

# Find Zod enum schemas
grep -r "z.enum" packages/api-types/src/
```

Standardize on lowercase per style guide:

```typescript
// Correct - Zod schema
export const ItemTypeSchema = z.enum(['type_a', 'type_b']).openapi('ItemType');

// Incorrect
export const ItemTypeSchema = z.enum(['TYPE_A', 'TYPE_B']); // uppercase - don't do this
```

## "OpenAPI export fails"

### For NestJS (legacy)

Ensure AppModule is properly exported:

```typescript
// services/my-service/src/app.module.ts
@Module({ ... })
export class AppModule {}  // Must be named export
```

### For Zod

Ensure all schemas are registered:

```typescript
// packages/api-types/src/openapi.ts
const registry = new OpenAPIRegistry();

// Must register each schema
registry.register('ItemType', ItemTypeSchema);
registry.register('ErrorResponse', ErrorResponseSchema);
```

## "Generated client has wrong types"

Regenerate after API changes:

```bash
# 1. Re-export OpenAPI spec (Zod)
pnpm run openapi:export

# 2. Regenerate models
./scripts/openapi/generate-python-client.sh services/my-service/openapi.json libs/my-service-client/my_service_client/models.py

# 3. Rebuild dependent services
pnpm run build
```

## "Zod schema doesn't appear in OpenAPI"

Ensure you're calling `.openapi()` with a name:

```typescript
// Wrong - won't appear in OpenAPI
export const MySchema = z.object({ ... });

// Correct - appears as "MyType" in OpenAPI
export const MySchema = z.object({ ... }).openapi('MyType');
```

## "Type inference not working"

Ensure you're using `z.infer`:

```typescript
// Wrong - types can drift
export interface MyType {
  id: string;
}
export const MySchema = z.object({ id: z.string() });

// Correct - type is always in sync
export const MySchema = z.object({ id: z.string() });
export type MyType = z.infer<typeof MySchema>;
```

## "Validation errors not descriptive"

Use `.describe()` to add field descriptions:

```typescript
export const CreateItemSchema = z.object({
  title: z.string().min(1).describe('Item title (required)'),
  count: z.number().int().positive().describe('Must be a positive integer'),
});
```

## File Locations Reference

| Purpose | Location |
|---------|----------|
| Shared Zod schemas + types | `packages/api-types/src/` |
| Spectral config | `.spectral.yaml` |
| OpenAPI export scripts | `scripts/openapi/` |
| Generated Python clients | `libs/<service>-client/` |
| Generated TS clients | `packages/<service>-client/` |
| OpenAPI specs (services) | `services/<service>/openapi.json` |
