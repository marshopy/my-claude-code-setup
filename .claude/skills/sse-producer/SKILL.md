---
name: sse-producer
description: Guide for producing Server-Sent Events using Valkey/Redis Streams. Use when adding real-time event delivery to a service, emitting progress updates, or integrating with an SSE infrastructure. Covers Valkey Streams, channel naming conventions, event types, and producer best practices.
---

# SSE Producer Pattern

## Overview

This skill provides everything needed to produce Server-Sent Events (SSE) for real-time delivery to connected clients.

**Architecture:**
```
Producer (your service) → Valkey/Redis Streams → Fan-out Worker → Pub/Sub → SSE Controller → Client
```

**Key Design Principle:** Streams are auto-created on first write (`XADD`), and consumer groups are created when clients subscribe. Producers just publish — no registration required.

## When to Use This Skill

- Adding real-time event delivery to a service
- Emitting progress updates (e.g., file analysis, job processing)
- Sending notifications to users
- Questions about SSE patterns in this codebase

---

## How It Works: Consumer-Triggered Registration

The SSE system uses **consumer-triggered stream registration** to ensure zero message loss:

```
1. Client connects to SSE, subscribes to channel "user:u123:updates"
2. SSE Controller registers stream:user:u123:updates with fan-out worker
   - Creates consumer group with MKSTREAM (handles race if stream doesn't exist)
   - Uses start ID '0' to read ALL messages (prevents loss)
3. Producer publishes to stream:user:u123:updates (stream auto-created by XADD)
4. Fan-out worker reads from stream, publishes to pub/sub
5. Client receives event
```

**As a producer, you don't need to do anything special.** Just call `xadd` — the stream is auto-created.

---

## Quick Reference

| Task | Details |
|------|---------|
| Stream key format | `stream:{scope}:{scopeId}:{resourceType}` |
| Max stream length | ~10,000 entries (approximate trim) |
| Required fields | `type`, `data` (JSON string), `timestamp` |

### Channel Scopes

| Scope | Format | Authorization |
|-------|--------|---------------|
| User | `stream:user:{userId}:updates` | Authenticated user |
| Group | `stream:group:{groupId}:activity` | Group membership |
| Team | `stream:team:{teamId}:updates` | Team membership |
| Org | `stream:organization:{orgId}:announcements` | Org membership |

---

## Producer Implementation

### TypeScript/NestJS with Valkey GLIDE

```typescript
import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { GlideClient } from '@valkey/valkey-glide';

@Injectable()
export class EventProducer implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(EventProducer.name);
  private client: GlideClient;

  async onModuleInit() {
    this.client = await GlideClient.createClient({
      addresses: [
        {
          host: process.env.VALKEY_HOST || 'localhost',
          port: parseInt(process.env.VALKEY_PORT || '6379'),
        },
      ],
      clientName: 'sse-producer',
      databaseId: parseInt(process.env.VALKEY_DB || '0'),
      useTLS: process.env.VALKEY_TLS_ENABLED === 'true',
    });
  }

  async onModuleDestroy() {
    await this.client?.close();
  }

  async emitProgress(
    userId: string,
    jobId: string,
    progress: number,
    stage: string,
  ): Promise<void> {
    const streamKey = `stream:user:${userId}:updates`;

    try {
      await this.client.xadd(
        streamKey,
        [
          ['type', 'job.progress'],
          ['data', JSON.stringify({ jobId, progress, stage })],
          ['timestamp', Date.now().toString()],
        ],
        { trim: { method: 'maxlen', threshold: 10000, exact: false } },
      );
    } catch (error) {
      this.logger.error(`Failed to emit progress: ${error.message}`);
      // Don't throw - SSE is not critical path
    }
  }

  async emitComplete(userId: string, jobId: string, result: object): Promise<void> {
    const streamKey = `stream:user:${userId}:updates`;

    await this.client.xadd(
      streamKey,
      [
        ['type', 'job.complete'],
        ['data', JSON.stringify({ jobId, ...result })],
        ['timestamp', Date.now().toString()],
      ],
      { trim: { method: 'maxlen', threshold: 10000, exact: false } },
    );
  }
}
```

### Minimal Example

