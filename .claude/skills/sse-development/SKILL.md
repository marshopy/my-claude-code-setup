---
name: sse-development
description: Complete guide for Server-Sent Events development — producing events via Valkey/Redis Streams, consuming with EventSource and Python clients, testing at every layer, inspecting live streams with curl/browser DevTools, and validating with Caddy or nginx proxy. Use for any SSE work: producer implementation, consumer hooks, debugging, or end-to-end validation.
---

# SSE Producer Pattern

## Overview

**Architecture:**
```
Producer (your service) → Valkey/Redis Streams → Fan-out Worker → Pub/Sub → SSE Controller → Client
```

**Key Design Principle:** Streams are auto-created on first write (`XADD`), and consumer groups are created when clients subscribe. Producers just publish — no registration required.

## When to Use This Skill

- Adding real-time event delivery to a service
- Emitting progress updates (e.g., file analysis, job processing)
- Sending notifications to users
- **Debugging why SSE events aren't reaching clients**
- **Validating the full producer → stream → client pipeline**

---

## How It Works: Consumer-Triggered Registration

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

## Testing SSE Streams

### Layer 1: Test the Producer in Isolation

Unit test that `xadd` is called with correct fields — no need for a live Valkey:

```typescript
// event-producer.service.spec.ts
import { mockDeep } from 'jest-mock-extended';
import { GlideClient } from '@valkey/valkey-glide';

describe('EventProducer', () => {
  let producer: EventProducer;
  let mockClient: jest.Mocked<Pick<GlideClient, 'xadd' | 'close'>>;

  beforeEach(() => {
    mockClient = mockDeep();
    mockClient.xadd.mockResolvedValue('1234567890-0');

    producer = new EventProducer();
    (producer as any).client = mockClient;
  });

  it('publishes job.progress with correct stream key and fields', async () => {
    await producer.emitProgress('user-123', 'job-456', 50, 'processing');

    expect(mockClient.xadd).toHaveBeenCalledWith(
      'stream:user:user-123:updates',
      expect.arrayContaining([
        ['type', 'job.progress'],
        ['data', expect.stringContaining('"progress":50')],
        ['timestamp', expect.any(String)],
      ]),
      expect.objectContaining({ trim: expect.any(Object) }),
    );
  });

  it('does not throw when xadd fails', async () => {
    mockClient.xadd.mockRejectedValue(new Error('connection refused'));

    await expect(
      producer.emitProgress('user-123', 'job-456', 50, 'processing'),
    ).resolves.not.toThrow();
  });
});
```

### Layer 2: Test the Stream with a Real Valkey (Docker)

```typescript
// event-producer.integration.spec.ts
import { GlideClient } from '@valkey/valkey-glide';

describe('EventProducer integration', () => {
  let client: GlideClient;
  let producer: EventProducer;

  beforeAll(async () => {
    client = await GlideClient.createClient({
      addresses: [{ host: 'localhost', port: 6379 }],
    });
  });

  afterAll(() => client.close());

  it('writes event to Valkey stream', async () => {
    await producer.emitProgress('user-test', 'job-001', 75, 'finalizing');

    const messages = await client.xrange(
      'stream:user:user-test:updates',
      '-',
      '+',
    );

    expect(messages).toHaveLength(1);
    const fields = Object.fromEntries(messages[0][1]);
    expect(fields.type).toBe('job.progress');
    expect(JSON.parse(fields.data)).toMatchObject({ progress: 75 });
  });
});
```

### Layer 3: Test the SSE HTTP Endpoint

Use `EventSource` (Node.js) or `fetch` with streaming to validate what the client receives:

```typescript
// sse-endpoint.e2e.spec.ts
import { EventSource } from 'eventsource'; // npm install eventsource

it('delivers published event to SSE subscriber', (done) => {
  const received: string[] = [];

  const es = new EventSource('http://localhost:3000/sse/user/test-user/updates', {
    headers: { Authorization: `Bearer ${testToken}` },
  });

  es.addEventListener('message', (event) => {
    received.push(event.data);

    if (received.length === 1) {
      const parsed = JSON.parse(received[0]);
      expect(parsed.type).toBe('job.progress');
      es.close();
      done();
    }
  });

  es.onerror = (err) => { es.close(); done(err); };

  // Wait for subscription, then publish
  setTimeout(async () => {
    await producer.emitProgress('test-user', 'job-e2e', 40, 'testing');
  }, 200);
}, 10000);
```

