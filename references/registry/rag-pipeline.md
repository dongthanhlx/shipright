# Registry pack — rag-pipeline

> One project-type pack. Load it together with the trigger index in `references/registry.md`,
> never the other packs. Install names, commands and the consent rule: registry.md §Install recipes.

RAG system, knowledge base, document Q&A, semantic search.

> **Exploration note:** LLM API (OpenAI/Anthropic/etc.) must be explored before writing
> LLM module. Save real responses including token usage fields, error formats,
> rate limit headers. LLM response shapes change between model versions.

```
install:
  required:
    - addyosmani/agent-skills
      skills: [incremental-implementation, test-driven-development, code-review-and-quality]
    - RAGAS: pip install ragas
      when: evaluation needed (always — eval-first policy)
  optional:
    - LangSmith OR Arize Phoenix (LLM tracing/observability)
    - NVIDIA/rag-blueprint (NVIDIA stack)
    - datadog-labs/dd-llmo-eval-bootstrap (production LLM eval)

tested-with: RAGAS 0.2+, LangChain 0.3+, LlamaIndex 0.11+
load: references/stacks/ai-projects.md — the LLM boundary (Boundary 4 for AI), THEN
      references/stacks/ai-rag.md — RAG deep dive (eval loop, chunking, vector DB, retrieval metrics)

framework-decision:
  retrieval-first: LlamaIndex
  orchestration-first: LangChain + LangGraph
  both: LlamaIndex ingestion + LangChain orchestration
  enterprise: Haystack

shipright-adds-to-CLAUDE:
  llm-boundary: "All LLM calls in llm/ module only. Never in service or handler. (Boundary 4 for AI)"
  llm-boundary-b: "Raw LLM response never leaves ResponseAdapter. Service receives typed AIResponse."
  llm-timeout: "Every LLM call has a timeout + fallback (Boundary 5). Agents also cap max iterations."
  eval-policy: "Run eval suite before merging any retrieval or prompt changes."
  cost-tracking: "Every LLM call logs: model + input_tokens + output_tokens + cost_usd + latency_ms"
  chunking-adr: "Record in ARCHITECTURE.md: chunk_size=[N], overlap=[N], strategy=[why]"
  debt-signals:
    - "TODO[faithfulness<0.8]: tune retrieval pipeline"
    - "TODO[hit-rate<0.85]: review chunking strategy"
    - "TODO[p95>5s]: add semantic caching"
  non-determinism: "Tests assert structure/constraints, never exact LLM output strings."
```
