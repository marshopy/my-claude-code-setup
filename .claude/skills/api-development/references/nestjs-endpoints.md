# Creating NestJS Endpoints

Guide for creating API endpoints in NestJS backend services using Zod schemas.

## Step 0: Check Existing Config Before Adding Env Vars

**Before adding any new environment variable**, search for existing configuration patterns:

```bash
# Check config factory for existing env var mappings
grep -r "process.env" services/*/src/config/

# Check config schema for existing env var definitions
cat services/<service>/src/config/config.schema.ts

# Check .env.example for documented env vars
cat services/<service>/.env.example
```

Always use existing config keys rather than creating new ones that may not be deployed.

## Step 1: Check for Shared Zod Schemas

Before creating types, check if they exist in shared packages:

```bash
# Check api-types for existing schemas
grep -r "Schema" packages/api-types/src/

# Check if similar types exist elsewhere
grep -r "YourTypeName" services/*/src/
```

## Step 2: Import Shared Zod Schemas and Types

```typescript
// Use shared Zod schemas and inferred types
import {
  ApiResponseSchema,
  ErrorResponseSchema,
  type ApiResponse,
  type ErrorResponse
} from '@your-org/api-types';
```

## Step 3: Create Domain-Specific Schemas

For domain-specific types (not shared), define Zod schemas in the service:

```typescript
// services/my-service/src/items/schemas/item.schema.ts
import { z } from 'zod';

// Define schema with Zod
export const CreateItemSchema = z.object({
  title: z.string().min(1).describe('Item title'),
  type: z.enum(['type_a', 'type_b']).describe('Item type'),
  description: z.string().optional().describe('Optional description'),
});

// Infer the type - NEVER define separately
export type CreateItemDto = z.infer<typeof CreateItemSchema>;

// Response schema
export const ItemResponseSchema = z.object({
  id: z.string().uuid(),
  title: z.string(),
  type: z.enum(['type_a', 'type_b']),
  description: z.string().nullable(),
  created_at: z.string().datetime(),
  updated_at: z.string().datetime(),
});

export type ItemResponse = z.infer<typeof ItemResponseSchema>;
```

## Step 4: Use with NestJS (ZodValidationPipe)

```typescript
// services/my-service/src/items/items.controller.ts
import { Controller, Get, Post, Body, Param, Query, UsePipes } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { ZodValidationPipe } from '@anatine/zod-nestjs';
import {
  CreateItemSchema,
  type CreateItemDto,
  type ItemResponse
} from './schemas/item.schema';

@ApiTags('items')
@Controller('items')
export class ItemsController {
  @Post()
  @ApiOperation({ operationId: 'createItem', summary: 'Create a new item' })
  @UsePipes(new ZodValidationPipe(CreateItemSchema))
  async create(@Body() dto: CreateItemDto): Promise<ApiResponse<ItemResponse>> {
    // dto is validated by Zod
  }
}
```

## Alternative: Manual Validation in Service Layer

```typescript
// If not using ZodValidationPipe, validate manually
async create(input: unknown): Promise<ApiResponse<ItemResponse>> {
  const dto = CreateItemSchema.parse(input); // throws on invalid
  // or use .safeParse() for error handling
}
```

## OpenAPI Annotations

All endpoints must have:

1. **Operation ID**: Unique identifier for the operation
2. **Summary**: Brief description (< 80 chars)
3. **Response schemas**: All possible response types documented

```typescript
@ApiOperation({
  operationId: 'getItem',
  summary: 'Get a single item by ID',
})
@ApiResponse({ status: 200, type: ItemResponseDto })
@ApiResponse({ status: 404, type: ErrorResponseDto })
@Get(':id')
async getItem(@Param('id') id: string) { ... }
```

## Controller/Service Pattern

Controllers should be **thin wrappers** that handle:
- Request/response mapping
- Authorization (guards and decorators)
- Input validation (via DTOs/Zod)
- Delegating to services for business logic

**DO - Thin Controller:**
```typescript
@Controller('items')
@UseGuards(AuthGuard)
export class ItemsController {
  constructor(private readonly itemsService: ItemsService) {}

  @Post()
  async create(@Body() dto: CreateItemDto, @User() user: AuthenticatedUser) {
    return this.itemsService.create(dto, user.id);
  }
}
```

**DON'T - Fat Controller:**
```typescript
@Controller('items')
export class ItemsController {
  @Post()
  async create(@Body() dto: CreateItemDto) {
    // BAD: Business logic in controller
    const validated = await this.validate(dto);
    const file = await this.storage.upload(validated);
    const record = await this.db.create(file);
    await this.events.emit(record);
    return record;
  }
}
```

## Testing API Endpoints

### Schema Validation in Tests

Validate responses against shared schemas:

```typescript
import { ItemResponseSchema } from '@your-org/api-types';

describe('ItemsController', () => {
  it('should return valid item response', async () => {
    const response = await request(app).post('/items').send(payload);

    // Validate against schema - throws if invalid
    const parsed = ItemResponseSchema.parse(response.body.data);
    expect(parsed.id).toBeDefined();
  });
});
```

### Authentication in Tests

**NEVER bypass authentication in tests.**

```typescript
import { createTestAuthHeaders } from '../utils/test-auth.utils';

describe('ItemsController', () => {
  it('should require authentication', async () => {
    const response = await request(app).get('/items');
    expect(response.status).toBe(401);
  });

  it('should work with valid auth', async () => {
    const headers = createTestAuthHeaders({ userId: 'test-user' });
    const response = await request(app).get('/items').set(headers);
    expect(response.status).toBe(200);
  });
});
```

### Verification Checklist for API Tests

- [ ] Controller/service returns data matching shared schemas
- [ ] Verify snake_case field naming per API Style Guide
- [ ] Run schema validation tests (Zod `.parse()` or `.safeParse()`)
- [ ] Test both authenticated and unauthenticated access
- [ ] Test authorization (user can only access their resources)
