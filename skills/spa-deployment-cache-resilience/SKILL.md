---
name: spa-deployment-cache-resilience
description: >-
  Single Page Application (SPA) deployment cache resilience, dynamic chunk preload failure recovery,
  Service Worker HTML cache-poisoning prevention, and negative-lookahead SPA routing for Vite, React Router,
  Vercel, and PWA environments. Distilled from real-world post-deployment chunk mismatch and CSS preload error
  troubleshooting. Use when debugging "Unable to preload CSS", "Failed to fetch dynamically imported module",
  "Unexpected token <", ErrorBoundary crashes on first load requiring Ctrl+Shift+R, or configuring zero-downtime SPA caching.
---

# SPA Deployment Cache Resilience & Preload Failure Recovery

A battle-tested architecture and runbook for eliminating post-deployment chunk mismatches, Service Worker cache poisoning, dynamic CSS preload rejections, and SPA rewrite collisions across React, Vite, and modern cloud hosting environments (Vercel, Netlify, Cloudflare Pages, Nginx).

---

## 1. When to Activate This Skill
- **Symptom 1:** Users encounter `Error: Unable to preload CSS for /assets/...` on initial load or route transition.
- **Symptom 2:** Users see an `ErrorBoundary` crash ("Something went wrong") on the first visit after a release, but pressing `Ctrl + Shift + R` makes the website load normally.
- **Symptom 3:** Browser console reports `SyntaxError: Unexpected token '<'` or `TypeError: Failed to fetch dynamically imported module`.
- **Symptom 4:** Service Worker serves outdated or corrupt assets, forcing clients into inconsistent application states.
- **Symptom 5:** Configuring SPA routing rewrites on Vercel, Netlify, or Nginx to ensure missing static assets return `404 Not Found` rather than `200 OK (text/html)`.

---

## 2. Anatomy of the Failure Chain

In single-page applications deployed with content-hashed bundles and Service Workers, a naive configuration creates a compounding failure cycle:

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 1. New Production Deployment occurs (Vite emits new hashed chunks)              │
└─────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 2. Client requests an obsolete asset (e.g. /assets/landing-OLD.css)             │
│    (From cached index.html or an active user session)                          │
└─────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 3. Catch-all SPA rewrite (/(.*) -> /index.html) intercepts missing asset        │
│    Server returns HTTP 200 OK with HTML content (<!doctype html>)               │
└─────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 4. Service Worker caches HTML response under the .css or .js URL                │
│    CacheStorage is now permanently POISONED for that asset                      │
└─────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 5. Browser inspects response: MIME is text/html, but script/style was expected  │
│    X-Content-Type-Options: nosniff blocks execution                             │
│    Vite preload helper fires <link>.onerror -> throws "Unable to preload CSS"   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 6. React Suspense fails -> ErrorBoundary catches error -> App crashes           │
│    Normal reload reuses poisoned SW cache! (Only Ctrl+Shift+R bypasses SW)      │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. The 5-Layer Defense Architecture

To achieve zero-downtime client deployments that never require users to perform hard refreshes, apply all 5 layers:

