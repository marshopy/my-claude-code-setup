---
name: defect-workflow
description: End-to-end defect workflow — research the bug report, understand and validate reproduction steps, perform root cause analysis, implement the fix, and produce manual testing results. Use when assigned a bug, investigating a reported issue, or resolving a production incident.
---

# Defect Workflow

## Overview

```
1. Research      → Understand what the bug actually is
2. Reproduce     → Confirm you can trigger it consistently
3. Root Cause    → Find WHY it happens (not just where)
4. Fix           → Change the minimum required to resolve
5. Verify        → Confirm fix works + no regression
6. Document      → Produce testing record
```

Do not skip steps. Fixing before reproducing leads to guessing. Fixing before root cause leads to treating symptoms.

---

## Phase 1: Research

### Gather the Report

Collect before touching code:

| What | Why |
|------|-----|
| Exact error message / screenshot | Defines the observable failure |
| Steps to reproduce | Your testing target |
| Expected vs actual behavior | Defines success criteria for the fix |
| Affected version / environment | Narrows the search space |
| How often it occurs | Signals intermittent vs deterministic |
| Who is affected | Scope and urgency |
| Any recent changes | Often narrows the cause immediately |

### Search for Context

```bash
# Search code for the error message
grep -r "error message text" src/

# Find related recent changes
git log --oneline --since="7 days ago" --all -- path/to/suspected/file

# Check if the issue was reported before
git log --oneline --grep="keyword from bug report"

# Who last touched the relevant code
git blame path/to/file.ts
```

### Identify the Code Path

Trace from the symptom backward:
1. What is the **user action** or **trigger**?
2. What **API endpoint** or **function** handles it?
3. What **service / module** owns that function?
4. What **data** flows through it?

---

## Phase 2: Reproduce

### Write a Reproduction Script

Before changing anything, confirm you can trigger the bug:

**TypeScript/Node:**
```typescript
// repro.ts — run with: npx ts-node repro.ts
import { MyService } from './src/services/my.service';

async function repro() {
  const service = new MyService();

  // Use exact inputs from the bug report
  const result = await service.doThing({ id: '123', value: null });

  console.log('result:', result);
  // Expected: { status: 'ok' }
  // Actual: throws TypeError
}

repro().catch(console.error);
```

**Python:**
```python
# repro.py — run with: uv run python repro.py
from services.processor import Processor

async def repro():
    processor = Processor()

    # Use exact inputs from the bug report
    result = await processor.process({"id": "123", "value": None})

    print("result:", result)
    # Expected: {"status": "ok"}
    # Actual: KeyError

import asyncio
asyncio.run(repro())
```

### Reproduction Checklist

- [ ] Can you trigger the bug with the reported steps?
- [ ] Is it **deterministic** (always fails) or **intermittent**?
- [ ] Does it fail with the **minimal input** you can construct?
- [ ] Does it fail in **isolation** (unit test) or only in integration?
- [ ] Does it fail in the reporter's environment but not yours? (environment difference)

If you cannot reproduce: ask the reporter for more detail. Do not proceed to fix a bug you cannot verify.

---

## Phase 3: Root Cause Analysis

### The 5-Why Method

Keep asking "why" until you reach a root cause, not a symptom:

```
Bug: User sees "Internal Server Error" when uploading a file
Why? → The API returns 500
Why? → An unhandled exception is thrown
Why? → `file.size` is undefined
Why? → The upload middleware strips unknown fields
Why? → The field name in the form is "fileSize" but the code expects "size"
Root cause: field name mismatch between client and server contract
```

### Locate the Defect

```bash
# Add a focused breakpoint or log at the failing line
# TypeScript
console.log('[DEBUG repro]', { inputValue, processedValue });

# Python
print(f"[DEBUG repro] input={input_value!r} processed={processed_value!r}")
```

Confirm:
1. The **exact line** where the value diverges from expectation
2. The **input** that produces the bad output
3. Whether the bug is in **this code** or a **dependency**

### Common Root Causes

| Pattern | Signs |
|---------|-------|
| Missing null check | `Cannot read property X of undefined/null` |
| Off-by-one | Fails at boundaries (empty list, last item, 0) |
| Race condition | Intermittent, timing-dependent, concurrent requests |
| Stale cache | Works after restart, fails after time |
| Config mismatch | Works in one env, fails in another |
| API contract drift | Works when called directly, fails via client |
| Implicit type coercion | Values that look correct but compare wrong |