### Python SSE Consumer for Testing

```python
# test_sse.py
import httpx
import json
import asyncio

async def consume_sse(url: str, token: str, n_events: int = 1) -> list[dict]:
    """Collect N SSE events then return them."""
    events = []

    async with httpx.AsyncClient() as client:
        async with client.stream(
            "GET",
            url,
            headers={
                "Accept": "text/event-stream",
                "Authorization": f"Bearer {token}",
            },
        ) as response:
            assert response.headers["content-type"].startswith("text/event-stream"), \
                f"Expected SSE, got {response.headers['content-type']}"

            async for line in response.aiter_lines():
                if line.startswith("data:"):
                    payload = line[5:].strip()
                    if payload:
                        events.append(json.loads(payload))
                if len(events) >= n_events:
                    break

    return events

# In pytest:
async def test_sse_delivers_job_progress(producer, sse_base_url, auth_token):
    asyncio.create_task(
        asyncio.sleep(0.2)  # let subscription establish
    )

    # Start consuming (in background)
    consume_task = asyncio.create_task(
        consume_sse(f"{sse_base_url}/sse/user/test-user/updates", auth_token)
    )

    await asyncio.sleep(0.2)
    await producer.emit_progress("test-user", "job-py-1", 60, "testing")

    events = await asyncio.wait_for(consume_task, timeout=5.0)
    assert len(events) == 1
    assert events[0]["type"] == "job.progress"
```

---

## Inspecting SSE in Real Time

### 1. curl (fastest)

```bash
# Stream SSE events — -N disables buffering, essential for SSE
curl -N \
  -H "Accept: text/event-stream" \
  -H "Authorization: Bearer <token>" \
  http://localhost:3000/sse/user/test-user/updates

# Include response headers (verify Content-Type)
curl -N -v \
  -H "Accept: text/event-stream" \
  http://localhost:3000/sse/user/test-user/updates

# Expected response headers:
# < HTTP/1.1 200 OK
# < content-type: text/event-stream
# < cache-control: no-cache
# < connection: keep-alive
#
# Expected body (line-by-line):
# data: {"type":"job.progress","data":{"progress":50}}
#
# (blank line between events)
```

### 2. httpie

```bash
# Install: pip install httpie
http --stream GET http://localhost:3000/sse/user/test-user/updates \
  Accept:text/event-stream \
  Authorization:"Bearer <token>"
```

### 3. Browser DevTools — EventStream Tab

1. Open DevTools → **Network** tab
2. Navigate to / trigger a page that opens an SSE connection
3. Filter by **Fetch/XHR** or search for your SSE endpoint
4. Click the request → **EventStream** tab
5. See each event as it arrives with timestamp and data

This is the most visual way to debug SSE in development.

### 4. Node.js Script (scripted inspection)

```javascript
// inspect-sse.mjs — run with: node inspect-sse.mjs
import { EventSource } from 'eventsource';

const TOKEN = process.env.TOKEN || 'your-token';
const URL = process.env.SSE_URL || 'http://localhost:3000/sse/user/test-user/updates';

const es = new EventSource(URL, {
  headers: { Authorization: `Bearer ${TOKEN}` },
});

console.log(`Connecting to ${URL}...`);

es.onopen = () => console.log('[open] Connection established');
es.onerror = (e) => console.error('[error]', e);

es.addEventListener('message', (event) => {
  try {
    const parsed = JSON.parse(event.data);
    console.log('[event]', JSON.stringify(parsed, null, 2));
  } catch {
    console.log('[raw]', event.data);
  }
});

// Ctrl+C to stop
process.on('SIGINT', () => { es.close(); process.exit(0); });
```

### 5. Python sseclient (scripted inspection)

```bash
pip install sseclient-py requests
```

