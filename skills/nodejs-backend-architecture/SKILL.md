---
name: nodejs-backend-architecture
description: Enterprise Node.js and Express backend architecture, asynchronous hot-path optimizations, memory leak prevention, and connection pooling from agentic-awesome-skills.
---

# Node.js Backend Architecture (Agentic Awesome Skills)

## Core Guidelines
1. **Asynchronous Non-Blocking Hot Paths:** Never block the event loop with synchronous CPU-heavy parsing or blocking file I/O.
2. **Resilient Connection Pooling:** Always wrap database and vector service connections with timeout guards (e.g. `AbortSignal.timeout(10000)`).
3. **Graceful Degradation & Circuit Breaking:** Implement jittered exponential backoffs on downstream API calls (HTTP 429/503 handlers).
4. **Structured Logging & Telemetry:** Use out-of-band buffered streams (e.g. Redis Streams or ring buffers) to log telemetry without impacting request response times.