```
┌────────────────────────────────────────────────────────────────────────┐
│ Layer 1: Unified CSS Bundling (vite.config.js: cssCodeSplit: false)     │
│ -> Eliminates dynamic <link> preloads; all styles load with HTML shell │
├────────────────────────────────────────────────────────────────────────┤
│ Layer 2: Negative-Lookahead SPA Rewrites (vercel.json / netlify.toml)  │
│ -> Missing /assets/* return 404, never 200 HTML                        │
├────────────────────────────────────────────────────────────────────────┤
│ Layer 3: Service Worker MIME-Aware Cache Guard (sw.js)                 │
│ -> Never cache text/html for code assets; purge corrupt entries        │
├────────────────────────────────────────────────────────────────────────┤
│ Layer 4: Vite Dynamic Preload Auto-Recovery (main.jsx)                 │
│ -> vite:preloadError event handler throttles and reloads safely        │
├────────────────────────────────────────────────────────────────────────┤
│ Layer 5: ErrorBoundary Self-Healing (ErrorBoundary.jsx)                │
│ -> Purges CacheStorage on chunk errors and user reload clicks          │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Implementation Runbook & Code Reference

### 4.1 Layer 1: Unified CSS Bundling in Vite
By default, Vite splits CSS per lazy-loaded route (`cssCodeSplit: true`). When dynamic imports are invoked, Vite injects dynamic `<link rel="stylesheet">` elements via JavaScript. If an asset is missing or blocked, Vite throws an unhandled rejection.

For applications with small-to-medium total CSS bundles (< 200KB), disabling `cssCodeSplit` combines all CSS into a single static file included in `<head>`:

```javascript
// vite.config.js
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  build: {
    // Bundle all component styles into a single static stylesheet
    // Eliminates dynamic runtime CSS preloading and associated network crashes
    cssCodeSplit: false,
    rollupOptions: {
      output: {
        manualChunks: {
          "vendor-react": ["react", "react-dom", "react-router-dom"],
        },
      },
    },
  },
});
```

### 4.2 Layer 2: Negative-Lookahead SPA Hosting Rewrites
Never rewrite static asset directories to `/index.html`. If an asset does not exist, the server **must** return `404 Not Found` so browser loaders and service workers recognize the failure immediately.

#### Vercel Configuration (`vercel.json`)
```json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "X-Frame-Options", "value": "DENY" }
      ]
    }
  ],
  "rewrites": [
    {
      "source": "/((?!assets/|IMAGES/|sw\\.js|manifest\\.webmanifest|favicon\\.ico).*)",
      "destination": "/index.html"
    }
  ]
}
```

#### Netlify Configuration (`_redirects` / `netlify.toml`)
```toml
# netlify.toml
[[redirects]]
  from = "/assets/*"
  to = "/assets/:splat"
  status = 404

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

#### Nginx Configuration (`nginx.conf`)
```nginx
location /assets/ {
    try_files $uri =404;
    expires 1y;
    add_header Cache-Control "public, immutable";
}

location / {
    try_files $uri $uri/ /index.html;
}
```

### 4.3 Layer 3: Service Worker MIME-Aware Cache Storage
In your Service Worker `sw.js`, add strict MIME type validation before saving network responses to cache. If a `.js` or `.css` request returns `text/html`, discard it immediately. If a poisoned entry already exists in cache, evict it.

```javascript
// sw.js
const CACHE_VERSION = "v1.0.5";
const STATIC_CACHE = `app-static-${CACHE_VERSION}`;

/**
 * Stale-While-Revalidate with strict MIME-type guards
 */
async function staleWhileRevalidate(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cachedResponse = await cache.match(request);
  const isCodeAsset = /\.(js|css)$/i.test(request.url);

  // 1. Inspect existing cached response: purge if poisoned with HTML
  if (cachedResponse) {
    const cachedType = cachedResponse.headers.get("content-type") || "";
    if (isCodeAsset && cachedType.includes("text/html")) {
      await cache.delete(request);
    } else {
      // Revalidate in background without blocking render
      fetch(request.clone())
        .then((networkResponse) => {
          if (networkResponse?.ok) {
            const netType = networkResponse.headers.get("content-type") || "";
            if (!isCodeAsset || !netType.includes("text/html")) {
              cache.put(request, networkResponse.clone());
            }
          }
        })
        .catch(() => null);

      return cachedResponse;
    }
  }

  // 2. Fetch fresh from network with MIME verification
  try {
    const networkResponse = await fetch(request.clone());
    if (networkResponse && networkResponse.ok) {
      const netType = networkResponse.headers.get("content-type") || "";
      // CRITICAL: Never cache text/html under a .js or .css URL
      if (!isCodeAsset || !netType.includes("text/html")) {
        cache.put(request, networkResponse.clone());
      }
    }
    return networkResponse;
  } catch (err) {
    if (cachedResponse) return cachedResponse;
    throw err;
  }
}
```

