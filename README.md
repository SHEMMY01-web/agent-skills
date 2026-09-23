# 🧠 Agent Skills

A curated repository of 23 production-grade, enterprise-ready **Agent Skills** designed for AI coding assistants and autonomous agents (including Google Antigravity, Gemini CLI, Claude Code, and Agentic IDEs).

Agent skills act as modular on-demand runbooks and domain knowledge packs. They equip agents with battle-tested architectures, best practices, security guardrails, and design systems without bloating prompt context windows.

---

## 📑 Table of Contents

- [Overview](#-overview)
- [Skills Catalog](#-skills-catalog)
  - [🎨 Frontend, Styling & UI/UX Design](#-frontend-styling--uiux-design)
  - [⚙️ Backend, Cloud Infrastructure & Resilience](#️-backend-cloud-infrastructure--resilience)
  - [🗄️ Database, Concurrency & Storage Integrity](#️-database-concurrency--storage-integrity)
  - [🤖 AI, LLM Reliability & Grounding Engines](#-ai-llm-reliability--grounding-engines)
  - [📄 Document Ingestion, AST Parsing & Document Export](#-document-ingestion-ast-parsing--document-export)
  - [🔌 IoT, Biometrics & Hardware Sockets](#-iot-biometrics--hardware-sockets)
  - [🧪 QA, Financial Precision & Chaos Testing](#-qa-financial-precision--chaos-testing)
  - [🎮 Game Architecture & Spatial Traversal](#-game-architecture--spatial-traversal)
  - [🛠️ Templates & Verification](#️-templates--verification)
- [Quick Start & Installation](#-quick-start--installation)
  - [Option 1: Using the Automated Installer (Recommended)](#option-1-using-the-automated-installer-recommended)
  - [Option 2: Direct Global Installation](#option-2-direct-global-installation)
  - [Option 3: Project-Level Installation](#option-3-project-level-installation)
- [How Agent Skills Work](#-how-agent-skills-work)
- [Creating & Contributing New Skills](#-creating--contributing-new-skills)
- [Repository Structure](#-repository-structure)

---

## 🚀 Overview

Skills use **progressive disclosure**. The agent only ingests the `name` and `description` frontmatter initially, loading the full skill instructions only when a relevant user prompt requires it. This keeps inference costs low and reasoning sharp.

```mermaid
flowchart TD
    A[User Request] --> B[Agent Evaluates Available Skill Metadata]
    B -->|Match Found| C[Load Full SKILL.md & Runbook]
    B -->|No Match| D[Standard Inference]
    C --> E[Execute Expert Multi-Step Workflow with Domain Rules]
```

---

## 📚 Skills Catalog

### 🎨 Frontend, Styling & UI/UX Design

| Skill Name | Purpose & Activation Scenarios | Location |
| :--- | :--- | :--- |
| [`frontend-design-mastery`](./skills/frontend-design-mastery/SKILL.md) | World-class frontend UI/UX design principles, responsive layout rules, typography hierarchies, and premium styling guidelines for modern web applications. | [skills/frontend-design-mastery](./skills/frontend-design-mastery/) |
| [`frontend-design`](./skills/frontend-design/SKILL.md) | Enterprise UI/UX design direction, component layout structures, visual hierarchy rules, color composition, and modern aesthetic guidelines. | [skills/frontend-design](./skills/frontend-design/) |
| [`design-taste-frontend`](./skills/design-taste-frontend/SKILL.md) | High-taste aesthetic guidelines, typography pairing, glassmorphic elevation, and visual polish rules. | [skills/design-taste-frontend](./skills/design-taste-frontend/) |
| [`react-best-practices`](./skills/react-best-practices/SKILL.md) | Production-grade React 18 component patterns, hooks optimization, lazy-loading, suspense boundaries, and DOM sanitization. | [skills/react-best-practices](./skills/react-best-practices/) |
| [`tailwind-patterns`](./skills/tailwind-patterns/SKILL.md) | Best practices for composing maintainable, responsive, high-performance Tailwind CSS utility classes and design tokens. | [skills/tailwind-patterns](./skills/tailwind-patterns/) |

### ⚙️ Backend, Cloud Infrastructure & Resilience

| Skill Name | Purpose & Activation Scenarios | Location |
| :--- | :--- | :--- |
| [`nodejs-backend-architecture`](./skills/nodejs-backend-architecture/SKILL.md) | Enterprise Node.js and Express backend architecture, asynchronous hot-path optimizations, memory leak prevention, and resilient connection pooling. | [skills/nodejs-backend-architecture](./skills/nodejs-backend-architecture/) |
| [`cloud-keepalive-resilience`](./skills/cloud-keepalive-resilience/SKILL.md) | Enterprise-grade keep-alive, database warming, and cold-start absorption patterns for free-tier and serverless cloud services (Render, Supabase, Fly.io, Vercel, Railway, Neon). Includes automated cron workflows and ping scripts. | [skills/cloud-keepalive-resilience](./skills/cloud-keepalive-resilience/) |
| [`security-audit-hardening`](./skills/security-audit-hardening/SKILL.md) | Enterprise application security hardening, Content Security Policy (CSP), magic-byte file signature validation, rate limiting, and zero-trust sanitization. | [skills/security-audit-hardening](./skills/security-audit-hardening/) |
| [`pwa-offline-resilience`](./skills/pwa-offline-resilience/SKILL.md) | Progressive Web App (PWA) service worker caching architecture, multi-tier cache partitioning, mutation bypass safety, network timeout race wrappers, and offline synchronization. | [skills/pwa-offline-resilience](./skills/pwa-offline-resilience/) |
| [`spa-deployment-cache-resilience`](./skills/spa-deployment-cache-resilience/SKILL.md) | Single Page Application (SPA) deployment cache resilience, dynamic chunk preload failure recovery, Service Worker HTML cache-poisoning prevention, and negative-lookahead SPA routing for Vite, React Router, Vercel, and PWA environments. | [skills/spa-deployment-cache-resilience](./skills/spa-deployment-cache-resilience/) |

### 🗄️ Database, Concurrency & Storage Integrity

| Skill Name | Purpose & Activation Scenarios | Location |
| :--- | :--- | :--- |
| [`database-concurrency-atomic-rpc`](./skills/database-concurrency-atomic-rpc/SKILL.md) | PostgreSQL and Supabase concurrency control, atomic stored procedures (RPCs), row-level locks (`SELECT FOR UPDATE`), transaction rollbacks, race condition mitigation for stock/balance mutations, and formula injection sanitization. | [skills/database-concurrency-atomic-rpc](./skills/database-concurrency-atomic-rpc/) |
| [`supabase-postgresql-mastery`](./skills/supabase-postgresql-mastery/SKILL.md) | Production-grade Supabase and PostgreSQL architecture, connection pool resilience, Row Level Security (RLS) enforcement, idempotent upserts, resilient table fallbacks, and real-time subscription lifecycle management. | [skills/supabase-postgresql-mastery](./skills/supabase-postgresql-mastery/) |

### 🤖 AI, LLM Reliability & Grounding Engines

| Skill Name | Purpose & Activation Scenarios | Location |
| :--- | :--- | :--- |
| [`llm-advocate-critic-pipeline`](./skills/llm-advocate-critic-pipeline/SKILL.md) | Multi-agent and dual-pass LLM validation architecture, statutory/precedent grounding, adversarial critic verification, prompt leakage sanitization, and mitigating carve-out detection. | [skills/llm-advocate-critic-pipeline](./skills/llm-advocate-critic-pipeline/) |
| [`llm-agentic-reliability`](./skills/llm-agentic-reliability/SKILL.md) | Production LLM integration reliability, graceful credential degradation, concurrency pacing, strict JSON schema recovery, and prompt injection defense. | [skills/llm-agentic-reliability](./skills/llm-agentic-reliability/) |
| [`rag-system-architect`](./skills/rag-system-architect/SKILL.md) | Hybrid retrieval-augmented generation (RAG), dense vector similarity search, Reciprocal Rank Fusion (RRF), chunking strategies, and SHA-256 embedding cache patterns. | [skills/rag-system-architect](./skills/rag-system-architect/) |

### 📄 Document Ingestion, AST Parsing & Document Export

| Skill Name | Purpose & Activation Scenarios | Location |
| :--- | :--- | :--- |
| [`document-ast-extraction`](./skills/document-ast-extraction/SKILL.md) | Multi-format document parsing (PDF, DOCX, TXT, OCR), legal/structured AST outline segmentation, delimiter lookahead architectures, parent-clause fragment collapsing, and prompt injection sanitization. | [skills/document-ast-extraction](./skills/document-ast-extraction/) |
| [`enterprise-document-export`](./skills/enterprise-document-export/SKILL.md) | Programmatic enterprise document generation for Microsoft Word (`.docx` via `docx.js`) and PDF (via ReportLab / Platypus), covering XML hex rules, cell padding/borders, callouts, and 2-pass numbered canvas paging. | [skills/enterprise-document-export](./skills/enterprise-document-export/) |

### 🔌 IoT, Biometrics & Hardware Sockets

| Skill Name | Purpose & Activation Scenarios | Location |
| :--- | :--- | :--- |
| [`iot-hardware-bridge-architecture`](./skills/iot-hardware-bridge-architecture/SKILL.md) | IoT hardware networking, biometric attendance device protocols (Realand, ZKTeco, FK protocols), UDP/TCP socket bridging, immediate ACK patterns, and buffered cloud synchronization. | [skills/iot-hardware-bridge-architecture](./skills/iot-hardware-bridge-architecture/) |
| [`hardware-protocol-bridge`](./skills/hardware-protocol-bridge/SKILL.md) | Hardware IoT protocol bridging, binary UDP/TCP packet parsing, datagram socket lifecycle, CRC checksum validation, and device-to-cloud relay pipelines in Node.js. | [skills/hardware-protocol-bridge](./skills/hardware-protocol-bridge/) |

### 🧪 QA, Financial Precision & Chaos Testing

| Skill Name | Purpose & Activation Scenarios | Location |
| :--- | :--- | :--- |
| [`automated-testing-patterns`](./skills/automated-testing-patterns/SKILL.md) | Enterprise QA test harness engineering, chaos testing, load simulation, financial precision assertion, and regression suite architecture. | [skills/automated-testing-patterns](./skills/automated-testing-patterns/) |
| [`financial-precision-engine`](./skills/financial-precision-engine/SKILL.md) | Deterministic financial precision, zero-drift floating-point arithmetic, compound interest simulation stability, defensive boundary guards against division-by-zero/NaN, and monotonic risk scoring. | [skills/financial-precision-engine](./skills/financial-precision-engine/) |

### 🎮 Game Architecture & Spatial Traversal

| Skill Name | Purpose & Activation Scenarios | Location |
| :--- | :--- | :--- |
| [`platformer-level-design`](./skills/platformer-level-design/SKILL.md) | Master 2D/2.5D platformer level design architecture based on Kishōtenketsu, GMTK, Celeste, and Mario spatial traversal loops. | [skills/platformer-level-design](./skills/platformer-level-design/) |

### 🛠️ Templates & Verification

| Skill Name | Purpose & Activation Scenarios | Location |
| :--- | :--- | :--- |
| [`_template`](./skills/_template/SKILL.md) | Starter blueprint for authoring new agent skills with standardized YAML frontmatter and validation sections. | [skills/_template](./skills/_template/) |
| [`test-skill`](./skills/test-skill/SKILL.md) | Lightweight skill for verifying global and project-level skill discovery. | [skills/test-skill](./skills/test-skill/) |

---

## ⚡ Quick Start & Installation

Clone this repository:

```bash
git clone https://github.com/SHEMMY01-web/agent-skills.git
cd agent-skills
```

### Option 1: Using the Automated Installer (Recommended)

The included `install.sh` script automates installation across global and workspace configurations:

```bash
# 1. Inspect all available skills with full descriptions
./install.sh --list

# 2. Install all skills globally for all agent sessions
./install.sh --global

# 3. Or create live symlinks (updates in this repo immediately reflect globally)
./install.sh --link-global

# 4. Or install skills into a specific project workspace
./install.sh --project /path/to/your/project
```

### Option 2: Direct Global Installation

To make these skills available across **every project** on your machine:

```bash
mkdir -p ~/.gemini/config/skills
cp -r skills/* ~/.gemini/config/skills/
```

### Option 3: Project-Level Installation

To equip a specific repository or project:

```bash
mkdir -p /path/to/your/project/.agents/skills
cp -r skills/* /path/to/your/project/.agents/skills/
```

---

## 🧩 How Agent Skills Work

Every skill directory adheres to the standard Agent Customization schema:

```text
skills/<skill-name>/
├── SKILL.md          # Required: Instructions with YAML frontmatter
├── scripts/          # Optional: Helper utilities and automated scripts
├── examples/         # Optional: Reference implementations and code samples
└── references/       # Optional: In-depth documentation and whitepapers
```

### The `SKILL.md` Specification
Every `SKILL.md` requires YAML frontmatter specifying:
- `name`: Lowercase, hyphenated unique skill identifier.
- `description`: Explicit guidance stating **what** the skill achieves and **under what exact conditions** the agent should activate it.

Example:
```yaml
---
name: security-audit-hardening
description: >-
  Enterprise application security hardening, Content Security Policy (CSP),
  magic-byte file validation, rate limiting, and zero-trust data sanitization.
---
```

---

## 📂 Repository Structure

```text
agent-skills/
├── .agents/
│   └── skills -> ../skills            # Workspace symlink for instant IDE discovery
├── skills/                            # Canonical skill definitions (22 production skills)
│   ├── automated-testing-patterns/
│   ├── cloud-keepalive-resilience/
│   ├── database-concurrency-atomic-rpc/
│   ├── design-taste-frontend/
│   ├── document-ast-extraction/
│   ├── enterprise-document-export/
│   ├── financial-precision-engine/
│   ├── frontend-design/
│   ├── frontend-design-mastery/
│   ├── hardware-protocol-bridge/
│   ├── iot-hardware-bridge-architecture/
│   ├── llm-advocate-critic-pipeline/
│   ├── llm-agentic-reliability/
│   ├── nodejs-backend-architecture/
│   ├── platformer-level-design/
│   ├── pwa-offline-resilience/
│   ├── rag-system-architect/
│   ├── react-best-practices/
│   ├── security-audit-hardening/
│   ├── supabase-postgresql-mastery/
│   ├── tailwind-patterns/
│   ├── test-skill/
│   └── _template/
├── install.sh                         # One-click installation & linking utility
├── LICENSE                            # MIT License
└── README.md                          # Documentation catalog
```

---

## 📄 License

MIT © [SEMILORE](https://github.com/SHEMMY01-web)
