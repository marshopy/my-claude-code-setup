# Migration Guide: class-validator to Zod

Guide for migrating existing class-validator DTOs to Zod schemas.

## When to Migrate

Migrate types to Zod schemas in shared packages when:

1. **Identical DTOs exist in multiple services** (copy-paste duplication)
2. **Cross-service communication** requires shared types
3. **Frontend and backend** need consistent types
4. **Runtime validation** is needed (Zod provides this automatically)

## Migration Checklist

- [ ] Check if schema already exists in `@your-org/api-types`
- [ ] If not, create Zod schema in `@your-org/api-types`
- [ ] Export inferred type alongside schema
- [ ] Update imports in all consuming services
- [ ] Delete the local class-validator based DTO
- [ ] Run `pnpm run build` to verify

## Step-by-Step Migration

### 1. Identify Duplicate

```bash
# Find duplicates (class-validator DTOs)
grep -r "ApiResponseDto" services/*/src/ apps/*/src/

# Find existing Zod schemas
grep -r "Schema" packages/api-types/src/
```

### 2. Add Zod Schema to Shared Package

```typescript
// packages/api-types/src/common/api-response.ts
import { z } from 'zod';
import { extendZodWithOpenApi } from '@asteasolutions/zod-to-openapi';

extendZodWithOpenApi(z);

// Define schema with OpenAPI metadata
export const ApiResponseSchema = <T extends z.ZodTypeAny>(dataSchema: T) =>
  z.object({
    data: dataSchema,
    meta: z.object({
      timestamp: z.string().datetime().optional(),
      version: z.string().optional(),
    }).optional(),
  }).openapi('ApiResponse');

// Infer the type - NEVER duplicate manually
export type ApiResponse<T> = {
  data: T;
  meta?: { timestamp?: string; version?: string };
};
```

### 3. Export from Index

```typescript
// packages/api-types/src/common/index.ts
export * from './api-response';
```

### 4. Update Consumers

```typescript
// Before (class-validator DTO)
import { ApiResponseDto } from '../common/dto/api-response.dto';

// After (Zod schema + inferred type)
import { ApiResponseSchema, type ApiResponse } from '@your-org/api-types';
```

### 5. Delete Local Copy

```bash
rm services/my-service/src/common/dto/api-response.dto.ts
```

### 6. Verify Build

```bash
pnpm run build
pnpm run lint
```

## Common Migration Patterns

### class-validator class → Zod schema

**Before:**
```typescript
import { IsString, IsOptional, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateItemDto {
  @ApiProperty({ description: 'Item title' })
  @IsString()
  title: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ enum: ItemType })
  @IsEnum(ItemType)
  type: ItemType;
}
```

**After:**
```typescript
import { z } from 'zod';
import { extendZodWithOpenApi } from '@asteasolutions/zod-to-openapi';

extendZodWithOpenApi(z);

export const CreateItemSchema = z.object({
  title: z.string().min(1).describe('Item title'),
  description: z.string().optional().describe('Optional description'),
  type: z.enum(['type_a', 'type_b']).describe('Item type'),
}).openapi('CreateItem');

export type CreateItemDto = z.infer<typeof CreateItemSchema>;
```

### TypeScript enum → Zod enum

**Before:**
```typescript
export enum ItemType {
  TYPE_A = 'TYPE_A',
  TYPE_B = 'TYPE_B',
}
```

**After:**
```typescript
// Use lowercase values per style guide
export const ItemTypeSchema = z.enum(['type_a', 'type_b']).openapi('ItemType');
export type ItemType = z.infer<typeof ItemTypeSchema>;
```