### 4.4 Layer 4: Global `vite:preloadError` Auto-Recovery
Vite provides a dedicated window event, `vite:preloadError`, whenever dynamic import chunks fail to fetch. Intercept this event, call `event.preventDefault()` to stop the exception from bubbling to React, and execute a throttled reload to fetch the latest `index.html`.

```javascript
// src/main.jsx
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App.jsx";

// Intercept chunk loading errors caused by post-deployment hash changes
window.addEventListener("vite:preloadError", (event) => {
  console.warn("[Vite] Preload error detected:", event.payload);
  event.preventDefault(); // Stop unhandled rejection from crashing ErrorBoundary

  const lastReload = sessionStorage.getItem("vite_preload_retry");
  const now = Date.now();
  // Throttle reload to at most once per 10 seconds to prevent infinite reload loops
  if (!lastReload || now - parseInt(lastReload, 10) > 10000) {
    sessionStorage.setItem("vite_preload_retry", String(now));
    window.location.reload();
  }
});

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
```

### 4.5 Layer 5: ErrorBoundary Self-Healing & Cache Clearing
Ensure the root `ErrorBoundary` automatically clears browser `CacheStorage` before reloading. Users clicking "Reload Page" must never be trapped in a stale cache loop.

```jsx
// src/components/ErrorBoundary.jsx
import React from "react";

export default class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error("[ErrorBoundary] Caught error:", error, errorInfo);

    // Auto-recover from stale chunks or preload errors after new releases
    const isChunkOrPreloadError = error?.message && (
      error.message.includes("dynamically imported module") ||
      error.message.includes("Unable to preload") ||
      error.message.includes("Unexpected token")
    );

    if (isChunkOrPreloadError) {
      const lastRetry = sessionStorage.getItem("chunk_auto_retry");
      const now = Date.now();
      if (!lastRetry || now - parseInt(lastRetry, 10) > 15000) {
        sessionStorage.setItem("chunk_auto_retry", String(now));
        // Clear all caches and force clean reload
        if ("caches" in window) {
          caches.keys().then(keys => Promise.all(keys.map(k => caches.delete(k))))
            .finally(() => { window.location.reload(); });
        } else {
          window.location.reload();
        }
      }
    }
  }

  handleReload = async () => {
    this.setState({ hasError: false, error: null });
    // Guarantee clean state for manual user reload
    if ("caches" in window) {
      try {
        const keys = await caches.keys();
        await Promise.all(keys.map(k => caches.delete(k)));
      } catch (e) {
        console.warn("[ErrorBoundary] Cache purge error:", e);
      }
    }
    window.location.reload();
  };

  render() {
    if (this.state.hasError) {
      return (
        <div className="error-fallback">
          <h2>Something went wrong</h2>
          <button onClick={this.handleReload}>Reload Page</button>
        </div>
      );
    }
    return this.props.children;
  }
}
```

---

## 5. Verification & Testing Checklist

When auditing or validating an SPA deployment:

| Check | Test Command / Action | Expected Result |
| :--- | :--- | :--- |
| **Asset 404 Response** | `curl -i https://app.example.com/assets/nonexistent.js` | HTTP `404 Not Found` (never `200 OK` or `text/html`) |
| **CSS Preload Elimination** | Inspect generated `index.html` after build | Contains single `<link rel="stylesheet">`, zero dynamic CSS chunks |
| **Service Worker Invalidation** | Inspect `caches.keys()` in DevTools | Old cache versions purged upon Service Worker `activate` |
| **Initial Load Cleanliness** | Load site in a fresh incognito window | Homepage renders immediately with zero console errors or `ErrorBoundary` triggers |
| **Bypass Necessity** | Reload page without `Ctrl + Shift + R` | Page renders cleanly; hard refresh is completely unnecessary |
