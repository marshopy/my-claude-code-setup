# Creating FastAPI Endpoints

Guide for creating API endpoints in FastAPI (Python) services.

## Step 1: Define Pydantic Models

```python
# services/rule-generator/rule_generator/models/intel.py
from pydantic import BaseModel, Field
from enum import Enum
from typing import Optional
from datetime import datetime


class RuleType(str, Enum):
    """Rule type enum - use lowercase values per API style guide."""
    sigma = "sigma"
    yara = "yara"
    kql = "kql"
    spl = "spl"


class IntelItemCreate(BaseModel):
    """Request model for creating intel items."""
    title: str = Field(..., description="Intel item title")
    rule_type: RuleType = Field(..., description="Rule type")
    description: Optional[str] = Field(None, description="Optional description")


class IntelItemResponse(BaseModel):
    """Response model for intel items."""
    id: str
    title: str
    rule_type: RuleType
    description: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class ApiResponse[T](BaseModel):
    """Standard API response wrapper."""
    data: T
    meta: dict = Field(default_factory=lambda: {"timestamp": datetime.utcnow().isoformat()})


class PaginatedMeta(BaseModel):
    """Pagination metadata."""
    total: int
    page: int
    page_size: int
    total_pages: int


class PaginatedResponse[T](BaseModel):
    """Paginated API response."""
    data: list[T]
    meta: PaginatedMeta
```

## Step 2: Create the Router

```python
# services/rule-generator/rule_generator/routers/intel.py
from fastapi import APIRouter, Query, HTTPException
from typing import Annotated
from ..models.intel import (
    IntelItemCreate,
    IntelItemResponse,
    ApiResponse,
    PaginatedResponse,
)

router = APIRouter(prefix="/intel-items", tags=["intel"])


@router.get(
    "",
    response_model=PaginatedResponse[IntelItemResponse],
    summary="List intel items with pagination",
    operation_id="listIntelItems",
)
async def list_intel_items(
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
):
    """List intel items with pagination."""
    # Implementation
    pass


@router.get(
    "/{item_id}",
    response_model=ApiResponse[IntelItemResponse],
    summary="Get a single intel item",
    operation_id="getIntelItem",
)
async def get_intel_item(item_id: str):
    """Get a single intel item by ID."""
    # Implementation
    pass


@router.post(
    "",
    response_model=ApiResponse[IntelItemResponse],
    status_code=201,
    summary="Create a new intel item",
    operation_id="createIntelItem",
)
async def create_intel_item(item: IntelItemCreate):
    """Create a new intel item."""
    # Implementation
    pass
```

## Exporting OpenAPI from FastAPI

FastAPI can export specs without running a server:

```bash
uv run python scripts/openapi/export-fastapi.py services/rule-generator main:app
# Creates services/rule-generator/openapi.json
```

## Naming Conventions

| Convention | Rule | Example |
|------------|------|---------|
| URL paths | kebab-case | `/intel-items`, `/detection-rules` |
| Query params | snake_case | `page_size=20`, `sort_by=created_at` |
| Response fields | snake_case | `user_id`, `created_at` |
| Enum values | lowercase | `sigma`, `yara` |
