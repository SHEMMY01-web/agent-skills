/**
 * Production-Grade Database & Cloud Keep-Alive Background Service
 * Absorbs cold starts via retry loops and prevents process hangs with unref timers.
 */

const keepAliveState = {
  isRunning: false,
  intervalMs: 14 * 60 * 1000,
  totalPings: 0,
  failedPings: 0,
  lastPingTime: null,
  lastLatencyMs: null,
  lastStatus: 'uninitialized',
  lastError: null,
  history: []
};

let keepAliveInterval = null;
let initialTimeout = null;

/**
 * Ping database probe with multi-attempt retry loop and backoff
 * @param {Object} client - Database or ORM client instance (e.g. Supabase, Prisma, Pool)
 * @param {Object} options - Configuration overrides
 */
async function pingDatabase(client, options = {}) {
  const maxRetries = options.maxRetries ?? (process.env.NODE_ENV === 'test' ? 1 : 3);
  const retryDelayMs = options.retryDelayMs ?? (process.env.NODE_ENV === 'test' ? 10 : 1500);

  const startTime = Date.now();
  keepAliveState.totalPings++;

  let lastError = null;
  let lastData = null;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      // 1. Primary probe: Lightweight indexed query
      let { data, error } = await client
        .from('items')
        .select('id')
        .limit(1);

      if (!error) {
        const latencyMs = Date.now() - startTime;
        const timestamp = new Date().toISOString();

        keepAliveState.lastStatus = 'healthy';
        keepAliveState.lastError = null;
        keepAliveState.lastPingTime = timestamp;
        keepAliveState.lastLatencyMs = latencyMs;

        recordHistory({ success: true, latencyMs, timestamp, attempts: attempt });
        console.log(`[Keep-Alive] ✅ Database ping successful (${latencyMs}ms, attempt ${attempt}/${maxRetries})`);

        return { success: true, latencyMs, timestamp, attempts: attempt, rows: data?.length || 0 };
      }

      lastError = error;
    } catch (err) {
      lastError = err;
    }

    if (attempt < maxRetries) {
      console.warn(`[Keep-Alive] ⚠️ Ping attempt ${attempt}/${maxRetries} failed: ${lastError.message}. Retrying in ${retryDelayMs}ms...`);
      await new Promise(resolve => setTimeout(resolve, retryDelayMs));
    }
  }

  // All retries failed
  const latencyMs = Date.now() - startTime;
  const timestamp = new Date().toISOString();
  const errorMessage = lastError ? lastError.message : 'Unknown database ping error';

  keepAliveState.failedPings++;
  keepAliveState.lastStatus = 'error';
  keepAliveState.lastError = errorMessage;
  keepAliveState.lastPingTime = timestamp;
  keepAliveState.lastLatencyMs = latencyMs;

  recordHistory({ success: false, latencyMs, timestamp, error: errorMessage, attempts: maxRetries });
  console.error(`[Keep-Alive] ❌ Database ping failed after ${maxRetries} attempts (${latencyMs}ms):`, errorMessage);

  return { success: false, error: errorMessage, latencyMs, timestamp, attempts: maxRetries };
}

function recordHistory(entry) {
  keepAliveState.history.unshift(entry);
  if (keepAliveState.history.length > 20) {
    keepAliveState.history.pop();
  }
}

/**
 * Starts periodic keep-alive background worker with unref timers
 */
function startDatabaseKeepAlive(client, intervalMs = 14 * 60 * 1000) {
  if (keepAliveInterval) return;

  keepAliveState.isRunning = true;
  keepAliveState.intervalMs = intervalMs;

  // Initial delayed ping to let process cold-start settle
  initialTimeout = setTimeout(() => {
    pingDatabase(client).catch(() => {});
  }, 10000);
  if (initialTimeout.unref) initialTimeout.unref();

  keepAliveInterval = setInterval(() => {
    pingDatabase(client).catch(() => {});
  }, intervalMs);
  if (keepAliveInterval.unref) keepAliveInterval.unref();
}

/**
 * Stops worker and cleans up timers
 */
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

module.exports = {
  pingDatabase,
  startDatabaseKeepAlive,
  stopDatabaseKeepAlive,
  getKeepAliveStats: () => ({ ...keepAliveState, uptimeSeconds: Math.floor(process.uptime()) })
};
