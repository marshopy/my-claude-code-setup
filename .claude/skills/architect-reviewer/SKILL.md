---
name: architect-reviewer
description: Expert architecture reviewer for system design validation, component boundaries, scalability analysis, and technical decision assessment. Use when evaluating architectural changes, reviewing PRs with structural impact, planning new services, or assessing technical debt. Specializes in microservices patterns, event-driven design, and monorepo architecture.
---

# Architect Reviewer Skill

## Overview

Comprehensive architecture review for any codebase. This skill evaluates system design decisions, validates component boundaries, assesses scalability patterns, and identifies technical debt before it accumulates.

## When to Use This Skill

- When reviewing PRs that modify service boundaries or add new services
- When planning new features that span multiple services
- When evaluating architectural decisions (technology choices, patterns)
- When assessing technical debt or planning refactoring efforts
- When migrating existing code into the monorepo
- When a user asks "is this architecture correct?" or "should we split this service?"

## Architectural Principles

### 1. Separation of Concerns

**Layers within each service:**
```
Controllers  → Handle HTTP, validate DTOs, return responses
     ↓
Services     → Business logic, orchestration
     ↓
Repositories → Data access, data store entities
```

**Cross-cutting concerns:**
- Authentication: Handled by guards/middleware
- Logging: Use framework logger, not console.log
- Validation: Validate at entry points (controllers/handlers)

### 2. Domain Boundaries

Each service owns its data and exposes it through APIs:

```
✓ GOOD: intel-service → GET /api/intel/items/:id
✗ BAD:  other-service → SELECT * FROM intel.items
```

Cross-service data access patterns:
- HTTP API calls via typed clients
- Event-driven updates for eventual consistency
- Shared reference data via read-only APIs

### 3. Event-Driven Communication

Use events for intra-service communication:

```typescript
// Publisher
this.eventEmitter.emit('entity.created', { id, tenantId });

// Subscriber
@OnEvent('entity.created')
async handleEntityCreated(payload: EntityCreatedEvent) {
  // React to event
}
```

Use WebSocket/SSE for real-time client updates.

### 4. Scalability Patterns

| Pattern | When to Use |
|---------|-------------|
| Stateless services | Always - no request state in singletons |
| Connection pooling | Database and cache connections |
| Caching | Frequently accessed, rarely changed data |
| Queue processing | Long-running tasks |
| Horizontal scaling | CPU-bound operations |

### 5. Technology Stack Governance

Before adding new dependencies, verify:
- Consistency with existing stack choices
- Team has expertise with the technology
- It solves a real problem (not just novelty)
- Long-term maintenance burden is acceptable

## Review Checklist

### Component Boundaries

- [ ] New code placed in correct service based on domain
- [ ] No direct database access across service boundaries
- [ ] Shared types in shared package, not duplicated
- [ ] No circular dependencies between services

### Data Flow

- [ ] Request data validated at controller level
- [ ] Business logic contained in service layer
- [ ] Repository pattern used for data access
- [ ] Event-driven for cross-cutting concerns

### Scalability

- [ ] No request-specific state in singleton services
- [ ] Long-running operations use queues
- [ ] Caching strategy documented for new endpoints
- [ ] Connection pooling configured properly

### Maintainability

- [ ] Follows existing patterns in the codebase
- [ ] No unnecessary abstractions
- [ ] Clear naming aligned with domain terminology
- [ ] Appropriate error handling at boundaries

## Anti-Pattern Detection

### 1. God Service

**Symptom:** Single service doing too much

```typescript
// BAD: UserService handling payments, notifications, and auth
export class UserService {
  async createUser(dto: CreateUserDto) {
    await this.validatePaymentMethod(dto); // Payment concern
    await this.sendWelcomeEmail(dto);      // Notification concern
    await this.assignDefaultRoles(dto);   // Auth concern
    // ... actual user creation
  }
}
```

**Fix:** Split into focused services, use events for cross-cutting

### 2. Distributed Monolith

**Symptom:** Tight coupling despite service separation

```typescript
// BAD: Synchronous chain of HTTP calls
async processOrder(id: string) {
  const inventory = await this.inventoryClient.check(id);
  const user = await this.authClient.getUser(inventory.userId);
  const payment = await this.paymentClient.validate(user.paymentId);
  // All calls must succeed, no resilience
}
```

**Fix:** Use async events, implement circuit breakers, cache reference data

### 3. Shared Database

**Symptom:** Multiple services accessing same tables

**Fix:** Expose via owner-service API, cache responses

### 4. Missing Abstraction

**Symptom:** Same code pattern repeated across services

**Fix:** Create shared utility in a common package

## Decision Framework

When evaluating architectural changes, consider:

1. **Reversibility**: Can we undo this decision easily?
2. **Blast Radius**: How many files/services does this affect?
3. **Team Expertise**: Does the team have experience with this pattern?
4. **Maintenance Burden**: What's the ongoing cost of this approach?
5. **Migration Path**: How do we get from here to there safely?

## Verification Commands

```bash
# Check for circular dependencies (if using Nx)
pnpm nx graph

# Validate no cross-service imports
grep -r "from '../../services/" services/*/src/

# Find duplicated patterns
grep -r "pattern-to-check" services/*/src/
```
