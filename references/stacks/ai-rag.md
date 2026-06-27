# Stack Reference: AI Projects — RAG Pipelines & LLM Applications

> **Navigation:** This file covers RAG/retrieval deep dive.
> For general AI project patterns → `references/stacks/ai-projects.md`
> For Telegram/Discord chatbot → `references/stacks/chatbot-platforms.md`
> For RAG chatbot → read this file AND chatbot-platforms.md

## The fundamental difference from regular projects

AI projects have one feedback loop that regular projects don't:
**Build → Evaluate → Tune → Build**

Without evaluation, you don't know if your RAG is working.
Without observability, you can't trace why an answer was wrong.
Without a testing strategy, you can't safely improve retrieval quality.

Shipright's L0→L4 tree applies — but the definition of "correct" is probabilistic,
not binary. Tests don't pass or fail cleanly. This changes everything about L2 and L3.

---

## Framework decision (ask before L0)

```
"What is the primary risk in your project?"

[A] Retrieval quality and data ingestion complexity
    → LlamaIndex (retrieval-first, batteries included, fast prototype)
    → Best for: document Q&A, knowledge bases, semantic search

[B] Workflow complexity: multi-step flows, agents, tool calling
    → LangChain + LangGraph (orchestration-first, flexible agents)
    → Best for: chatbots with tools, multi-agent systems, complex reasoning

[C] Both retrieval quality AND complex workflows
    → LlamaIndex for indexing + LangChain for orchestration (common production pattern)
    → More moving parts, but often the right architecture

[D] Enterprise production, evaluation-first, strong observability
    → Haystack (modular pipeline DAG, built-in evaluation, professional support)

[E] Optimizing for prompt quality and chain-of-thought
    → DSPy (compiles prompts, self-optimizing, research-oriented)
```

---

## AI-specific L0 constitution additions

Beyond shipright's standard CLAUDE.md template, add:

```markdown
## AI/LLM specific rules

### LLM boundary (extends Boundary Rule 4)
All LLM calls happen in one dedicated module: [llm/] or [ai/]
No LLM calls in service layer, handlers, or any other module.
Prompt templates are files, not inline strings.
LLM module returns typed domain objects, never raw LLM response strings.

### Non-determinism acknowledgment
LLM outputs are probabilistic — tests assert structure and constraints,
not exact string matches. Use:
  - JSON schema validation for structured outputs
  - Semantic similarity thresholds, not exact equality
  - Guardrails for prohibited content/phrases

### Evaluation-first development
Every RAG feature must have:
  - A question set (min 20 questions) before building
  - A baseline score before any change
  - An eval run after every significant change
  - Score must not regress > 5% on any metric

### Cost tracking
Every LLM call logs: model, input_tokens, output_tokens, latency_ms, requestId
Daily/monthly cost tracked via cost = tokens × model_price
Budget alerts at 80% of monthly limit

### Chunking decisions (record in ARCHITECTURE.md ADR)
chunk_size: [N] characters — reasoning: [why]
chunk_overlap: [N] characters — reasoning: [why]
splitting strategy: [recursive/semantic/header-based] — reasoning: [why]
```

---

## ARCHITECTURE.md additions for RAG project

```markdown
## AI Pipeline architecture

### Component diagram
```
User Query
    ↓
[Query Handler]           ← validates, logs, rate-limits
    ↓
[Retriever]               ← embeds query, searches vector DB
    ↓ top-K chunks
[Context Builder]         ← ranks, deduplicates, formats context
    ↓ formatted context
[LLM Module]              ← prompt assembly + LLM call
    ↓ raw response
[Response Adapter]        ← parse, validate, normalize to domain type
    ↓ typed AIResponse
[Response Handler]        ← format for API/UI, add citations
```

### Data pipeline (ingestion)
```
[Source Connector]        ← load documents (PDF, URL, DB, etc.)
    ↓ raw documents
[Chunker]                 ← split with overlap, add metadata
    ↓ chunks with metadata
[Embedder]                ← embed chunks (batched)
    ↓ vectors
[Vector Store]            ← upsert with deduplication
```

### Module boundaries (AI-specific)
- Retriever NEVER calls LLM directly
- LLM Module NEVER queries vector store directly
- Response Adapter NEVER calls external services
- Source Connector NEVER knows about vector store schema

### Vector store decision
| Concern | Choice | Reason |
|---|---|---|
| Development / local | Chroma | Zero setup, file-based, easy to reset |
| Production small-medium | pgvector | Already on PostgreSQL, no extra infra |
| Production large-scale | Pinecone / Weaviate | Managed, hybrid search |

### Embedding model decision
| Concern | Choice |
|---|---|
| Development | text-embedding-3-small (OpenAI) |
| Production cost-optimized | text-embedding-3-small |
| Production quality-optimized | text-embedding-3-large |
| Self-hosted / private | nomic-embed-text (via Ollama) |

Note: Embedding model is FROZEN after first index build.
Changing model requires full re-index. Record in ADR.

### ADR-001: Chunking strategy
Decision: RecursiveCharacterTextSplitter, chunk_size=800, overlap=100
Reasoning: 400-800 tokens is sweet spot — enough context, specific enough to be relevant
Rejected: Fixed-size splitting (loses semantic boundaries)
Rejected: Semantic chunking (slower, overkill for first version)
Trigger to revisit: retrieval precision < 0.7 after tuning
```