```python
# inspect_sse.py
import sseclient
import requests
import json

url = "http://localhost:3000/sse/user/test-user/updates"
headers = {
    "Accept": "text/event-stream",
    "Authorization": "Bearer your-token",
}

response = requests.get(url, headers=headers, stream=True)
client = sseclient.SSEClient(response)

print(f"Connected to {url}")
print(f"Content-Type: {response.headers.get('content-type')}")
print(f"Cache-Control: {response.headers.get('cache-control')}")
print()

for event in client.events():
    print(f"[{event.event or 'message'}] id={event.id}")
    try:
        data = json.loads(event.data)
        print(json.dumps(data, indent=2))
    except json.JSONDecodeError:
        print(event.data)
    print()
```

---

## Validating SSE with Caddy

Caddy can act as a transparent reverse proxy in front of your SSE endpoint. This lets you:

- **Inspect headers** — confirm `Content-Type: text/event-stream` and no buffering headers
- **Log all events** with structured access logs
- **Validate CORS** and auth headers are passed through correctly
- **Test TLS termination** locally before deploying

### Caddyfile for SSE Inspection

```caddy
# Caddyfile
{
  # Disable admin for local use
  admin off
}

:8080 {
  # Log all requests including SSE streams
  log {
    output file /tmp/caddy-sse.log
    format json
    level DEBUG
  }

  # Reverse proxy to your SSE service
  reverse_proxy localhost:3000 {
    # Critical: disable buffering for SSE
    flush_interval -1

    # Log headers for inspection
    header_up X-Forwarded-For {remote_host}
    header_up X-Forwarded-Proto {scheme}

    # Pass auth headers through
    header_up Authorization {header.Authorization}
  }
}
```

```bash
# Run Caddy with the Caddyfile
caddy run --config Caddyfile

# Now connect through Caddy instead of directly
curl -N \
  -H "Accept: text/event-stream" \
  -H "Authorization: Bearer <token>" \
  http://localhost:8080/sse/user/test-user/updates

# Tail Caddy logs to see each request
tail -f /tmp/caddy-sse.log | jq .
```

### Validating Critical SSE Headers via Caddy

Add a `respond` block to check headers before proxying:

```caddy
:8080 {
  log {
    output stdout
    format console
    level DEBUG
  }

  # Intercept SSE paths to validate + proxy
  handle /sse/* {
    reverse_proxy localhost:3000 {
      flush_interval -1  # required — prevents Caddy from buffering SSE

      # Validate response: add a header to track proxy passage
      header_down X-Proxied-By "caddy-sse-inspector"
    }
  }
}
```

```bash
# Verify the SSE response has correct headers
curl -sI \
  -H "Accept: text/event-stream" \
  http://localhost:8080/sse/user/test-user/updates | grep -E "content-type|cache-control|connection|x-proxied"

# Expected:
# content-type: text/event-stream
# cache-control: no-cache
# connection: keep-alive
# x-proxied-by: caddy-sse-inspector
```

### Caddy Access Log — Parsing SSE Events

For deeper inspection, use a Caddy plugin or log the raw body. More practical: route SSE through Caddy and tail the JSON logs:

```bash
# Stream Caddy logs, filter to SSE paths only
tail -f /tmp/caddy-sse.log | jq 'select(.request.uri | startswith("/sse"))'

# Output example:
# {
#   "level": "info",
#   "ts": 1711580400.123,
#   "request": { "method": "GET", "uri": "/sse/user/test-user/updates" },
#   "duration": 45.2,         ← long duration = healthy streaming connection
#   "status": 200,
#   "resp_headers": {
#     "Content-Type": ["text/event-stream"],
#     "Cache-Control": ["no-cache"]
#   }
# }
```

A `duration` >> 1s for a 200 response is the sign of a healthy SSE connection.

### Alternative: nginx for SSE Inspection

```nginx
# nginx.conf snippet — equivalent to Caddy for SSE validation
server {
  listen 8080;

  location /sse/ {
    proxy_pass http://localhost:3000;
    proxy_http_version 1.1;

    # Required for SSE: disable buffering
    proxy_buffering off;
    proxy_cache off;
    proxy_read_timeout 3600s;  # keep connection alive for SSE

    # Pass connection upgrade headers
    proxy_set_header Connection '';
    chunked_transfer_encoding on;

    # Log for inspection
    access_log /tmp/nginx-sse.log combined;
  }
}
```

