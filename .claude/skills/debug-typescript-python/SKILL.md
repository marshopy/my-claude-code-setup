---
name: debug-typescript-python
description: Systematic debugging workflow for TypeScript and Python. Use when diagnosing runtime errors, type errors, async bugs, unexpected behavior, or test failures. Covers error reading, stack trace analysis, breakpoint debugging, logging strategies, and language-specific gotchas.
---

# Debugging TypeScript & Python

## Workflow

```
1. Read the full error (don't skim)
2. Identify error type and location
3. Form a hypothesis
4. Add targeted instrumentation
5. Confirm or refute — adjust and repeat
6. Fix root cause, not symptom
7. Verify fix doesn't break neighbors
```

Never add random logging or change random things. Each step should test one hypothesis.

---

## Reading Errors

### TypeScript

```
error TS2345: Argument of type 'string | undefined' is not assignable
to parameter of type 'string'.
  Type 'undefined' is not assignable to type 'string'.
    at src/services/user.service.ts:42:28
```

Read:
- **Error code** (`TS2345`) — look this up if unfamiliar
- **What** was expected vs received
- **Where** — file + line number
- **Why** — TypeScript often shows the chain of inference

### Python

```
Traceback (most recent call last):
  File "services/processor.py", line 87, in process_batch
    result = await self.client.fetch(item.id)
  File "clients/api_client.py", line 34, in fetch
    return response.json()["data"]
KeyError: 'data'
```

Read from **bottom up** — the lowest frame is the immediate cause, the top frame is the entry point. The real bug is usually in the middle.

---

## TypeScript Debugging

### Type Errors

**Strategy: narrow the type at the point of divergence**

```typescript
// Error: Object is possibly 'undefined'
const name = user.profile.name; // TS2532

// Step 1: log the actual value
console.log('profile:', user.profile);

// Step 2: add a guard
if (!user.profile) {
  throw new Error(`user ${user.id} has no profile`);
}
const name = user.profile.name; // now safe
```

**Tip:** Use `satisfies` to catch type mismatches at assignment:
```typescript
const config = {
  host: 'localhost',
  port: '3000', // oops, string not number
} satisfies AppConfig; // error caught here, not at usage
```

### Runtime Errors

**Strategy: confirm inputs at boundaries**

```typescript
// "Cannot read properties of undefined (reading 'id')"
async function processItem(item: Item): Promise<void> {
  // Add assertion at entry
  console.assert(item != null, 'processItem called with null item');
  console.log('processItem input:', JSON.stringify(item, null, 2));

  const result = await this.service.handle(item.id); // line 55
  console.log('handle result:', result);
}
```

### Async / Promise Errors

Common issues:

| Symptom | Likely Cause |
|---------|-------------|
| Promise never resolves | Missing `await` in async chain |
| Unhandled rejection | `async` function called without `.catch()` or `await` |
| Race condition | Two awaits reading/writing shared state |
| `undefined` from async call | Forgot to `return` in async function |

```typescript
// Debugging async: add timing logs
console.time('fetchUser');
const user = await this.userService.findById(id);
console.timeEnd('fetchUser'); // logs elapsed time
console.log('user after fetch:', user);
```

### NestJS / DI Errors

```
Nest can't resolve dependencies of the MyService (?).
Please make sure that the argument MyRepository at index [0]
is available in the MyModule context.
```

Checklist:
1. Is the dependency decorated with `@Injectable()`?
2. Is it declared in `providers` of the owning module?
3. Is the owning module imported in `MyModule`?
4. Is it exported from the owning module?

### Debugger (VS Code)

```json
// .vscode/launch.json
{
  "type": "node",
  "request": "attach",
  "name": "Attach to NestJS",
  "port": 9229,
  "restart": true
}
```

Start service with: `node --inspect src/main.js`

Set breakpoints → inspect variables → step through → check call stack.

---

## Python Debugging

### Type Errors (mypy)

```
error: Argument 1 to "process" has incompatible type
"str | None"; expected "str"  [arg-type]
```

```python
# Step 1: find where None enters
result = fetch_value()  # returns str | None
print(f"result type: {type(result)}, value: {result!r}")

# Step 2: guard or assert
assert result is not None, f"fetch_value returned None unexpectedly"
process(result)  # now str
```

**Run mypy locally before assuming runtime bugs:**
```bash
uv run mypy src/ --ignore-missing-imports
```

