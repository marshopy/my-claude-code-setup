# Cross-Language Client Generation

Guide for generating typed clients for cross-service communication.

## When to Generate Clients

| Scenario | Generate Client? | Reason |
|----------|-----------------|--------|
| TypeScript service calls TypeScript service | Maybe | Consider direct HTTP with shared types first |
| Python service calls TypeScript service | **Yes** | Need Pydantic models from OpenAPI |
| TypeScript service calls Python service | **Yes** | Need TypeScript types from OpenAPI |
| Frontend calls any backend | **Yes** | Type-safe API client |

## Workflow Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Source Service │────▶│   OpenAPI Spec  │────▶│ Generated Client│
│  (TS or Python) │     │  (openapi.json) │     │   (TS or Py)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

## TypeScript → Python

### Step 1: Export OpenAPI from Zod Schemas (Preferred)

For shared types in `@your-org/api-types`, generate OpenAPI statically:

```bash
# No server needed - generates from Zod schemas
pnpm run openapi:export
# Creates packages/api-types/openapi.json
```

### Step 1 (Legacy): Export OpenAPI from NestJS Service

For NestJS services not yet using Zod, fetch from running server:

```bash
# Start service
pnpm run start:dev

# Fetch spec (in another terminal)
./scripts/openapi/fetch-spec.sh http://localhost:3000 services/my-service/openapi.json
```

### Step 2: Generate Python Models

```bash
./scripts/openapi/generate-python-client.sh \
  services/my-service/openapi.json \
  libs/my-service-client/my_service_client/models.py
```

This creates:

```
libs/my-service-client/my_service_client/
├── models.py      # Pydantic v2 models
└── py.typed       # PEP 561 marker (auto-generated)
```

**Important:** The generator automatically creates a `py.typed` marker file ([PEP 561](https://peps.python.org/pep-0561/)) in the output directory. This is required for mypy to type-check code that imports from the generated models.

### Generator: datamodel-code-generator

We use [datamodel-code-generator](https://github.com/koxudaxi/datamodel-code-generator) for Python client generation. Key flags:

| Flag | Purpose |
|------|---------|
| `--output-model-type pydantic_v2.BaseModel` | Generate Pydantic v2 models |
| `--use-annotated` | Use `Annotated[T, Field(...)]` syntax |
| `--enum-field-as-literal one` | Single-value enums → `Literal['value']` |
| `--target-python-version 3.12` | Target Python 3.12+ |

**Why `--enum-field-as-literal one`?**

OpenAPI discriminated unions (oneOf with discriminator) generate single-value enums for each variant. Without this flag, you get redundant types. With it:

```python
# GOOD: With the flag
class ItemTypeA(BaseModel):
    item_type: Literal['type_a']  # Clean!
```

### Step 3: Add as Dependency

```toml
# services/consumer-service/pyproject.toml
[project]
dependencies = [
    "my-org-my-service-client",  # Workspace dependency
]
```

### Step 4: Use the Models

```python
import httpx
from my_service_client.models import CreateItemRequest, ItemResponse

async def create_item(title: str) -> ItemResponse:
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.MY_SERVICE_URL}/api/v1/items",
            json=CreateItemRequest(title=title).model_dump(),
        )
        return ItemResponse.model_validate(response.json())
```

---

## Python → TypeScript

### Step 1: Export OpenAPI from Python Service

```bash
uv run python scripts/openapi/export-fastapi.py \
  services/python-service \
  python_service.main:app
# Creates services/python-service/openapi.json
```

### Step 2: Generate TypeScript Client

```bash
./scripts/openapi/generate-ts-client.sh \
  services/python-service/openapi.json \
  packages/python-service-client/src
```

This creates:

```
packages/python-service-client/
├── package.json
├── src/
│   ├── index.ts
│   ├── types.gen.ts   # Generated types
│   └── services/      # API service classes
```

### Step 3: Add as Dependency

```json
// consuming-service/package.json
{
  "dependencies": {
    "@your-org/python-service-client": "workspace:*"
  }
}
```

### Step 4: Use the Client

```typescript
import { MyServiceClient } from '@your-org/python-service-client';

export class MyServiceIntegration {
  private client = new MyServiceClient({
    baseUrl: process.env.PYTHON_SERVICE_URL,
  });

  async doSomething(input: InputType) {
    return this.client.doSomething(input);
  }
}
```

---

## OpenAPI Spec Management

### Exporting Specs

#### Zod Schemas (Preferred for Shared Types)

```bash
pnpm run openapi:export
# Creates packages/api-types/openapi.json
```

#### NestJS Services (Legacy)

```bash
# Start service, then fetch spec
./scripts/openapi/fetch-spec.sh http://localhost:3000 services/my-service/openapi.json
```

The fetch script tries common endpoints (`/api/docs-json`, `/api-json`, `/swagger-json`).

#### FastAPI Services

```bash
uv run python scripts/openapi/export-fastapi.py services/python-service main:app
```

### Linting Specs

```bash
# Single spec
npx @stoplight/spectral-cli lint services/my-service/openapi.json --ruleset .spectral.yaml

# All specs
npx @stoplight/spectral-cli lint services/*/openapi.json --ruleset .spectral.yaml
```

### CI Integration

Add to CI pipeline:
1. Lint all OpenAPI specs with Spectral
2. Detect breaking changes on PRs using oasdiff
3. Verify generated clients are up-to-date