---

## Diagnosing Common SSE Issues

### Events published but client never receives them

**Checklist — work through each layer:**

```bash
# 1. Confirm the event is in Valkey
docker exec valkey valkey-cli XRANGE stream:user:test-user:updates - + COUNT 5

# 2. Confirm the stream has a consumer group
docker exec valkey valkey-cli XINFO STREAM stream:user:test-user:updates

# 3. Confirm the fan-out worker is consuming the stream
docker exec valkey valkey-cli XINFO GROUPS stream:user:test-user:updates

# 4. Confirm the SSE HTTP endpoint is reachable
curl -v -N -H "Accept: text/event-stream" http://localhost:3000/sse/user/test-user/updates
```

### Proxy is buffering SSE (events arrive in batches)

Signs: events appear in chunks, not one-by-one.

Fixes:
- Caddy: `flush_interval -1`
- nginx: `proxy_buffering off`
- Node.js `http` module: ensure `res.flushHeaders()` is called immediately
- NestJS: set `Content-Type: text/event-stream` and call `response.flushHeaders()` before writing

### SSE connection drops immediately

```bash
# Check if the server is actually keeping the connection open
curl -N -v http://localhost:3000/sse/user/test-user/updates 2>&1 | grep -E "< |> |Connected|Connection"

# If connection closes immediately:
# - Missing authentication / auth token rejected
# - Server timeout configured too short
# - Load balancer / proxy closing idle connections
```

### Duplicate events received

Cause: multiple consumer groups or SSE controller subscribing more than once.

```bash
# Check consumer groups on the stream
docker exec valkey valkey-cli XINFO GROUPS stream:user:test-user:updates
# Should show exactly 1 group per active subscriber channel
```

---

## Validating SSE Wire Format

A valid SSE stream looks like this at the byte level:

```
HTTP/1.1 200 OK
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive

data: {"type":"job.started","data":{"jobId":"abc"},"timestamp":"1711580400000"}

data: {"type":"job.progress","data":{"jobId":"abc","progress":50},"timestamp":"1711580460000"}

data: {"type":"job.complete","data":{"jobId":"abc","result":{}},"timestamp":"1711580520000"}

```

Rules to validate:
- Each event is one or more `data: <payload>` lines
- Events are separated by a **blank line** (`\n\n`)
- Optionally prefixed with `event: <type>\n` for named events
- Optionally prefixed with `id: <id>\n` for resumption

```bash
# Validate wire format with curl — show raw bytes
curl -N --no-buffer \
  -H "Accept: text/event-stream" \
  http://localhost:3000/sse/user/test-user/updates \
  | cat -A  # show invisible characters ($ = \n)

# Each event line should end with $
# Blank line between events should show $$
```

---

## SSE Consumer Best Practices

### Reconnection and Resumption

The `EventSource` API reconnects automatically after disconnection — but only resumes from the last event if the server sends `id:` fields and the client sends `Last-Event-ID`.

```typescript
// GOOD — server sends event IDs to enable resumption
await this.client.xadd(
  streamKey,
  [
    ['type', 'job.progress'],
    ['data', JSON.stringify(payload)],
    ['timestamp', Date.now().toString()],
  ],
);
// The Valkey stream message ID becomes the SSE event id

// Consumer automatically resumes after disconnect:
// Client sends: Last-Event-ID: 1711580400000-0
// Server reads from that ID forward, not from beginning
```

```typescript
// SSE controller — always set event id for resumption support
response.write(`id: ${messageId}\n`);
response.write(`data: ${JSON.stringify(payload)}\n\n`);
```

### TypeScript / Browser Consumer

