---
name: spa-deployment-cache-resilience
description: >-
  Single Page Application (SPA) deployment cache resilience, dynamic chunk preload
  failure recovery, Service Worker HTML cache-poisoning prevention, and negative-lookahead
  SPA routing for Vite, React Router, Vercel, and PWA environments. Distilled from real-world
  post-deployment chunk mismatch and CSS preload error troubleshooting. Use when debugging
  "Unable to preload CSS", "Failed to fetch dynamically imported module", "Unexpected token <",
  ErrorBoundary crashes on first load requiring Ctrl+Shift+R, or configuring zero-downtime SPA caching.
---

# SPA Deployment Cache Resilience & Chunk Recovery

A definitive runbook for diagnosing and eliminating post-deployment asset caching bugs, "white screens of death", missing icons, and stale Service Worker chunk mismatches in Single Page Applications (Vite, React, Vercel, Netlify).

---

## 1. The Root Cause: Why Icons/Chunks Fail Until "Ctrl + Shift + R"

When modern web apps are built, bundlers generate content-hashed filenames for JavaScript and CSS chunks (e.g. `index-D8IlDZVV.js`, `icons-vendor-CwF3K6zW.js`).

When a new version is deployed to hosting platforms (Vercel, Cloudflare, Netlify, S3/CloudFront):
1. **The Stale HTML Trap:** The user's browser or service worker serves a cached `index.html` from the previous deployment because `index.html` lacked `Cache-Control: max-age=0, must-revalidate`.
2. **The Catch-All Rewrite Trap:** The stale `index.html` requests the old chunk hash (`icons-vendor-OLD.js`). Because the host's SPA routing rule rewrites `/(.*)` to `/index.html`, the server returns HTTP 200 with HTML text (`<!doctype html>...`) instead of returning a 404 or JavaScript!
3. **The MIME / Syntax Crash:** The browser attempts to execute the HTML response as JavaScript and throws `SyntaxError: Unexpected token '<'` or `Failed to fetch dynamically imported module`. The icon chunk fails to load, and icons across the entire UI fail to render!
4. **Why Hard Refresh (Ctrl + Shift + R) "Fixes" It:** Ctrl + Shift + R forces the browser to bypass all caches, fetch the latest `index.html`, and request the current chunk hashes.

---

## 2. Core Guidelines & Best Practices

### 1. Strict Cache-Control Headers in Hosting Configuration
Never allow browsers or CDNs to cache `index.html` or Service Worker scripts:
- `index.html`, `sw.js`, `registerSW.js` -> `Cache-Control: public, max-age=0, must-revalidate`
- `/assets/*` (hashed files) -> `Cache-Control: public, max-age=31536000, immutable`

**Example: `vercel.json`**
```json
{
  "headers": [
    {
      "source": "/index.html",
      "headers": [{ "key": "Cache-Control", "value": "public, max-age=0, must-revalidate" }]
    },
    {
      "source": "/(sw\\.js|registerSW\\.js)",
      "headers": [{ "key": "Cache-Control", "value": "public, max-age=0, must-revalidate" }]
    },
    {
      "source": "/assets/(.*)",
      "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }]
    }
  ]
}
```

### 2. Negative-Lookahead SPA Routing
Prevent SPA rewrites from masking deleted chunks with `index.html`. If an asset does not exist, it MUST return a true 404 so error handlers can detect the version change:
```json
// ❌ FRAGILE: Rewrites deleted JS chunks to HTML
{ "source": "/(.*)", "destination": "/index.html" }

// ✅ RESILIENT: Negative-lookahead protects /assets/ and file extensions
{ "source": "/((?!assets/|.*\\..*).*)", "destination": "/index.html" }
```

### 3. Automated Chunk Preload Error Recovery (Vite)
Add automated reload listeners in `main.jsx` to seamlessly recover from deployment chunk mismatches without user intervention:
```javascript
// Auto-recover from dynamic import / chunk preload mismatches
window.addEventListener('vite:preloadError', (event) => {
  console.warn('[Vite] Chunk preload mismatch. Auto-refreshing for latest deployment...', event);
  const reloadKey = 'app_chunk_reload';
  const lastReload = parseInt(sessionStorage.getItem(reloadKey) || '0', 10);
  const now = Date.now();
  if (now - lastReload > 8000) {
    sessionStorage.setItem(reloadKey, now.toString());
    window.location.reload();
  }
});

// Fallback for script MIME / syntax errors on stale chunk rewrites
window.addEventListener('error', (event) => {
  const isChunkError = 
    event?.message?.includes('Failed to fetch dynamically imported module') ||
    event?.message?.includes('Importing a module script failed') ||
    event?.message?.includes("Unexpected token '<'");

  if (isChunkError) {
    const reloadKey = 'app_chunk_reload';
    const lastReload = parseInt(sessionStorage.getItem(reloadKey) || '0', 10);
    const now = Date.now();
    if (now - lastReload > 8000) {
      sessionStorage.setItem(reloadKey, now.toString());
      window.location.reload();
    }
  }
});
```

### 4. PWA / Service Worker Tug-of-War Prevention
- Never call `registration.unregister()` on `window.load` while simultaneously using a PWA plugin (`VitePWA`) that auto-registers service workers. This leaves orphaned caches in `CacheStorage`.
- In `vite.config.js`, configure Workbox to purge old caches and activate immediately:
  ```javascript
  workbox: {
    cleanupOutdatedCaches: true,
    clientsClaim: true,
    skipWaiting: true,
    navigateFallback: '/index.html',
    navigateFallbackDenylist: [/^\/api\//, /^\/assets\//]
  }
  ```

### 5. Keep Core Visual Primitives in the Main Bundle
- Do not split lightweight, universally-used visual libraries (like `lucide-react`, which is ~32kB) into separate asynchronous chunks (`icons-vendor`).
- Reserve `manualChunks` exclusively for heavy, deferred dependencies (e.g. `jspdf`, `docx`, heavy chart libraries) that are not needed on the initial screen.

---

## 3. Verification & Validation
- **Deployment Verification:** Deploy a new build, keep an old browser tab open, and click a link to a lazy-loaded route. Assert the page automatically reloads seamlessly without throwing unhandled exceptions.
- **Cache-Control Audit:** Inspect HTTP response headers via `curl -I https://app.example.com/index.html`. Verify `Cache-Control: max-age=0, must-revalidate` is returned.
- **Asset 404 Audit:** Inspect `curl -I https://app.example.com/assets/nonexistent-hash.js`. Verify it returns HTTP 404 (NOT 200 with HTML text).
