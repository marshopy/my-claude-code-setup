---
name: useeffect-reviewer
description: Expert code review skill for identifying unnecessary useEffect usage in React code and suggesting better patterns. Use this skill when reviewing React code, conducting PR reviews, or when asked to check useEffect usage. Applies modern React guidance (React 19+): useEffect should be rare; prefer derived state, event handlers, React Query; use useEffectEvent to avoid stale closures; use startTransition for non-urgent updates; use to unwrap framework promises where suspension is desired.
---

# useEffect Reviewer

## Overview

Review React code for proper useEffect usage following the principle: **Don't use useEffect unless absolutely
necessary**. Most useEffect instances can be replaced with better patterns that are simpler, more efficient, and easier
to maintain.

## When to Use This Skill

- When conducting code reviews or PR reviews
- When asked to review useEffect usage
- When refactoring React components
- When investigating performance issues or unnecessary re-renders
- When a user asks "is this useEffect necessary?"

## Review Process

Follow this workflow to systematically review useEffect usage:

### Step 1: Search for useEffect Usage

Search the codebase for all useEffect instances:

```bash
# Find all useEffect with surrounding context
grep -r "useEffect" --include="*.tsx" --include="*.ts" -n -C 10
```

Focus on common locations:

- `src/components/**/*.tsx`
- `src/hooks/**/*.ts`
- `src/pages/**/*.tsx`

### Step 2: Categorize Each useEffect

For each useEffect found, categorize it as:

- ✅ **Legitimate**: External system synchronization (WebSockets, browser APIs, third-party libs)
- ❌ **Anti-pattern**: Should be replaced with better pattern
- ⚠️ **Needs Review**: Unclear if necessary

### Step 3: Analyze Anti-Patterns

For each anti-pattern, identify the type and provide refactoring guidance.

## Anti-Pattern Detection Guide

### 1. Derived State → Calculate During Render

**Detect:**

```typescript
useEffect(() => {
  set[Something](compute(props));
}, [props]);
```

**Refactor to:**

```typescript
const something = compute(props);
// Or if expensive:
const something = useMemo(() => compute(props), [props]);
```

**Why:** Eliminates unnecessary re-renders and state synchronization.

---

### 2. Event Handling → Use Event Handlers

**Detect:**

```typescript
useEffect(() => {
  if (someCondition) {
    // Do something in response to state change
  }
}, [someState]);
```

**Refactor to:**

```typescript
const handleEvent = () => {
  const newState = computeNewState();
  setState(newState);
  if (someCondition(newState)) {
    // Do something immediately
  }
};
```

**Why:** Makes cause-and-effect clear, provides immediate feedback.

---

### 2b. Non‑urgent updates → startTransition at event site

**Detect:**

```typescript
// Inside effect after state change
useEffect(() => {
  setFiltered(expensiveFilter(items));
}, [items]);
```

**Refactor to:**

```typescript
import { startTransition } from 'react';

const onItemsChange = (next: Item[]) => {
  setItems(next); // urgent
  startTransition(() => {
    setFiltered(expensiveFilter(next)); // non‑urgent
  });
};
```

**Why:** Keeps input responsive; moves work to transition instead of reactive effects.

---

### 3. State Reset → Use key Prop

**Detect:**

```typescript
useEffect(() => {
  resetState();
}, [userId]); // Or any prop that should reset component
```

**Refactor to:**

```typescript
<Component key={userId} />
```

**Why:** React's built-in mechanism for resetting state, no extra render.

---

### 4. Chains of Effects → Use React Query

**Detect:**

```typescript
useEffect(() => {
  fetchData().then(setData);
}, []);

useEffect(() => {
  if (data) setProcessed(transform(data));
}, [data]);
```

**Refactor to:**

```typescript
// Use React Query + derived state
const { data } = useQuery({ queryKey: ['data'], queryFn: fetchData });
const processed = data ? transform(data) : null;
```

**Why:** Reduces render cycles, clearer data flow, better caching and error handling.

---

### 5. Parent Notifications → Lift State

**Detect:**

```typescript
useEffect(() => {
  onParentCallback(localState);
}, [localState]);
```

**Refactor to:**

```typescript
const handleChange = (newValue) => {
  onParentCallback(newValue); // Parent manages state
};
```

**Why:** Single source of truth, batched updates.

---

### 6. Data Fetching → Use React Query

**Detect:**

```typescript
useEffect(() => {
  fetch('/api/data')
    .then((r) => r.json())
    .then(setData);
}, []);
```

**Refactor to:**

```typescript
const { data } = useQuery({
  queryKey: ['data'],
  queryFn: () => fetch('/api/data').then((r) => r.json()),
});
```

**Why:** Better caching, error handling, loading states, refetching.

