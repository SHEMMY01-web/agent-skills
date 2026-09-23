---
name: llm-advocate-critic-pipeline
description: >-
  Multi-agent and dual-pass LLM validation architecture, statutory/precedent grounding,
  adversarial critic verification, prompt leakage sanitization, and fallback degradation
  distilled from ClearSight legal intelligence. Use when designing, implementing, or auditing
  high-stakes generative AI pipelines, contract/document risk analyzers, and decision engines.
---

# LLM Advocate-Critic Pipeline & Grounding Architecture

A production-grade pattern for mission-critical AI reasoning engines where hallucinations, ungrounded assertions, or bias carry legal, financial, or operational consequences.

---

## 1. When to Activate This Skill
- Building multi-pass LLM pipelines (Advocate -> Critic -> Synthesizer).
- Implementing statutory, factual, or regulatory citation validation over RAG hits.
- Preventing system prompt leakage and instruction injection in user-facing LLM outputs.
- Designing deterministic fallback matrices when LLM APIs time out, throttle (HTTP 429), or fail.
- Adding statistical or empirical historical outcomes alongside generative interpretations.

---

## 2. Core Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ 1. INGESTION & CONTEXT NORMALIZATION                       │
│ - Strip preamble markers & normalize clause hierarchies     │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. ADVOCATE PASS (Primary Generation)                       │
│ - Generates analysis, opportunity detection, or risk flags │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. CRITIC PASS (Adversarial Verification)                   │
│ - Audits citations against statutory database               │
│ - Tests for hallucinated sections, overreach, or bias       │
│ - Demotes severity if valid mitigating carve-outs exist     │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. SANITIZATION & STRUCTURED SYNTHESIS                      │
│ - Filter prompt preambles and system instruction artifacts  │
│ - Attach empirical win-rate stats & actionable counter-draft│
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Key Implementation Guidelines

### 3.1 Server-Side Prompt Leakage & Preamble Sanitization
Never return raw LLM outputs directly to clients without strict regex and token filtering:

```javascript
const SYSTEM_PREAMBLE_MARKERS = [
  '<SYSTEM_INSTRUCTION>',
  '</SYSTEM_INSTRUCTION>',
  '<CONTRACT_DOCUMENT>',
  '</CONTRACT_DOCUMENT>',
  'You are an expert AI',
  'system instructions:',
  'plain english legal assistant:'
];

export function sanitizeUserFacingText(text) {
  if (!text || typeof text !== 'string') return '';
  let cleaned = text;

  // Filter out any leaked prompt preamble lines
  for (const marker of SYSTEM_PREAMBLE_MARKERS) {
    if (cleaned.includes(marker)) {
      cleaned = cleaned.split('\n')
        .filter(line => !SYSTEM_PREAMBLE_MARKERS.some(m => line.includes(m)))
        .join('\n');
    }
  }

  // Strip tag wrappers and meta-preambles
  cleaned = cleaned
    .replace(/<SYSTEM_INSTRUCTION>[\s\S]*?<\/SYSTEM_INSTRUCTION>/gi, '')
    .replace(/<CONTRACT_DOCUMENT>[\s\S]*?<\/CONTRACT_DOCUMENT>/gi, '')
    .replace(/^system instructions:?\s*/i, '')
    .replace(/^plain english legal assistant:?\s*/i, '');

  return cleaned.trim();
}
```

---

### 3.2 Statutory Citation & Sentence Validation
RAG vector search hits frequently return headers, fragments, or table of contents lines. Validate candidate citations before grounding the Critic:

```javascript
export function isValidPrecedentSentence(sentence) {
  if (!sentence || typeof sentence !== 'string') return false;
  const s = sentence.trim();

  // Reject tiny fragments or naked section headers
  if (s.length < 30) return false;
  if (/^(section|article|clause|paragraph|\d+\.|\([a-z0-9]+\))\s*$/i.test(s)) return false;

  const wordCount = s.split(/\s+/).length;
  if (wordCount < 5) return false;

  return true;
}
```

---

### 3.3 Mitigating Carve-Out & Severity Demotion Engine
High-severity warnings often panic users when a contract actually contains mitigating language elsewhere. The Critic must inspect parent clause context for carve-out patterns:

```javascript
const CARVE_OUT_PATTERNS = [
  {
    category: 'ip_assignment',
    patterns: [
      /(?:save|except|excluding|other than|with the exception of)\s+[^.\n]{0,100}?(?:pre-existing|background|prior|standard)\s+(?:ip|code|software|libraries)/i,
      /(?:creator|author|vendor)\s+(?:shall retain|retains)\s+[^.\n]{0,100}?(?:pre-existing|background|generic)\s+(?:ip|materials|tools)/i
    ],
    summary: 'Pre-existing background IP and standard tools are explicitly carved out and retained.',
    adjustedSeverity: 'MEDIUM'
  },
  {
    category: 'indemnity_cap',
    patterns: [
      /(?:aggregate|total)\s+liability\s+(?:shall not exceed|is capped at|limited to)\s+(?:the\s+)?(?:fees paid|total contract value|\d+x)/i
    ],
    summary: 'Liability exposure is constrained by an express financial liability cap.',
    adjustedSeverity: 'MEDIUM'
  },
  {
    category: 'cure_period',
    patterns: [
      /(?:provided|subject to)\s+(?:the\s+)?(?:breach|default)\s+is not cured within\s+(\d+)\s*(?:days|business days)/i,
      /(?:upon giving|with)\s+(\d+)\s*(?:days|business days)\s+prior written notice/i
    ],
    summary: 'A mandatory written notice-to-cure grace period prevents immediate unilateral termination.',
    adjustedSeverity: 'MEDIUM'
  }
];

export function detectCarveOuts(clauseText) {
  const matches = [];
  for (const carveOut of CARVE_OUT_PATTERNS) {
    for (const pattern of carveOut.patterns) {
      if (pattern.test(clauseText)) {
        matches.push(carveOut);
        break;
      }
    }
  }
  return matches;
}
```

---

### 3.4 Resilient Multi-Tier Fallback Degradation
Never fail a client request completely when LLM services encounter timeouts or rate limits. Build a fallback matrix with pre-baked rule summaries:

```javascript
export async function generateWithFallback(taskFn, fallbackData, logContext = 'LLM Task') {
  try {
    const result = await taskFn();
    if (result && typeof result === 'string' && result.trim().length > 0) {
      return { text: sanitizeUserFacingText(result), usedFallback: false };
    }
    throw new Error('Empty generation response');
  } catch (err) {
    console.warn(`[${logContext}] LLM failed (${err.message}). Degrading gracefully to static rule fallback.`);
    return {
      text: fallbackData.text || 'Rule-based analysis applied.',
      usedFallback: true
    };
  }
}
```

---

## 4. Verification & Testing Checklist
- [ ] Ensure prompt templates wrap user input in distinct XML tags (`<INPUT_DOCUMENT>...</INPUT_DOCUMENT>`).
- [ ] Verify that server-side sanitizers eliminate raw system tags before sending to the client.
- [ ] Run edge-case tests with fragmented RAG snippets to confirm `isValidPrecedentSentence` rejects non-substantive text.
- [ ] Test network failure and verify the fallback returns clean, well-formatted rule defaults without crashing the UI.
