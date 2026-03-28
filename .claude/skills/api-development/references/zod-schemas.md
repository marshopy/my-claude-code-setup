# Zod-First Development

All new shared API types MUST be defined as Zod schemas. This provides:

- Single source of truth (schema = type = validation)
- Static OpenAPI generation via `zod-to-openapi`
- Runtime validation for request/response handling
- Cross-language client generation

## Defining Shared Schemas

```typescript
// packages/api-types/src/common/api-response.ts
import { z } from 'zod';
import { extendZodWithOpenApi } from '@asteasolutions/zod-to-openapi';

extendZodWithOpenApi(z);

// Define the schema with OpenAPI metadata
export const ApiResponseSchema = <T extends z.ZodTypeAny>(dataSchema: T) =>
  z.object({
    data: dataSchema,
    meta: z.object({
      timestamp: z.string().datetime().optional(),
      version: z.string().optional(),
    }).optional(),
  }).openapi('ApiResponse');

// Infer the type from the schema - NEVER define types separately
export type ApiResponse<T> = {
  data: T;
  meta?: { timestamp?: string; version?: string };
};

// Error response schema
export const ErrorResponseSchema = z.object({
  errors: z.array(z.object({
    code: z.string(),
    message: z.string(),
    details: z.record(z.unknown()).optional(),
  })),
}).openapi('ErrorResponse');

export type ErrorResponse = z.infer<typeof ErrorResponseSchema>;
```

## Defining Shared Enums

```typescript
// packages/api-types/src/enums/item-type.ts
import { z } from 'zod';

// Define enum as Zod schema - lowercase values per style guide
export const ItemTypeSchema = z.enum(['type_a', 'type_b', 'type_c']).openapi('ItemType');

// Infer the type
export type ItemType = z.infer<typeof ItemTypeSchema>;
```

## Generating OpenAPI from Zod

```typescript
// packages/api-types/src/openapi.ts
import { OpenAPIRegistry, OpenApiGeneratorV3 } from '@asteasolutions/zod-to-openapi';
import { ApiResponseSchema, ErrorResponseSchema } from './common';

const registry = new OpenAPIRegistry();

// Register all schemas
registry.register('ErrorResponse', ErrorResponseSchema);

// Generate OpenAPI spec
const generator = new OpenApiGeneratorV3(registry.definitions);
export const openApiSpec = generator.generateDocument({
  openapi: '3.0.3',
  info: { title: 'API Types', version: '1.0.0' },
});
```

## Using Zod Schemas for Validation

```typescript
// In any service
import { ApiResponseSchema } from '@your-org/api-types';

// Validate response from downstream service
const response = await fetch('/api/items');
const json = await response.json();

const parsed = ApiResponseSchema(ItemSchema).safeParse(json);
if (!parsed.success) {
  console.error('Invalid response:', parsed.error);
}
```

## Using Schemas in Backend Services

Backend services use Zod schemas for validation via `createZodDto()`:

```typescript
// services/my-service/src/items/dtos/create-item.dto.ts
import { createZodDto } from 'nestjs-zod';
import { CreateItemRequestSchema } from '@your-org/api-types';

// One-liner - derives validation and types from shared schema
export class CreateItemDto extends createZodDto(CreateItemRequestSchema) {}
```

## Anti-Patterns (Do NOT Do This)

```typescript
// WRONG: Defining type separately from schema
export interface Example {
  id: string;
  name: string;
}
export const ExampleSchema = z.object({ ... }); // Types can drift!

// WRONG: Using class-validator for new shared types
export class ExampleDto {
  @IsString()
  id: string;
}

// WRONG: Not adding OpenAPI metadata
export const ExampleSchema = z.object({ ... }); // Missing .openapi()
```

## Query Parameter Schemas

HTTP query parameters are **always strings**. Zod's `z.boolean()`, `z.number()`, etc. expect JavaScript primitives and
will reject string values.

### Problem

```typescript
// ❌ WRONG - ?active=true sends string "true"
export const QuerySchema = z.object({
  active: z.boolean().optional(),
  // Error: "Expected boolean, received string"
});

// ❌ WRONG - ?limit=10 sends string "10"
export const ListQuerySchema = z.object({
  limit: z.number().int().min(1).max(100),
  // Error: "Expected number, received string"
});
```

### Solutions

**For booleans - use enum + transform:**

```typescript
export const QuerySchema = z.object({
  active: z
    .enum(['true', 'false'])
    .transform((v) => v === 'true')
    .optional()
    .openapi({
      description: 'Filter by active status',
      example: 'true',
    }),
});
```

**For numbers - use coerce:**

```typescript
export const ListQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(10).openapi({
    description: 'Maximum items to return',
    example: 10,
  }),
  offset: z.coerce.number().int().min(0).default(0).openapi({
    description: 'Number of items to skip',
    example: 0,
  }),
});
```

**For arrays - handle comma-separated:**

```typescript
export const FilterQuerySchema = z.object({
  // ?types=a,b,c → ['a', 'b', 'c']
  types: z
    .string()
    .transform((v) => v.split(',').filter(Boolean))
    .pipe(z.array(ItemTypeSchema))
    .optional()
    .openapi({
      description: 'Filter by types (comma-separated)',
      example: 'type_a,type_b',
    }),
});
```

### Quick Reference

| Type    | Query String   | Zod Pattern                                            |
| ------- | -------------- | ------------------------------------------------------ |
| Boolean | `?flag=true`   | `z.enum(['true','false']).transform(v => v === 'true')` |
| Number  | `?limit=10`    | `z.coerce.number()`                                    |
| Integer | `?page=1`      | `z.coerce.number().int()`                              |
| Array   | `?ids=a,b,c`   | `z.string().transform(v => v.split(','))`              |
| Enum    | `?status=active` | `z.enum([...])` (strings work directly)              |

## Dependencies

```json
{
  "dependencies": {
    "zod": "^3.23.0",
    "@asteasolutions/zod-to-openapi": "^7.0.0"
  }
}
```
