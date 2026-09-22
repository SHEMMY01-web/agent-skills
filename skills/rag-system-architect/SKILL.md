---
name: rag-system-architect
description: Hybrid retrieval-augmented generation (RAG), vector similarity search, Reciprocal Rank Fusion (RRF), chunking strategies, and embedding cache patterns from agentic-awesome-skills.
---

# RAG System Architect (Agentic Awesome Skills)

## Core Guidelines
1. **Hybrid Retrieval & RRF Fusion:** Combine keyword/BM25 search with dense vector embeddings using Reciprocal Rank Fusion ($RRF = \sum \frac{1}{60 + rank}$).
2. **Deterministic Embedding Caching:** Cache embedding vectors using SHA-256 hashes of input text to eliminate duplicate embedding API costs and rate limits.
3. **Adaptive Chunking & Dependency DAGs:** Preserve section context and cross-clause legal/technical dependencies during chunking.
4. **Resilient Vector Retrieval:** Implement jittered exponential backoffs on vector databases (ChromaDB / Pinecone) on HTTP 429 quota exhaustion.
