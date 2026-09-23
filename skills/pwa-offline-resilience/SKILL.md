---
name: pwa-offline-resilience
description: >-
  Progressive Web App (PWA) service worker caching architecture, multi-tier cache partitioning,
  mutation bypass safety, network timeout race wrappers, and offline synchronization strategies
  distilled from CIH Inventory. Use when building or auditing offline-capable web apps, mobile PWAs,
  or service workers to eliminate stale data bugs and caching race conditions.
---

# PWA Offline Resilience & Service Worker Architecture

A robust pattern for building production-grade Progressive Web Apps that remain fully functional in low-connectivity or offline environments while strictly avoiding stale mutation bugs and cache bloat.

---

## 1. When to Activate This Skill
- Designing or debugging Service Worker lifecycle events (`install`, `activate`, `fetch`).
- Partitioning caches by asset type (static shell, user images, typography, REST API queries).
- Preventing mutation caching bugs (ensuring `POST`, `PATCH`, `DELETE`, and RPCs bypass CacheStorage).
- Eliminating browser fetch hangs on high-latency or unstable mobile data connections.
- Implementing Single-Page Application (SPA) navigation fallbacks and background synchronization.

---

## 2. Multi-Tier Cache Architecture

Do not lump all assets into a single monolithic cache. Partition by volatility and invalidation rules:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. STATIC CACHE (cih-static-vX)                             │
│ - HTML shell, webmanifest, core icons, critical CSS/JS      │
│ - Strategy: Stale-While-Revalidate or Precache on install   │
├─────────────────────────────────────────────────────────────┤
│ 2. IMAGES CACHE (cih-images-vX)                             │
│ - Product photos, avatars, diagrams, logos                  │
│ - Strategy: Cache-First with Network Fallback               │
├─────────────────────────────────────────────────────────────┤
│ 3. FONTS CACHE (cih-fonts-vX)                               │
│ - Google Fonts stylesheets and WOFF2 binaries               │
│ - Strategy: Cache-First (immutable remote assets)           │
├─────────────────────────────────────────────────────────────┤
│ 4. API CACHE (cih-api-vX)                                   │
│ - Read-only public catalog queries (GET /rest/v1/items)     │
│ - Strategy: Network-First with Cache Fallback (3s timeout)  │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Core Implementation Guidelines

### 3.1 Strict Mutation Bypass Guard
`CacheStorage` only supports idempotent `GET` requests. Attempting to match or put `POST`, `PUT`, `PATCH`, or `DELETE` requests will throw errors or serve stale transactional data:

```javascript
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // RULE 1: Completely bypass non-GET requests
  if (request.method !== 'GET') {
    return;
  }

  // RULE 2: Bypass browser extension schemes (chrome-extension://)
  if (!url.protocol.startsWith('http')) {
    return;
  }

  // RULE 3: Bypass privileged or transactional API endpoints
  if (url.pathname.includes('/rpc/') || 
      url.pathname.includes('/transactions') || 
      url.pathname.includes('/auth/')) {
    return;
  }

  // Route to appropriate caching strategy...
});
```

---

### 3.2 Network Timeout Wrapper (Anti-Hanging)
On 3G or unstable connections, standard `fetch()` can hang for 30–60 seconds before failing, freezing the UI. Race the network against a strict timeout:

```javascript
/**
 * Executes a network fetch with an aggressive timeout guard.
 * If the network fails or times out, seamlessly falls back to cached data.
 */
async function networkFirstWithTimeout(request, cacheName, timeoutMs = 3000) {
  const cache = await caches.open(cacheName);

  const timeoutPromise = new Promise((_, reject) => {
    setTimeout(() => reject(new Error('Network timeout')), timeoutMs);
  });

  try {
    const networkResponse = await Promise.race([
      fetch(request.clone()),
      timeoutPromise
    ]);

    // Cache valid 200 responses
    if (networkResponse && networkResponse.status === 200) {
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (err) {
    console.warn(`[SW] Network fetch failed or timed out (${err.message}). Serving from cache.`);
    const cachedResponse = await cache.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    throw err;
  }
}
```

---

### 3.3 Cache-First for Heavy Media & Static Assets
```javascript
async function cacheFirstStrategy(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(request);
  if (cached) {
    return cached;
  }

  try {
    const fresh = await fetch(request);
    if (fresh && fresh.status === 200) {
      cache.put(request, fresh.clone());
    }
    return fresh;
  } catch (err) {
    // Return offline placeholder image if media request fails
    if (request.destination === 'image') {
      return caches.match('/IMAGES/empty-state.png');
    }
    throw err;
  }
}
```

---

### 3.4 Safe Cache Purging on Version Bump
When updating the application, purge all previous cache versions during the `activate` event and immediately claim clients:

```javascript
const CURRENT_CACHES = [STATIC_CACHE, IMAGES_CACHE, FONTS_CACHE, API_CACHE];

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (!CURRENT_CACHES.includes(key)) {
            console.log(`[SW] Deleting obsolete cache: ${key}`);
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});
```

---

### 3.5 SPA Navigation Fallback
Ensure client-side routing works offline by serving the shell `/index.html` when navigating:

```javascript
if (request.mode === 'navigate') {
  event.respondWith(
    fetch(request).catch(async () => {
      return (await caches.match('/index.html')) || caches.match('/');
    })
  );
  return;
}
```

---

## 4. Verification Checklist
- [ ] Inspect DevTools > Application > Service Workers: verify only `GET` requests are stored in CacheStorage.
- [ ] Simulate "Offline" in Network tab: verify the SPA shell loads and cached images display.
- [ ] Simulate "Slow 3G": verify that API requests fall back to cache after 3 seconds rather than spinning indefinitely.
- [ ] Verify that new versions delete old cache keys and take control without requiring full manual cache clears.
