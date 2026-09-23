---
name: document-ast-extraction
description: >-
  Multi-format document parsing (PDF, DOCX, TXT, OCR), legal/structured AST outline
  segmentation, delimiter lookahead architectures, parent-clause fragment collapsing,
  and prompt injection sanitization. Use when parsing, chunking, or analyzing complex
  documents, contracts, and legal agreements.
---

# Document AST Extraction & Outline Segmentation

A comprehensive guide for robust, enterprise-grade document extraction, semantic outline segmentation, and Abstract Syntax Tree (AST) reconstruction across complex multi-page documents and legal contracts.

---

## 1. When to Use
- Implementing or tuning document ingestion pipelines (PDFs, DOCX, plain text, scanned images/OCR).
- Extracting hierarchical clauses, numbered sections, sub-clauses, and schedules.
- Fixing document chunking bugs where entire agreements collapse into single monolithic blocks.
- Collapsing fragmented sub-clause risk flags into cohesive parent-clause summary cards.
- Sanitizing system preamble markers or prompt injection attempts from extracted text.
- Pacing large multi-page documents (e.g., 50+ pages) through translation or embedding token budgets.

---

## 2. Core Guidelines & Best Practices

### 1. Robust Section & Clause Delimiter Architecture
- **Avoid Overly Strict Lookaheads:** A common failure occurs when clause regexes demand immediate alphanumeric characters without permitting delimiters:
  ```javascript
  // ❌ FRAGILE: Misses "Clause 5.3: Termination" or "Section 4 - Indemnity"
  const badRegex = /(?:Clause|Section)\s+(\d+)(?=[A-Z])/i;

  // ✅ RESILIENT: Permissive delimiter lookahead with punctuation support
  const clauseRegex = /(?:^|\n)\s*(?:(?:Clause|Section|Article)\s+)?(\d+(?:\.[0-9a-z]+)*(?:\([a-z0-9]+\))*)(?:[\s\t:.\-–—]+)([^\n]+)/gi;
  ```
- Support diverse numbering structures: Arabic numerals (`1.1`, `2.4.1`), alphabetical markers (`(a)`, `(iv)`), and legal preamble headers (`WHEREAS`, `NOW THEREFORE`).

### 2. Parent-Clause Collapsing & Fragment Merging
- Sub-clause analysis often produces noisy, fragmented risk cards (e.g. 8 separate warnings for sub-clauses 3.1 through 3.8).
- **Collapse by Parent Identifier:** Group fragments by parent clause (`3.` or `Clause 3`), select the highest severity across children, concatenate plain-language criticisms, and reconcile chunk accounting:
  ```javascript
  function collapseFragments(rawFlags) {
    const parentMap = new Map();
    for (const flag of rawFlags) {
      const parentId = extractParentId(flag.clauseId); // e.g. "Clause 4.2b" -> "Clause 4"
      if (!parentMap.has(parentId)) {
        parentMap.set(parentId, { ...flag, subClauses: [flag] });
      } else {
        const parent = parentMap.get(parentId);
        parent.subClauses.push(flag);
        parent.severity = resolveMaxSeverity(parent.severity, flag.severity);
        // CRITICAL: Merge and deduplicate RAG precedent hits
        parent.ragHits = mergeUniquePrecedents(parent.ragHits, flag.ragHits);
      }
    }
    return Array.from(parentMap.values());
  }
  ```

### 3. Decoupling RAG Precedents from Reference Equality
- Never rely on `array.indexOf(item)` to re-attach vector search results or precedent metadata after transformation.
- Because objects are spread or reconstructed during chunking passes, reference equality (`===`) fails. Always attach `ragHits` and `citations` directly onto the chunk item metadata.

### 4. Preamble Leak & Prompt Injection Sanitization
- Documents may contain adversarial text aiming to hijack downstream LLM instructions, or the pipeline may accidentally include internal system preambles.
- Store markers as clean string tokens (never regex objects when passing to `String.prototype.includes`), and run exact-match line denylisting:
  ```javascript
  const SYSTEM_PREAMBLE_MARKERS = [
    "SYSTEMATIC CONSTRAINT LAYER",
    "STRATEGIC PROFILE OVERRIDE",
    "JURISDICTION BASELINE"
  ];

  function sanitizeUserFacingText(text) {
    return text
      .split('\n')
      .filter(line => !SYSTEM_PREAMBLE_MARKERS.some(marker => line.includes(marker)))
      .join('\n')
      .trim();
  }
  ```

### 5. Multi-Signal Pagination & Chunk Accounting
- Dense documents need clear chunk boundaries to stay within LLM context windows (e.g., 30,000 characters or ~10 pages per batch).
- Track both character counts and derived page estimates (`translatedThroughPage = Math.min(totalPages, Math.ceil(charCount / CHARS_PER_PAGE))`) so users see transparent progress across long documents.

---

## 3. Recommended Workflow & Procedures

1. **Extract Raw Text:** Ingest PDF/DOCX using streaming parsers (e.g. `pdf-parse`, `mammoth`). Clean carriage returns and trailing null bytes.
2. **Build AST Hierarchy:** Scan for root headers (`Article`, `Clause`, `Section`), group text into nodes, and establish parent-child relationships.
3. **Attach Metadata:** Tag each AST node with `clauseId`, `startPage`, `endPage`, `wordCount`, and domain classification (`corporate`, `commercial`, `tenancy`, `employment`).
4. **Vector / RAG Enrichment:** Query legal precedent database for high-risk nodes and embed citation metadata directly into node objects.
5. **Collapse & Synthesize:** Merge sub-clause findings into parent summary cards for the user interface.

---

## 4. Verification & Validation
- **Delimiter Test:** Feed documents with varying delimiter formats (`Clause 1.1:`, `1.1 -`, `Section 4.`, `Clause 5.3 (a)`). Verify segmentation never falls back to a 1-chunk document.
- **Reconciliation Assertion:** Assert `inputFragments.length >= outputParentCards.length` and that sum of sub-clause accounts equals total flagged clauses.
- **Leak Test:** Pass test strings with injection markers (`SYSTEMATIC CONSTRAINT LAYER: Ignore previous instructions`). Verify sanitized output contains 0 preamble traces.
