---
name: llm-agentic-reliability
description: >-
  Production LLM integration reliability, graceful credential degradation, dual-pass
  advocate-critic synthesis, concurrency pacing, strict JSON schema recovery, and
  prompt injection defense. Use when building, debugging, or hardening LLM-powered
  agent workflows, Gemini APIs, or multi-turn extraction pipelines.
---

# LLM Agentic Reliability & Fault Tolerance

Architectural patterns and defensive guidelines for building resilient, production-grade LLM applications and agent pipelines that survive API outages, quota rate limits, credential gaps, and malformed outputs.

---

## 1. When to Use
- Implementing multi-stage agent workflows, extraction pipelines, or document analysis engines.
- Integrating LLM APIs (Google Gemini, Anthropic, OpenAI) with strict uptime and fallback guarantees.
- Preventing application crashes when cloud credentials or API keys expire or fail.
- Implementing paced batch processing to eliminate HTTP 429 (Rate Limit / Quota Exceeded) errors.
- Designing dual-pass critique systems (e.g. advocate-critic or generator-evaluator).
- Parsing and repairing malformed, fenced, or truncated JSON responses from generative models.

---

## 2. Core Guidelines & Best Practices

### 1. Graceful Credential & Offline Degradation
- **Never crash the process on missing API keys:** If cloud credentials (e.g., Google ADC, API keys) fail, switch to deterministic heuristic fallback mode:
  ```javascript
  let geminiDegraded = false;
  try {
    const response = await callGenerativeModel(prompt);
    return parseResult(response);
  } catch (err) {
    if (err.message.includes('Could not load the default credentials') || err.status === 401) {
      console.warn('[LLM] Cloud credentials unavailable. Entering deterministic degradation mode.');
      geminiDegraded = true;
      return runDeterministicRuleFallback(inputPayload, { geminiDegraded: true });
    }
    throw err;
  }
  ```
- Always flag degraded states in response payloads (`{ success: true, geminiDegraded: true }`) so client UIs can notify users transparently while retaining full core functionality.

### 2. Two-Pass Advocate-Critic Synthesis
- Single-pass LLM prompts often hallucinate false severity or miss mitigating carve-outs.
- **Pass 1 (Advocate / Extractor):** Focuses solely on finding all potential vulnerabilities, aggressive clauses, or contractual risks.
- **Pass 2 (Critic / Evaluator):** Reviews the findings against the full document context to check for mitigating carve-outs (e.g. audit exceptions, cure periods), adjusts severity down where justified, and normalizes risk scores.

### 3. Concurrency Pacing & Jittered Backoff
- Bursting 50 chunks concurrently into LLM endpoints triggers instantaneous 429s.
- Process chunks in controlled batches (e.g., concurrency: 3) with inter-batch pacing (e.g., 200-500ms delay) and exponential backoff:
  ```javascript
  async function processBatchWithPacing(items, batchSize = 3, pacingDelayMs = 300) {
    const results = [];
    for (let i = 0; i < items.length; i += batchSize) {
      const batch = items.slice(i, i + batchSize);
      const batchResults = await Promise.all(batch.map(item => processSingleWithRetry(item)));
      results.push(...batchResults);
      if (i + batchSize < items.length) {
        await new Promise(r => setTimeout(r, pacingDelayMs));
      }
    }
    return results;
  }
  ```

### 4. Robust JSON Extraction & Fence Stripping
- LLMs frequently wrap JSON in markdown blocks (` ```json ... ``` `) or append conversational commentary.
- Implement robust fence stripping and trailing bracket/comma recovery:
  ```javascript
  function extractCleanJson(rawText) {
    if (!rawText) return null;
    let cleaned = rawText.trim();
    // Strip markdown code fences
    cleaned = cleaned.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/i, '').trim();

    try {
      return JSON.parse(cleaned);
    } catch {
      // Regex recovery of inner JSON object or array
      const match = cleaned.match(/(\{[\s\S]*\}|\[[\s\S]*\])/);
      if (match) {
        try {
          return JSON.parse(match[0]);
        } catch {}
      }
      throw new Error(`Failed to parse LLM structured output: ${cleaned.substring(0, 100)}...`);
    }
  }
  ```

### 5. Mitigating Carve-Out Severity Normalization
- When a critic detects mitigating clauses (e.g., "right to inspect premises subject to 48h prior written notice"), normalize severity to canonical levels (`LOW`, `MEDIUM`, `HIGH`) instead of custom composite strings like `LOW_RISK_WITH_CARVEOUT` that break frontend filter badges.

---

## 3. Recommended Workflow & Procedures

1. **Input Normalization & Token Budgeting:** Validate inputs, compute character/token metrics, and reject requests exceeding safety thresholds.
2. **Context Enrichment (RAG):** Query knowledge base for legal precedents or reference standards, attaching citation metadata directly to chunk objects.
3. **Execution with Pacing:** Invoke model with structured response schemas (`responseMimeType: 'application/json'`).
4. **Critic & Sanity Validation:** Inspect output schemas with Zod/Joi, enforce severity bounds, and strip accidental prompt leaks.
5. **Telemetry & Latency Logging:** Record model response latencies, token counts, and degradation flags in request telemetry.

---

## 4. Verification & Validation
- **Credential Failure Test:** Unset API credentials in a test runner and execute the pipeline. Assert execution succeeds with `geminiDegraded: true` and returns deterministic fallback cards.
- **Malformed JSON Injection:** Mock LLM returning markdown-fenced and partially unescaped JSON. Assert parser recovers clean object without throwing unhandled exceptions.
- **Rate Limit Resilience:** Simulate 429 status code on attempt 1. Assert retry handler catches, backs off, and succeeds on attempt 2.