---

### 7. Stale Closure in Effects → useEffectEvent

**Detect:**

```typescript
useEffect(() => {
  const handler = () => {
    // uses stale props/state or forces handler into deps
    doSomething(state, props.value);
  };
  socket.on('message', handler);
  return () => socket.off('message', handler);
}, [socket /*, state, props.value */]);
```

**Refactor to:**

```typescript
import { useEffectEvent } from 'react';

const onMessage = useEffectEvent((payload) => {
  // always latest state/props here
  doSomething(state, props.value);
});

useEffect(() => {
  socket.on('message', onMessage);
  return () => socket.off('message', onMessage);
}, [socket]);
```

**Why:** Avoids stale closures and bloated dependency arrays.

---

### 7. Data Loading with useCallback → Use React Query

**Detect:**

```typescript
const loadData = useCallback(() => {
  /* fetch/load data */
}, []);
useEffect(() => {
  loadData();
}, [loadData]);
```

**Refactor to:**

```typescript
const { data } = useQuery({
  queryKey: ['data'],
  queryFn: loadData,
});
```

**Why:** Eliminates unnecessary memoization complexity, provides better caching, loading states, and error handling.

---

## Legitimate useEffect Patterns

**Only use useEffect for external system synchronization:**

### Valid Use Cases

1. **WebSocket connections** - Prefer `useSyncExternalStoreWithSelector` + `useEffectEvent`

   ```typescript
   // ❌ AVOID - Local state management
   useEffect(() => {
     const ws = new WebSocket(url);
     ws.onmessage = handleMessage;
     return () => ws.close();
   }, [url]);

   // ✅ BETTER - Shared store with useSyncExternalStoreWithSelector
   // Create a shared WebSocket store that all components can subscribe to
   // This ensures coordinated state management across all consumers
   const useWebSocketData = () => {
     return useSyncExternalStoreWithSelector(
       webSocketStore.subscribe,
       webSocketStore.getSnapshot,
       webSocketStore.getServerSnapshot,
       selector,
     );
   };
   ```

2. **Browser APIs**

   ```typescript
   useEffect(() => {
     const observer = new IntersectionObserver(handleIntersect);
     observer.observe(ref.current);
     return () => observer.disconnect();
   }, []);
   ```

3. **Third-party library initialization**

   ```typescript
   useEffect(() => {
     const chart = initializeChart(containerRef.current);
     return () => chart.destroy();
   }, []);
   ```

4. **Subscriptions with cleanup**

   ```typescript
   useEffect(() => {
     const unsubscribe = eventEmitter.on('event', handler);
     return () => unsubscribe();
   }, []);
   ```

### Verification Checklist for Legitimate Uses

For valid useEffect instances, verify:

- ✅ Complete dependency array (all referenced values included)
- ✅ Proper cleanup function (for subscriptions/timers/connections)
- ✅ No `eslint-disable` for exhaustive-deps
- ✅ Stable references (functions/objects memoized if in deps) or use `useEffectEvent` for callbacks

---

## Output Format

Provide a structured review in this format:

```````markdown
    ## useEffect Review Results

    ### Summary
    - Total useEffect instances: X
    - ✅ Legitimate (external sync): X
    - ❌ Anti-patterns to refactor: X
    - ⚠️ Needs manual review: X

    ### Anti-Patterns Found

    #### 1. [File:Line] - [Pattern Type]

    **Current Code:**
    ``````typescript
    // Show problematic code with context
    ``````

    **Issue:** [Explanation of why this is problematic]

    **Refactor:**

    ``````typescript
    // Show corrected code
    ``````

    **Impact:** [Benefits of refactoring]

    ---

    [Repeat for each anti-pattern]

    ### Legitimate Uses

    #### 1. [File:Line] - [Purpose]

    ✅ Correct use for [external system]
    [Any verification notes or suggestions]

    ### Recommendations

    1. [Priority fixes]
    2. [Team education suggestions]
    3. [Tooling recommendations]
```````

## Key Principles

When conducting reviews, emphasize these principles:

1. **Default to NO useEffect** - Question every use
2. **Ask: "Am I synchronizing with an external system?"** - If no, don't use useEffect
3. **Prefer derived state** - Calculate during render
4. **Use event handlers** - For user interactions and business logic
5. **Use React Query** - For all data fetching
6. **Use key prop** - For resetting component state
7. **Define functions inside effects** - Avoid unnecessary memoization complexity

## References

- [React Docs: You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect)
- [React 19 Docs](https://react.dev/blog/2024/12/05/react-19)
- Modern React APIs to consider: `useEffectEvent`, `startTransition`, `use`
- [Epic React: Myths about useEffect](https://www.epicreact.dev/myths-about-useeffect)
