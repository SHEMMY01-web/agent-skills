---
name: cloud-keepalive-resilience
description: Enterprise-grade keep-alive, database warming, and cold-start absorption patterns for free-tier and serverless cloud services (Render, Supabase, Fly.io, Vercel, Railway, Neon). Covers GitHub Actions cron workflows, retry loops with backoff, connection timeouts, flexible 2xx status handling, and diagnostic logging.
---

# Cloud Keep-Alive & Cold-Start Resilience Guide

## 1. Overview & Cold-Start Mechanics

Modern cloud platforms operating on free or serverless tiers (e.g., Render, Supabase, Fly.io, Neon, Railway) employ aggressive resource reclamation policies:
- **Render / Fly / Cloud Run:** Containers spin down after 15 minutes of inactivity. The first subsequent request triggers a container cold-boot taking between 15 to 45 seconds. During this window, reverse proxies often return `502 Bad Gateway`, `503 Service Unavailable`, `504 Gateway Timeout`, or drop the TCP connection (`000`).
- **Supabase / Neon / Serverless Postgres:** Free instances pause after days or hours of zero queries, and database connection pools (PgBouncer) drop idle connections. Probing queries take several seconds to re-establish the connection pool.

### The Anti-Pattern
A single HTTP probe with rigid status checks and no timeouts:
```bash
# ❌ FRAGILE: Fails false-positively on cold starts
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://api.example.com/health)
if [ "$STATUS_CODE" -eq 200 ]; then ... else exit 1; fi
```
**Why this fails:**
1. No retry loop: If the initial probe hits a spinning container, it fails immediately even though the request successfully queued container startup.
2. Rigid `200` match: Cloud providers or cached proxies may return `204`, `206`, or `304`, causing spurious alerts.
3. No timeouts: Without `--connect-timeout` and `--max-time`, curl can hang indefinitely on stuck gateways, consuming CI runner minutes.
4. Silent swallowing: `-o /dev/null` hides error response payloads, preventing diagnostics.

---

## 2. Core Resilience Pillars

All keep-alive implementations (whether GitHub Actions, Node.js background workers, or shell scripts) must enforce these 5 pillars:

1. **Multi-Attempt Retry Loop with Backoff:**
   Execute 3 to 4 attempts. Wait 8 to 10 seconds between attempts so the container or database instance has time to finish initializing before the next probe.
2. **Strict Timeouts:**
   Set `--connect-timeout 10` (max seconds to establish TCP handshake) and `--max-time 30` (or `60` for container cold starts).
3. **Flexible 2xx Acceptance:**
   Accept any status code in the range `200-299` (`[ "$STATUS_CODE" -ge 200 ] && [ "$STATUS_CODE" -lt 300 ]`).
4. **Transparent Diagnostics:**
   Log the HTTP status code and initial response payload snippet (`head -c 250` or `JSON.stringify(data).slice(0, 250)`) on every attempt.
5. **Dual-Path Probing:**
   Probe the application API endpoint (e.g. `/api/ping-db`) first. If that fails or is pending deployment, fall back to a direct database REST probe (e.g. Supabase `/rest/v1/<table>?select=id&limit=1`).

---

## 3. GitHub Actions Cron Workflow Pattern

