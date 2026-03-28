---
name: frontend-web-dev
description: Frontend development standards and patterns for React web apps. Use when working on React components, hooks, state management, data fetching, or testing. Triggers on frontend tasks including component creation, hook implementation, React Query usage, Zustand stores, Playwright tests, or any React frontend work.
---

# Frontend Development

## State Management

State must have a single source of truth:

| State Type                 | Where It Lives              | Examples                                        |
| -------------------------- | --------------------------- | ----------------------------------------------- |
| Navigation/identity        | URL params                  | `sessionId`, `workspaceId`, filters, pagination |
| Server/persisted data      | React Query/SWR cache       | Sessions, users, projects, any fetched data     |
| Real-time updates (SSE/WS) | Flow INTO React Query cache | Do not store in separate local state            |
| Cross-route UI state       | Zustand                     | Sidebar open/closed, user preferences           |
| Component-local UI state   | useState                    | Form inputs, hover states, modals, temporary UI |

**Do not:**

- Duplicate server data into Zustand or local state
- Have multiple components independently fetch/derive the same data
- Store SSE/WebSocket updates in separate state from the main data cache

## Component & Hook Structure

Separate logic from presentation for testability:

**Custom hooks** contain: data fetching, state management, business logic, side effects **Components** contain:
rendering, layout, styling, event handler wiring

```tsx
// GOOD - logic extracted to hook
function useSession(sessionId: string) {
  const query = useQuery({
    queryKey: ['session', sessionId],
    queryFn: () => fetchSession(sessionId),
  });
  const updateTitle = useMutation({
    /* ... */
  });
  return { ...query, updateTitle };
}

function SessionHeader({ sessionId }: Props) {
  const { data: session, updateTitle } = useSession(sessionId);
  return <Header title={session?.title} onUpdate={updateTitle} />;
}

// BAD - logic embedded in component
function SessionHeader({ sessionId }: Props) {
  const [session, setSession] = useState(null);
  useEffect(() => {
    fetch(`/api/sessions/${sessionId}`)
      .then((r) => r.json())
      .then(setSession);
  }, [sessionId]);
  // ... more logic mixed with rendering
}
```

## Testing Expectations

- **Hooks**: Unit/integration tested with `@testing-library/react` renderHook. Test business logic, state transitions,
  error handling.
- **Components**: Minimal testing; they should be thin wrappers over hooks.
- **E2E (Playwright)**: Reserved for critical user journeys only ("golden threads").

## React Query Patterns

```tsx
// Query with proper key structure
const { data, isLoading, error } = useQuery({
  queryKey: ['entity', entityId, { filters }],
  queryFn: () => api.getEntity(entityId, filters),
  staleTime: 5 * 60 * 1000, // 5 minutes
});

// Mutation with cache invalidation
const mutation = useMutation({
  mutationFn: api.updateEntity,
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ['entity'] });
  },
});

// Optimistic updates for responsive UI
const mutation = useMutation({
  mutationFn: api.updateEntity,
  onMutate: async (newData) => {
    await queryClient.cancelQueries({ queryKey: ['entity', id] });
    const previous = queryClient.getQueryData(['entity', id]);
    queryClient.setQueryData(['entity', id], newData);
    return { previous };
  },
  onError: (err, newData, context) => {
    queryClient.setQueryData(['entity', id], context?.previous);
  },
});
```

### Mutation Standards (IMPORTANT)

```tsx
// CORRECT: Async onSuccess with awaited invalidation
onSuccess: async (data) => {
  await Promise.allSettled([
    queryClient.invalidateQueries({ queryKey: ['items'] }),
    queryClient.invalidateQueries({ queryKey: ['item', data.id] }),
  ]);
  options?.onSuccess?.(data);
}

// WRONG: Fire-and-forget (causes race conditions)
onSuccess: () => {
  queryClient.invalidateQueries({ queryKey: ['items'] }); // No await!
}
```

**Key rules:**
- `onSuccess` with `invalidateQueries` MUST be async and await
- `onMutate` MUST call `cancelQueries` before `setQueryData`
- `onError` MUST rollback using context from `onMutate`
- Never use TanStack's `retry` option — handle retries inside `mutationFn`

### Single Query, Multiple Consumers

When multiple hooks need different slices of the same API response, use ONE base query with `select`. This prevents
duplicate fetches and ensures cache consistency.

```tsx
// BAD - Multiple hooks with different keys = multiple fetches of same endpoint
const useTitle = (id) => useQuery({ queryKey: ['session', id, 'title'], queryFn: () => getSession(id) });
const useIntel = (id) => useQuery({ queryKey: ['session', id, 'intel'], queryFn: () => getSession(id) });

// GOOD - Base query + select (same key = one fetch, React Query dedupes)
const useSessionDetail = (id, options) => useQuery({
  queryKey: ['session', id],
  queryFn: () => getSession(id),
  select: options?.select,
});
const useTitle = (id) => useSessionDetail(id, { select: (s) => s.name });
const useIntel = (id) => useSessionDetail(id, { select: (s) => s.attached_intel });
```

### Cross-Entity Cache Invalidation

When a mutation on Entity A affects Entity B's display, invalidate BOTH caches:

```tsx
const toggleStar = useMutation({
  mutationFn: () => api.patch(`/session/${id}`, { is_starred: !current }),
  onSettled: () => {
    queryClient.invalidateQueries({ queryKey: ['session', id] });
    queryClient.invalidateQueries({ queryKey: ['sessions'] });
  },
});
```

### SSE Events: Invalidate, Don't Stub

**CRITICAL**: When handling SSE events that notify about new/changed server data, **invalidate the query to fetch from
server**. Never create stub/placeholder data in the cache.

```tsx
// BAD - Creates stub data with missing fields (causes "No content" bugs)
const handleArtifactCreated = (data) => {
  queryClient.setQueryData(artifactsQueryKey(sessionId), (old) => [
    ...old,
    { id: data.artifactId, content: '', title: data.title }  // ❌ Empty content!
  ]);
};

// GOOD - Invalidate to fetch complete data from server
const handleArtifactCreated = (data) => {
  queryClient.invalidateQueries({ queryKey: artifactsQueryKey(sessionId) });
};
```

**When to use `setQueryData` directly:**
- Optimistic updates for user actions (you have the complete data)
- Appending messages during streaming (content is in the SSE event)
- Removing items from lists (you just need the ID)

**When to use `invalidateQueries`:**
- SSE notifies about server-side creation/updates you don't have full data for

## Quick Reference

- **New data fetching**: Create a custom hook with React Query, not useEffect
- **New global UI state**: Zustand store in `stores/`
- **New component**: Keep it thin, extract logic to hooks
- **URL-dependent state**: Use URL params, not React state
- **SSE/WebSocket data**: Update React Query cache directly
- **API calls**: Use typed API client hooks

## Design System

Use your project's design tokens for all styling — avoid arbitrary Tailwind values when design tokens exist.

See [references/code-connect-components.md](references/code-connect-components.md) for component props reference.
