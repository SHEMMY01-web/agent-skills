---
name: react-best-practices
description: Production-grade React 18 component patterns, hooks optimization, lazy-loading, suspense boundaries, and DOM sanitization from agentic-awesome-skills.
---

# React Best Practices (Agentic Awesome Skills)

## Core Guidelines

### 1. Code-Splitting & Dynamic Imports
- Lazy-load heavy or secondary modules using `React.lazy()` and `Suspense`:
  ```javascript
  const TemplateGallery = lazy(() => import('./components/Templates/TemplateGallery'));
  ```
- Always provide clean fallback indicators:
  ```jsx
  <Suspense fallback={<div className="p-8 text-center text-sm font-mono text-slate-400">Loading module...</div>}>
    <TemplateGallery />
  </Suspense>
  ```

---

### 2. State & Effect Isolation
- Keep local state close to the component where it is used.
- Avoid unnecessary `useEffect` chains; derive values directly during render where possible.
- Memoize heavy callbacks with `useCallback` when passed to optimized memoized children.

---

### 3. Security & DOM Sanitization
- Always sanitize dynamic HTML strings before rendering with `dangerouslySetInnerHTML` using `DOMPurify.sanitize()`.
- Use native `crypto.randomUUID()` instead of external packages when generating client-side unique keys.