```typescript
// sse-client.ts — production-grade EventSource wrapper
export class SSEClient {
  private es: EventSource | null = null;
  private retryDelay = 1000;
  private readonly MAX_RETRY = 30000;

  constructor(
    private readonly url: string,
    private readonly onEvent: (event: MessageEvent) => void,
    private readonly getToken: () => string,
  ) {}

  connect(): void {
    // EventSource doesn't support custom headers natively in browsers.
    // Pass token as query param or use a fetch-based polyfill.
    this.es = new EventSource(`${this.url}?token=${this.getToken()}`);

    this.es.onopen = () => {
      this.retryDelay = 1000; // reset backoff on successful connection
    };

    this.es.addEventListener('message', (event) => {
      this.onEvent(event);
    });

    this.es.onerror = () => {
      // EventSource will retry automatically, but you can add custom logic:
      console.warn(`SSE connection error. Will retry in ${this.retryDelay}ms`);
      // Don't close manually — let EventSource handle reconnect
    };
  }

  disconnect(): void {
    this.es?.close();
    this.es = null;
  }
}
```

**Always call `disconnect()` on component unmount** to prevent memory leaks.

### React Hook Pattern

```tsx
// useSSE.ts
import { useEffect, useRef } from 'react';
import { useQueryClient } from '@tanstack/react-query';

export function useSSE(userId: string) {
  const queryClient = useQueryClient();
  const esRef = useRef<EventSource | null>(null);

  useEffect(() => {
    if (!userId) return;

    const es = new EventSource(`/api/sse/user/${userId}/updates`);
    esRef.current = es;

    es.addEventListener('message', (event) => {
      try {
        const { type, data } = JSON.parse(event.data);

        switch (type) {
          case 'job.complete':
            // Invalidate to fetch fresh data — NEVER stub from SSE payload
            queryClient.invalidateQueries({ queryKey: ['jobs', data.jobId] });
            break;
          case 'notification.info':
            // For in-memory UI state only, not server data
            showToast(data.message);
            break;
        }
      } catch (err) {
        console.error('Failed to parse SSE event', err, event.data);
      }
    });

    es.onerror = () => {
      // EventSource retries automatically — log but don't panic
      console.warn('SSE connection interrupted, will retry');
    };

    // Critical: clean up on unmount to avoid memory leaks + duplicate subscriptions
    return () => {
      es.close();
      esRef.current = null;
    };
  }, [userId, queryClient]);
}
```

### Python Async Consumer

```python
# sse_consumer.py
import asyncio
import json
import logging
import httpx

logger = logging.getLogger(__name__)


class SSEConsumer:
    """Resilient SSE consumer with reconnection and backoff."""

    def __init__(self, url: str, token: str, handler):
        self.url = url
        self.token = token
        self.handler = handler
        self._last_event_id: str | None = None
        self._running = False

    async def start(self) -> None:
        self._running = True
        retry_delay = 1.0

        while self._running:
            try:
                await self._connect()
                retry_delay = 1.0  # reset on clean connection
            except httpx.ReadTimeout:
                logger.warning("SSE read timeout, reconnecting...")
            except httpx.ConnectError as e:
                logger.error("SSE connection error: %s", e)
                await asyncio.sleep(retry_delay)
                retry_delay = min(retry_delay * 2, 30.0)  # exponential backoff, cap 30s
            except Exception as e:
                logger.exception("Unexpected SSE error: %s", e)
                await asyncio.sleep(retry_delay)
                retry_delay = min(retry_delay * 2, 30.0)

    async def stop(self) -> None:
        self._running = False

    async def _connect(self) -> None:
        headers = {
            "Accept": "text/event-stream",
            "Authorization": f"Bearer {self.token}",
            "Cache-Control": "no-cache",
        }

        # Resume from last known event
        if self._last_event_id:
            headers["Last-Event-ID"] = self._last_event_id

        async with httpx.AsyncClient(timeout=None) as client:
            async with client.stream("GET", self.url, headers=headers) as response:
                response.raise_for_status()
                assert "text/event-stream" in response.headers.get("content-type", ""), \
                    f"Expected SSE, got {response.headers.get('content-type')}"

                logger.info("SSE connected to %s", self.url)
                await self._read_stream(response)

    async def _read_stream(self, response: httpx.Response) -> None:
        """Parse SSE protocol: data/id/event lines, blank-line delimited."""
        data_lines: list[str] = []
        event_type = "message"
        event_id: str | None = None

        async for line in response.aiter_lines():
            if line.startswith("data:"):
                data_lines.append(line[5:].lstrip())
            elif line.startswith("id:"):
                event_id = line[3:].strip()
            elif line.startswith("event:"):
                event_type = line[6:].strip()
            elif line == "":  # blank line = dispatch event
                if data_lines:
                    payload = "\n".join(data_lines)
                    if event_id:
                        self._last_event_id = event_id  # track for resumption

                    try:
                        await self.handler(event_type, json.loads(payload))
                    except Exception as e:
                        logger.error("SSE handler error: %s | payload: %s", e, payload)

                    # Reset for next event
                    data_lines = []
                    event_type = "message"
                    event_id = None
```