---

## Phase 4: Fix

### Fix Principles

- Change the **minimum required** to fix the root cause
- Do not refactor surrounding code as part of the fix
- Do not add features alongside the fix
- Preserve existing behavior for all unaffected paths

### Write a Failing Test First

Before fixing, write a test that captures the bug:

```typescript
// TypeScript (Jest)
it('should not throw when value is null', async () => {
  // This test FAILS before the fix
  await expect(service.doThing({ id: '123', value: null }))
    .resolves.toEqual({ status: 'ok' });
});
```

```python
# Python (pytest)
async def test_process_handles_none_value():
    # This test FAILS before the fix
    result = await processor.process({"id": "123", "value": None})
    assert result == {"status": "ok"}
```

Then implement the fix. The test should now pass.

### Validate No Regression

```bash
# TypeScript — run the affected module's tests
pnpm jest path/to/affected.spec.ts

# Run the full suite if the change is broad
pnpm jest

# Python — run affected tests
uv run pytest tests/test_affected.py -v

# Run full suite
uv run pytest
```

---

## Phase 5: Manual Testing

### Test Plan Template

Document before testing:

```
Bug: [brief description]
Fix: [what was changed and why]

Test Cases:
1. Happy path — [normal inputs, expect normal result]
2. Bug scenario — [exact inputs from report, expect correct result]
3. Edge case A — [boundary input, expect graceful handling]
4. Edge case B — [another boundary]
5. Regression — [related functionality that should still work]
```

### Manual Test Record

After testing, record results:

```
## Manual Test Results

**Date:** 2026-03-28
**Branch:** fix/null-value-upload-crash
**Environment:** local / staging / production

| # | Test Case | Input | Expected | Actual | Pass/Fail |
|---|-----------|-------|----------|--------|-----------|
| 1 | Happy path | `{ id: "1", value: "hello" }` | `{ status: "ok" }` | `{ status: "ok" }` | ✅ Pass |
| 2 | Bug scenario | `{ id: "1", value: null }` | `{ status: "ok" }` | `{ status: "ok" }` | ✅ Pass |
| 3 | Empty value | `{ id: "1", value: "" }` | `{ status: "ok" }` | `{ status: "ok" }` | ✅ Pass |
| 4 | Missing id | `{ value: "hello" }` | `400 Bad Request` | `400 Bad Request` | ✅ Pass |
| 5 | Existing feature X | normal usage | works as before | works as before | ✅ Pass |

**Result: All tests pass. Ready for review.**
```

### Environment-Specific Testing

| Environment | When to Test |
|-------------|-------------|
| Local | Always — first validation |
| Staging | Before merging — integration check |
| Production | After deploy — with feature flag or canary if risky |

---

## Phase 6: Documentation

### Commit Message

```
fix(<scope>): <what was broken and what was fixed>

Root cause: <one sentence explaining why the bug existed>
Fixes: #<issue-number>
```

Example:
```
fix(upload): handle null file size in upload middleware

Root cause: The upload form sends `fileSize` but the middleware
read `size`, returning undefined which crashed downstream validation.
Fixes: #247
```

### PR Description Template

```markdown
## Bug

[Link to issue or brief description of the reported behavior]

## Root Cause

[One paragraph explaining WHY the bug occurred — not just where]

## Fix

[What was changed and why this resolves the root cause]

## Testing

[Link to or paste the manual test record from Phase 5]

## Checklist

- [ ] Failing test added that captures the bug
- [ ] Fix makes the test pass
- [ ] Full test suite passes
- [ ] Manual test record completed
- [ ] No unrelated changes included
```

---

## Defect Workflow Checklist

**Research**
- [ ] Collected error message, steps, expected vs actual
- [ ] Searched codebase and git history for related context

**Reproduce**
- [ ] Can trigger the bug consistently
- [ ] Identified minimal reproduction case

**Root Cause**
- [ ] Identified the exact line where the defect lives
- [ ] Understood WHY (not just where) the bug occurs

**Fix**
- [ ] Written a failing test that captures the bug
- [ ] Implemented minimum fix to resolve root cause
- [ ] Test now passes

**Verify**
- [ ] Full test suite passes
- [ ] Manual test record completed
- [ ] No regression in related functionality

**Document**
- [ ] Commit message explains root cause
- [ ] PR description includes test results