---

## L1 skeleton prompt (RAG)

```
Read CLAUDE.md and ARCHITECTURE.md.

Create RAG project skeleton:

Directory structure:
  src/
    ingestion/
      connector.py (or .ts)   ← load documents from source
      chunker.py              ← split + add metadata
      embedder.py             ← embed chunks (batched, rate-limited)
      pipeline.py             ← orchestrate ingestion end-to-end
    retrieval/
      retriever.py            ← query vector DB, return top-K chunks
      context_builder.py     ← rank, deduplicate, format context
    llm/
      client.py               ← LLM API wrapper with retry + cost logging
      prompt_templates/       ← prompt template files (not inline strings)
      response_adapter.py    ← parse + validate LLM response → typed object
    api/ (if HTTP API)
      handlers.py             ← HTTP handlers, validation, rate limiting
    evaluation/
      eval_runner.py          ← run question set against pipeline
      metrics.py              ← precision, recall, faithfulness, latency
  tests/
    fixtures/
      questions.json          ← 20+ test questions with expected answers
      sample_chunks.json      ← pre-indexed test chunks
    unit/                     ← test each component in isolation
    eval/                     ← evaluation tests (slow, run separately)
  prompts/
    rag_system.txt            ← system prompt
    rag_user.txt              ← user prompt template
  scripts/
    ingest.py                 ← run ingestion pipeline
    evaluate.py               ← run evaluation suite

Config:
  LLM_MODEL, EMBEDDING_MODEL, VECTOR_DB_URL
  CHUNK_SIZE, CHUNK_OVERLAP (from ARCHITECTURE.md)
  MAX_RETRIEVED_CHUNKS (default: 5)
  MONTHLY_TOKEN_BUDGET (alert at 80%)

Gate: python scripts/ingest.py --sample 10 completes without error
      python scripts/evaluate.py outputs scores (not that scores are good)
```

---

## The AI evaluation loop — L2 equivalent

Regular L2: write tests (RED) → implement → GREEN.
AI L2: write question set → establish baseline → implement → compare to baseline.

### Minimum question set — this IS your test suite

> **Kent Beck applied to AI:** The question set is your RED test.
> Write 20+ questions BEFORE building the retrieval pipeline.
> Questions that fail to be answered = RED.
> After building retrieval: answers are GREEN.
> This is TDD for probabilistic systems.

### Minimum question set (create BEFORE building)

```python
# tests/fixtures/questions.json
[
  {
    "id": "q001",
    "question": "What is the refund policy?",
    "expected_answer_contains": ["30 days", "receipt"],
    "source_doc": "policies/refund.pdf",
    "difficulty": "easy"
  },
  {
    "id": "q002",
    "question": "How do I configure SSO with Okta?",
    "expected_answer_contains": ["SAML", "metadata URL"],
    "source_doc": "docs/sso-setup.md",
    "difficulty": "hard"
  }
  // Minimum 20 questions covering:
  // - easy factual (exact answer in one chunk)
  // - medium (answer spans multiple chunks)
  // - hard (requires reasoning across documents)
  // - adversarial (question not answerable from docs — should say "I don't know")
]
```

### Metrics to track (add to ARCHITECTURE.md)

```
Retrieval metrics (vector search quality):
  - Hit Rate: % of questions where correct chunk is in top-K results
  - MRR: Mean Reciprocal Rank (position of correct chunk)
  - Target: Hit Rate > 0.85, MRR > 0.7

Generation metrics (answer quality):
  - Faithfulness: answer grounded in retrieved context (0-1)
  - Answer Relevance: answer addresses the question (0-1)
  - Context Precision: retrieved chunks actually relevant (0-1)
  - Target: Faithfulness > 0.8, Answer Relevance > 0.75

Operational metrics (production health):
  - Latency p50/p95 (target: p95 < 5s for RAG)
  - Cost per query (track daily)
  - Fallback rate (% of times RAG falls back to "I don't know")
```

### Eval runner

```python
# evaluation/eval_runner.py
async def run_eval(pipeline: RAGPipeline, questions: list[Question]) -> EvalReport:
    results = []
    for q in questions:
        chunks = await pipeline.retrieve(q.question)
        answer = await pipeline.generate(q.question, chunks)
        results.append({
            "question_id": q.id,
            "hit_rate": q.id in [c.source for c in chunks],
            "answer": answer.text,
            "contains_expected": all(e in answer.text for e in q.expected_answer_contains),
            "faithfulness": await score_faithfulness(answer.text, chunks),
            "latency_ms": answer.latency_ms,
            "tokens_used": answer.tokens_used,
            "cost_usd": calculate_cost(answer.tokens_used, LLM_MODEL)
        })
    return EvalReport(results)

# Run BEFORE and AFTER every significant change
# Never ship if scores regress > 5% vs baseline
```