### Consumer Anti-Patterns

```typescript
// BAD: Opening multiple connections to the same channel
// Each component mounting creates a new EventSource — duplicate events
function ComponentA() {
  useEffect(() => {
    new EventSource('/sse/user/123/updates'); // ❌ leaked, no cleanup
  }, []);
}

// GOOD: Single shared connection, shared via context or Zustand
// Only one EventSource per channel per tab

// BAD: Storing server data from SSE in local state
es.addEventListener('message', (event) => {
  const { data } = JSON.parse(event.data);
  setJobData(data); // ❌ SSE payload is partial — causes "no content" bugs
});

// GOOD: Invalidate query cache to fetch complete data
es.addEventListener('message', (event) => {
  const { type, data } = JSON.parse(event.data);
  if (type === 'job.complete') {
    queryClient.invalidateQueries({ queryKey: ['job', data.jobId] }); // ✅
  }
});

// BAD: No error handling on the consumer
// Silent failure when SSE endpoint is down

// GOOD: Always handle onerror
es.onerror = (err) => {
  console.warn('SSE error, connection will auto-retry', err);
  metrics.increment('sse.connection_error');
};
```

### Connection Lifecycle Rules

| Rule | Why |
|------|-----|
| Always close `EventSource` on component unmount | Prevents memory leaks and duplicate subscriptions |
| Never open multiple `EventSource`s to the same URL | Duplicate events, wasted connections |
| Use `Last-Event-ID` for resumption in critical flows | Prevents missed events during reconnect |
| Invalidate query cache on SSE data events | SSE payload is a notification, not a full data record |
| Add exponential backoff in non-browser consumers | Prevents thundering herd on server restart |
| Validate `Content-Type: text/event-stream` on connect | Catches misconfigured proxies that buffer responses |

---

## Testing with Docker

```bash
# Start local Valkey
docker compose up valkey

# Add a test event directly
docker exec valkey valkey-cli XADD stream:user:test123:updates '*' \
  type test \
  data '{"message":"test event"}' \
  timestamp "$(date +%s)000"

# Read events from stream
docker exec valkey valkey-cli XRANGE stream:user:test123:updates - + COUNT 5

# Check stream length
docker exec valkey valkey-cli XLEN stream:user:test123:updates

# Monitor all Valkey commands in real time (useful during testing)
docker exec valkey valkey-cli MONITOR

# Watch a specific stream for new messages (poll every 1s)
watch -n1 'docker exec valkey valkey-cli XRANGE stream:user:test123:updates - + COUNT 3'
```

---

## Best Practices

### 1. Always Use Bounded Retention

```typescript
{ trim: { method: 'maxlen', threshold: 10000, exact: false } }
```

`exact: false` uses approximate trimming for better performance.

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
docker compose up valkey

# Uses localhost:6379, no IAM auth
VALKEY_HOST=localhost
VALKEY_IAM_ENABLED=false
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
- [ ] Unit test the producer with a mock Valkey client
- [ ] Integration test with a real Valkey (Docker)
- [ ] Validate SSE endpoint headers with curl or Caddy proxy
- [ ] Test full pipeline end-to-end with EventSource consumer
- [ ] Verify no proxy buffering (`flush_interval -1` in Caddy, `proxy_buffering off` in nginx)