```typescript
import { GlideClient } from '@valkey/valkey-glide';

async function publishSSEEvent(
  userId: string,
  eventType: string,
  payload: object,
): Promise<string> {
  const client = await GlideClient.createClient({
    addresses: [{
      host: process.env.VALKEY_HOST || 'localhost',
      port: parseInt(process.env.VALKEY_PORT || '6379'),
    }],
    databaseId: parseInt(process.env.VALKEY_DB || '0'),
    useTLS: process.env.VALKEY_TLS_ENABLED === 'true',
  });

  const streamKey = `stream:user:${userId}:updates`;
  const eventId = await client.xadd(
    streamKey,
    [
      ['type', eventType],
      ['data', JSON.stringify(payload)],
      ['timestamp', Date.now().toString()],
    ],
    { trim: { method: 'maxlen', threshold: 10000, exact: false } },
  );

  await client.close();
  return eventId;
}
```

---

## Event Types

### Job/Progress Events

| Type | Description | Data Fields |
|------|-------------|-------------|
| `job.started` | Job started | `jobId`, `jobType` |
| `job.progress` | Progress update | `jobId`, `progress` (0-100), `stage`, `message?` |
| `job.complete` | Job finished | `jobId`, `result` |
| `job.error` | Job failed | `jobId`, `error`, `errorCode?` |

### Notification Events

| Type | Description | Data Fields |
|------|-------------|-------------|
| `notification.info` | Informational | `title`, `message`, `action?` |
| `notification.warning` | Warning | `title`, `message`, `severity` |
| `notification.error` | Error notification | `title`, `message`, `errorCode` |

---

## Best Practices

### 1. Always Use Bounded Retention

Prevents unbounded memory growth:

```typescript
{ trim: { method: 'maxlen', threshold: 10000, exact: false } }
```

The `exact: false` uses approximate trimming for better performance.

### 2. Handle Failures Gracefully

SSE is not critical path — don't let failures break your main operation:

```typescript
try {
  await this.client.xadd(streamKey, fields, options);
} catch (error) {
  this.logger.error('SSE event not delivered', { error, streamKey });
  // Don't throw - let the main operation complete
}
```

### 3. Keep Payloads Small

SSE is for notifications, not bulk data transfer:

- Include IDs, not full objects
- Client fetches full data via REST API
- Aim for < 1KB per event

### 4. Use Appropriate Scopes

Choose the narrowest scope that covers your use case:

```typescript
// User-specific (user sees their own events)
`stream:user:${userId}:updates`

// Team-visible (all team members see)
`stream:team:${teamId}:updates`

// Org-wide announcements
`stream:organization:${orgId}:announcements`
```

### 5. Include Timestamps

Always include for ordering and debugging:

```typescript
['timestamp', Date.now().toString()]
```

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VALKEY_HOST` | required | Valkey server hostname |
| `VALKEY_PORT` | `6379` | Valkey server port |
| `VALKEY_DB` | `0` | Database for SSE streams |
| `VALKEY_TLS_ENABLED` | `false` | Enable TLS |
| `VALKEY_IAM_ENABLED` | `false` | Use IAM authentication (AWS only) |

### Local Development Setup

```bash
# Start local Valkey
docker-compose up valkey

# Uses localhost:6379, no IAM auth
VALKEY_HOST=localhost
VALKEY_IAM_ENABLED=false
```

---

## Testing with Docker

```bash
# Verify Valkey is running
docker exec valkey valkey-cli PING

# Add a test event
docker exec valkey valkey-cli XADD stream:user:test123:updates '*' \
  type test \
  data '{"message":"test event"}' \
  timestamp "$(date +%s)000"

# Read events from stream
docker exec valkey valkey-cli XRANGE stream:user:test123:updates - + COUNT 5

# Check stream length
docker exec valkey valkey-cli XLEN stream:user:test123:updates
```

---

## Checklist: Adding SSE to a Service

- [ ] Add Valkey client package to service dependencies
- [ ] Add `VALKEY_*` env vars to service's `.env.example`
- [ ] Create event producer service (see examples above)
- [ ] Use correct stream key format for your scope
- [ ] Include required fields: `type`, `data`, `timestamp`
- [ ] Apply `MAXLEN` trim to prevent unbounded growth
- [ ] Handle Valkey failures gracefully (don't break main operation)
- [ ] Keep payloads small (< 1KB, IDs not full objects)
- [ ] Test locally with Docker