---

## Testing strategy (AI-specific)

### Layer 1 — Unit tests (no LLM calls, no vector DB)

```python
# Test each component in isolation with fixtures
def test_chunker_preserves_metadata():
    doc = Document(content="...", metadata={"source": "policy.pdf"})
    chunks = chunker.split(doc)
    assert all(c.metadata["source"] == "policy.pdf" for c in chunks)
    assert all(len(c.content) <= CHUNK_SIZE + CHUNK_OVERLAP for c in chunks)

def test_response_adapter_parses_json():
    raw = '{"answer": "30 days", "confidence": 0.9}'
    result = response_adapter.parse(raw)
    assert isinstance(result, AIResponse)
    assert result.answer == "30 days"
    assert 0 <= result.confidence <= 1

def test_response_adapter_handles_malformed():
    # LLM sometimes returns invalid JSON — must not crash
    result = response_adapter.parse("Sorry, I don't know.")
    assert result.answer is not None  # graceful degradation
```

### Layer 2 — Integration tests (real LLM, recorded fixtures)

```python
# Use VCR.py or similar to record/replay LLM API calls
# First run: calls real API + records response
# Subsequent runs: replays recorded response (fast, no cost)
@pytest.mark.vcr  # records/replays HTTP calls
def test_retrieval_pipeline_finds_relevant_chunk():
    chunks = retriever.search("What is the refund policy?", top_k=5)
    assert any("30 days" in c.content for c in chunks)
    assert all(c.score > 0.5 for c in chunks)
```

### Layer 3 — Evaluation suite (real LLM, run separately)

```bash
# Run before merging any significant change
# Tag: @pytest.mark.eval — not in default CI run
python scripts/evaluate.py --questions tests/fixtures/questions.json
# Must output: all metrics >= baseline - 0.05
```

---

## Observability for AI (extends references/observability.md)

```python
# Every LLM call must log (in llm/client.py Adapter):
logger.info({
    "requestId": RequestContext.get_id(),
    "model": model,
    "input_tokens": usage.input_tokens,
    "output_tokens": usage.output_tokens,
    "latency_ms": latency,
    "cost_usd": cost,
    "retrieved_chunks": len(chunks),
    "top_chunk_score": chunks[0].score if chunks else None
}, "LLM call completed")

# On generation failure:
logger.error({
    "requestId": RequestContext.get_id(),
    "model": model,
    "error": str(e),
    "fallback_triggered": True
}, "LLM call failed — returning fallback response")
```

### Tracing for RAG (what to capture per query)

```
requestId → trace every hop
  ↓ query_text (anonymized if user data)
  ↓ retrieval_time_ms, chunks_retrieved, top_score
  ↓ context_size_tokens
  ↓ generation_time_ms, output_tokens
  ↓ answer_text (first 200 chars for log)
  ↓ total_latency_ms, total_cost_usd
```

### Alert rules (AI-specific)

```
Retrieval quality degraded: avg top_score < 0.6 for 100 queries → alert
Answer quality degraded: faithfulness < 0.7 for 50 queries → alert
Cost spike: daily cost > 2x 7-day average → alert
High fallback rate: fallback_triggered > 20% of queries → alert
Embedding model mismatch: schema version mismatch in vector store → critical alert
```

---

## L4 AI-specific hardening signals

| Signal | Action |
|---|---|
| Hit rate < 0.85 | Tune chunking: reduce chunk_size, increase overlap |
| Low retrieval diversity | Add MMR (Maximum Marginal Relevance) reranking |
| High latency (p95 > 5s) | Reduce top_k, add semantic cache, batch embedding |
| High hallucination rate | Tighten system prompt, add faithfulness guardrails |
| Cost too high | Switch to cheaper embedding model, add query cache |
| Stale knowledge | Add incremental indexing with change detection |
| Wrong answers on specific topics | Add metadata filtering, topic-specific retrieval |

---

## Walking skeleton for RAG MVP

The minimal RAG that proves end-to-end works:

```
1. Ingest 5-10 sample documents → indexed in local Chroma
2. Answer 1 question using retrieved chunks
3. Log: question, retrieved chunk, answer, tokens_used
4. Run 5-question mini eval → see scores (not that they're good)

Gate: the answer is grounded in retrieved context (not hallucinated)
Do NOT optimize before running this gate.
```

---

## Common AI project mistakes (add to CLAUDE.md)

```markdown
## AI/LLM anti-patterns

Never do:
- Inline prompt strings in service code → use prompts/ directory
- Call LLM outside the designated llm/ module
- Assert exact LLM output in tests → assert structure + constraints
- Skip evaluation before shipping retrieval changes
- Change embedding model without full re-index
- Store LLM context in module variables → use session storage
- Ignore token count → always log and budget
- Trust LLM to know when to say "I don't know" → add explicit guardrails

Always do:
- Run eval suite before merging RAG changes
- Log requestId + tokens + cost + latency on every LLM call
- Test with adversarial questions (unanswerable ones)
- Add metadata to every chunk at ingestion time
- Version your vector store schema
- Keep prompt templates in version control
```
