---
name: security-audit-hardening
description: Enterprise application security hardening, Content Security Policy (CSP), magic-byte file validation, rate limiting, and zero-trust data sanitization from agentic-awesome-skills.
---

# Security Audit & Hardening (Agentic Awesome Skills)

## Core Guidelines
1. **Content Security Policy (CSP):** Enforce strict CSP directives via Helmet with explicit script, style, font, and connect origins.
2. **Magic-Byte Sniffing:** Never trust client-supplied file extensions or MIME types. Always inspect initial file byte signatures (e.g. `%PDF`, PNG magic headers).
3. **Boundary Validation:** Enforce strict runtime schema validation with Zod or Joi on all incoming API payloads before execution.
4. **Data Sanitization:** Sanitize dynamic HTML using DOMPurify and prevent SQL/NoSQL injection with parameterized queries.