Schedule every 14 minutes (under Render's 15-minute threshold) with `workflow_dispatch` enabled:

```yaml
name: Cloud Keep-Alive Ping

on:
  schedule:
    - cron: '*/14 * * * *'
  workflow_dispatch:

jobs:
  keepalive:
    name: Ping Services
    runs-on: ubuntu-latest
    steps:
      - name: Ping Backend Service
        env:
          SERVICE_URL: ${{ secrets.BACKEND_URL }}
        run: |
          MAX_RETRIES=4
          RETRY_DELAY=10
          SUCCESS=false

          echo "📡 Pinging backend at: $SERVICE_URL/health"
          for i in $(seq 1 $MAX_RETRIES); do
            echo "--- Attempt $i of $MAX_RETRIES ---"
            HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
              --connect-timeout 10 \
              --max-time 60 \
              "$SERVICE_URL/health" || echo -e "\nfailed")

            STATUS_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)
            BODY=$(echo "$HTTP_RESPONSE" | sed '$d')

            echo "HTTP Status Code: $STATUS_CODE"
            if [ -n "$BODY" ]; then
              echo "Response: $(echo "$BODY" | head -c 250)"
            fi

            if [ "$STATUS_CODE" -ge 200 ] && [ "$STATUS_CODE" -lt 300 ]; then
              echo "✅ Success! Backend responded with HTTP $STATUS_CODE."
              SUCCESS=true
              break
            fi

            if [ "$i" -lt "$MAX_RETRIES" ]; then
              echo "⏳ Waiting ${RETRY_DELAY}s for container cold-start..."
              sleep $RETRY_DELAY
            fi
          done

          if [ "$SUCCESS" = false ]; then
            echo "⚠️ Backend did not return 2xx within $MAX_RETRIES attempts."
          fi

      - name: Direct Supabase Database Fallback Probe
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_KEY: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY || secrets.SUPABASE_ANON_KEY }}
        run: |
          MAX_RETRIES=4
          RETRY_DELAY=8
          SUCCESS=false

          echo "🗄️ Sending direct REST ping to Supabase: $SUPABASE_URL"
          for i in $(seq 1 $MAX_RETRIES); do
            echo "--- Attempt $i of $MAX_RETRIES ---"
            HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
              --connect-timeout 10 \
              --max-time 30 \
              -H "apikey: $SUPABASE_KEY" \
              -H "Authorization: Bearer $SUPABASE_KEY" \
              "$SUPABASE_URL/rest/v1/items?select=id&limit=1" || echo -e "\nfailed")

            STATUS_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)
            BODY=$(echo "$HTTP_RESPONSE" | sed '$d')

            echo "HTTP Status Code: $STATUS_CODE"
            if [ -n "$BODY" ]; then
              echo "Response: $(echo "$BODY" | head -c 250)"
            fi

            if [ "$STATUS_CODE" -ge 200 ] && [ "$STATUS_CODE" -lt 300 ]; then
              echo "✅ Success! Supabase database responded with HTTP $STATUS_CODE."
              SUCCESS=true
              break
            fi

            if [ "$i" -lt "$MAX_RETRIES" ]; then
              echo "⏳ Waiting ${RETRY_DELAY}s for database pool wake-up..."
              sleep $RETRY_DELAY
            fi
          done

          if [ "$SUCCESS" = false ]; then
            echo "❌ Error: Failed to ping Supabase after $MAX_RETRIES attempts."
            exit 1
          fi
```

---

## 4. Node.js In-Service Worker Pattern

When hosting an in-process background worker (e.g. inside Express or Fastify):

```javascript
const keepAliveState = {
  isRunning: false,
  totalPings: 0,
  failedPings: 0,
  lastStatus: 'uninitialized'
};

let keepAliveInterval = null;
let initialTimeout = null;

async function pingDatabase(options = {}) {
  const maxRetries = options.maxRetries ?? (process.env.NODE_ENV === 'test' ? 1 : 3);
  const retryDelayMs = options.retryDelayMs ?? (process.env.NODE_ENV === 'test' ? 10 : 1500);

  const startTime = Date.now();
  keepAliveState.totalPings++;

  let lastError = null;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      // Execute lightweight query
      const { data, error } = await supabase
        .from('items')
        .select('id')
        .limit(1);

      if (!error) {
        const latencyMs = Date.now() - startTime;
        keepAliveState.lastStatus = 'healthy';
        return { success: true, latencyMs, attempt };
      }
      lastError = error;
    } catch (err) {
      lastError = err;
    }

    if (attempt < maxRetries) {
      await new Promise(res => setTimeout(res, retryDelayMs));
    }
  }

  keepAliveState.failedPings++;
  keepAliveState.lastStatus = 'error';
  return { success: false, error: lastError.message, attempts: maxRetries };
}

function startDatabaseKeepAlive(intervalMs = 14 * 60 * 1000) {
  if (keepAliveInterval) return;
  keepAliveState.isRunning = true;

  // Initial delayed ping allows initial server boot to settle
  initialTimeout = setTimeout(() => {
    pingDatabase().catch(() => {});
  }, 10000);
  if (initialTimeout.unref) initialTimeout.unref();

  keepAliveInterval = setInterval(() => {
    pingDatabase().catch(() => {});
  }, intervalMs);
  if (keepAliveInterval.unref) keepAliveInterval.unref();
}

function stopDatabaseKeepAlive() {
  if (initialTimeout) {
    clearTimeout(initialTimeout);
    initialTimeout = null;
  }
  if (keepAliveInterval) {
    clearInterval(keepAliveInterval);
    keepAliveInterval = null;
    keepAliveState.isRunning = false;
  }
}
```

---

## 5. Standalone Bash Script Helper

A modular bash script `ping-endpoint.sh` is provided in `scripts/ping-endpoint.sh`.

```bash
# Usage:
bash scripts/ping-endpoint.sh \
  --url "https://api.example.com/health" \
  --retries 4 \
  --delay 10 \
  --connect-timeout 10 \
  --max-time 60
```