### Runtime Errors

**Strategy: add `repr()` logging at the crash point**

```python
# KeyError / AttributeError
try:
    value = response["data"]["items"][0]
except (KeyError, IndexError, TypeError) as e:
    print(f"response structure: {response!r}")
    raise
```

**Using `pdb` (built-in debugger):**
```python
import pdb; pdb.set_trace()  # drops into interactive debugger
# Commands: n (next), s (step into), c (continue), p <expr> (print), q (quit)
```

**Using `breakpoint()` (Python 3.7+):**
```python
breakpoint()  # same as pdb.set_trace(), respects PYTHONBREAKPOINT env var
```

### Async (asyncio) Errors

```
RuntimeError: coroutine 'fetch' was never awaited
```

Common issues:

| Symptom | Likely Cause |
|---------|-------------|
| Coroutine never awaited | Called `async_fn()` without `await` |
| Event loop is closed | Mixing sync and async code |
| Task exception was never retrieved | Fire-and-forget task without error handling |
| `asyncio.run()` called from async context | Already inside an event loop |

```python
# Debug with asyncio debug mode
import asyncio
asyncio.get_event_loop().set_debug(True)

# Or set env var
PYTHONASYNCIODEBUG=1 uv run python main.py
```

### Pydantic Validation Errors

```python
from pydantic import ValidationError

try:
    item = ItemModel(**data)
except ValidationError as e:
    print(e.json(indent=2))  # structured error with field paths
    raise
```

### FastAPI Errors

Add a global exception handler to capture full context:
```python
@app.exception_handler(Exception)
async def debug_exception_handler(request: Request, exc: Exception):
    import traceback
    print(f"Unhandled error on {request.method} {request.url}")
    traceback.print_exc()
    raise exc
```

---

## Structured Logging vs. Print Debugging

For temporary diagnosis, `print`/`console.log` is fine. When you need persistence:

**TypeScript (NestJS):**
```typescript
private readonly logger = new Logger(MyService.name);
this.logger.debug('processing item', { itemId, userId });
```

**Python:**
```python
import logging
logger = logging.getLogger(__name__)
logger.debug("processing item", extra={"item_id": item_id, "user_id": user_id})
```

**Rule:** Remove debug-only logging before committing. Keep only logging that serves production observability.

---

## Test Failures

### TypeScript (Jest)

```bash
# Run a single test file with verbose output
pnpm jest path/to/file.spec.ts --verbose

# Run a single test by name
pnpm jest --testNamePattern="should process item"

# Run with coverage to find untested paths
pnpm jest --coverage path/to/file.spec.ts
```

### Python (pytest)

```bash
# Run single file
uv run pytest tests/test_processor.py -v

# Run single test
uv run pytest tests/test_processor.py::test_process_batch -v

# Show locals on failure
uv run pytest --tb=long --showlocals

# Drop into pdb on failure
uv run pytest --pdb
```

---

## Common Gotchas

### TypeScript

| Gotcha | Fix |
|--------|-----|
| `==` vs `===` | Always use `===` |
| `undefined` vs `null` | Use `?? fallback` for both |
| Array mutation side effects | Clone: `[...arr]` or `arr.slice()` |
| Floating point: `0.1 + 0.2 !== 0.3` | Use integer math or a library |
| `async forEach` doesn't await | Use `for...of` with `await` |
| `this` lost in callbacks | Use arrow functions or `.bind(this)` |

### Python

| Gotcha | Fix |
|--------|-----|
| Mutable default arg: `def f(x=[])` | Use `def f(x=None): x = x or []` |
| Late binding closure | Use `lambda i=i: ...` to capture |
| `is` vs `==` for values | Use `==` for value comparison |
| Dict iteration while modifying | Iterate `list(d.items())` |
| `asyncio.run()` in Jupyter | Use `await` directly in cells |
| Timezone-naive datetime | Always use `datetime.now(timezone.utc)` |

---

## Debugging Checklist

- [ ] Read the **full** error message and stack trace
- [ ] Identify the **exact line** where the error occurs
- [ ] Confirm the **actual input values** at that line (log/breakpoint)
- [ ] Form one hypothesis and test it
- [ ] Check if the issue is in your code or in a dependency
- [ ] Search the codebase for similar patterns that work — compare
- [ ] Verify the fix doesn't break existing tests
- [ ] Remove any debug-only logging before committing
