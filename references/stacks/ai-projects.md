# Stack Reference: AI Projects — RAG, Agents, LLM Applications

## The fundamental difference from regular software

Regular software is deterministic: same input → same output → pass/fail test.
AI software is probabilistic: same input → similar output → quality score.

This changes everything about testing, observability, and what "done" means.
Shipright's L0→L4 tree and 4 boundary rules still apply — but each level needs
AI-specific additions that regular stack files don't have.

---

## 2026 reality check (from research)

```
73% of RAG failures happen at retrieval, not generation
40% of LLM apps have quality regressions within 90 days of production
72% of enterprises run RAG in production (was 8% in Q1 2024)
Naive RAG pipelines fail at retrieval ~40% of the time
```

Key insight: when your RAG gives a wrong answer, don't tune the system prompt first.
Score Context Precision and Context Recall (RAGAS) before touching anything else.

---

## AI project types — load the right sub-file

When user confirms AI project type, load the specific stack file:

| Project type | Load | Description |
|---|---|---|
| RAG / knowledge base / document Q&A | `references/stacks/ai-rag.md` | Retrieval, chunking, vector DB, eval loop |
| Chatbot for Telegram/Discord | `references/stacks/chatbot-platforms.md` | Platform Adapter, conversation state, security |
| RAG chatbot (both) | Load both files | Combine patterns from both |
| LLM API integration only | This file (ai-projects.md) | No retrieval, just LLM calls |
| AI agents / tool calling | This file (ai-projects.md) | LangChain/LangGraph agent patterns |

---

## AI project types — architectural differences

```
Type 1: RAG pipeline       — retrieval + generation, knowledge grounding
Type 2: LLM application    — structured LLM calls with prompt engineering
Type 3: AI agent           — LLM with tool use, multi-step reasoning
Type 4: Multi-agent system — multiple agents, orchestration, shared state
```

Shipright handles all four — walking skeleton differs per type.

---

## The 5th boundary rule for AI projects

Add this to CLAUDE.md when building any AI project:

```
5. LLM calls are external API calls — Adapter pattern applies (Boundary Rule 4)
   Every LLM call goes through a dedicated LLM client wrapper.
   Raw LLM response NEVER enters business logic directly.
   Normalize: LLMResponse → domain type (Answer, SearchResult, Classification).
   Why: swap models, add retry, add evaluation, add tracing — in one place.
```

---

## L0 Constitution additions for AI projects

### Additional CLAUDE.md sections for AI projects

```markdown
## AI-specific constraints

### LLM calls
LLM client: [OpenAI SDK / Anthropic SDK / LiteLLM]
All calls go through: src/llm/client.ts (single wrapper)
Raw LLM response NEVER returned to service layer — normalize first.
Every call logs: model, tokens, latency, prompt_version (see observability.md)

### Prompt management
Prompts live in: src/prompts/ (versioned, NOT hardcoded in service files)
Prompt versions tracked in: src/prompts/registry.ts
Never hardcode prompts inline — they change independently of code.

### Non-determinism policy
LLM outputs are probabilistic. Test with quality scores, not exact string match.
Evaluation framework: [RAGAS / DeepEval / promptfoo]
Minimum passing score: [context_precision > 0.8, faithfulness > 0.85]
Golden dataset: tests/golden/ (minimum 50 examples before production)

### Cost tracking
All LLM calls track token usage.
Daily budget: $[X] — alert at 80%.
Model selection: balance quality vs cost per use case.
TODO[daily_cost>$X]: review model selection and caching strategy.

### Deterministic first
Use conventional code for: arithmetic, status lookups, rule-based decisions.
Use LLM only for: ambiguity resolution, natural language understanding, generation.
```

### ARCHITECTURE.md additions for RAG pipeline

```markdown
## RAG Architecture

### Two-phase design (always separate these)

INGESTION PHASE (offline, runs on schedule or trigger):
  Source → Loader → Chunker → Embedder → Vector Store
  This phase is slow, expensive, runs once per document change.
  
RETRIEVAL PHASE (online, runs per user query):
  Query → Embedder → Vector Store → Reranker → LLM → Answer
  This phase must be fast (target: < 3s end-to-end p95).

### Component responsibilities

Loader:       parse source documents, extract text + metadata
Chunker:      split into semantically meaningful pieces
Embedder:     generate vector representations (single embedding model)
Vector Store: similarity search with metadata filtering
Retriever:    hybrid search = dense (vector) + sparse (BM25)
Reranker:     cross-encoder reranking of top-K → top-N results
LLM Client:   call generation model with retrieved context
Evaluator:    score output quality (faithfulness, precision, recall)

### Failure points (from 2026 research: 73% of failures are here)
Retrieval quality > generation quality in impact.
If answer is wrong: check retrieval first, tune prompt second.
```

---

## L1 Skeleton — walking skeleton per AI project type

### Type 1: RAG pipeline skeleton

```
Walking skeleton: user sends 1 query → system retrieves 1 relevant chunk → LLM answers

Prove end-to-end works:
1. Load 1 document, chunk it, embed it, store in vector DB
2. Take 1 query, embed it, retrieve top-1 chunk
3. Pass chunk + query to LLM, get answer
4. Print: [query] → [retrieved chunk] → [answer]

Gate: this works for 1 document and 1 query. No UI, no error handling yet.
Do NOT add more documents, multi-query, or reranking until gate passes.
```

### Type 2: LLM application skeleton

```
Walking skeleton: user input → prompt template → LLM call → structured output

Prove end-to-end works:
1. Accept user input as string
2. Fill prompt template with input
3. Call LLM, get response
4. Parse response to domain type (not raw string)
5. Return structured result

Gate: 1 happy path works end-to-end. Test with 3 manual inputs.
```

### Type 3: AI agent skeleton

```
Walking skeleton: user task → agent reasons → 1 tool call → result

Prove end-to-end works:
1. User sends a task
2. Agent calls LLM to reason about which tool to use
3. Agent calls exactly 1 tool with correct parameters
4. Agent returns result with reasoning trace

Gate: 1 complete tool-use cycle works. Monitor token usage.
Do NOT add multiple tools or multi-step reasoning until gate passes.
```

---

## L2 — Evaluation-first (not test-first for AI)

For AI projects, L2 is different: you define evaluation criteria before implementing,
the same way TDD defines test cases before implementing.

### Evaluation-first workflow

```
Instead of: write failing test → implement → make test pass
For AI:     define quality criteria → build golden dataset → implement → score

Step 1: Define what "correct" means for your use case
  RAG: faithfulness > 0.85, context_precision > 0.80, answer_relevancy > 0.75
  Classifier: accuracy > 0.90, precision > 0.85 on critical class
  Agent: task_completion > 0.80, tool_call_accuracy > 0.90

Step 2: Build golden dataset BEFORE implementing
  Minimum: 50 input/expected-output pairs for MVP, 200 for production
  Source: domain expert-authored examples (not AI-generated)
  Location: tests/golden/[use-case]/
  Format:
    input: [query or task]
    expected_answer: [correct answer]
    source_docs: [which documents should be retrieved]
    acceptable_variations: [paraphrases that count as correct]

Step 3: Implement
Step 4: Score against golden dataset
Step 5: Gate: minimum scores must pass before merging
```

### RAGAS metrics — what to track

```python
# Install: pip install ragas
from ragas import evaluate
from ragas.metrics import (
    faithfulness,          # Is answer grounded in retrieved context?
    answer_relevancy,      # Does answer address the question?
    context_precision,     # Are retrieved chunks actually relevant?
    context_recall,        # Did retrieval find all relevant chunks?
)

# Run after each significant change to retrieval or generation
results = evaluate(
    dataset=golden_dataset,
    metrics=[faithfulness, answer_relevancy, context_precision, context_recall]
)

# FAIL CI if below thresholds
assert results['faithfulness'] > 0.85, f"Faithfulness too low: {results['faithfulness']}"
assert results['context_precision'] > 0.80
```

### promptfoo — regression testing for prompts

```yaml
# promptfooconfig.yaml — test every prompt change
prompts:
  - file://src/prompts/rag-system.txt

providers:
  - openai:gpt-4o-mini
  - anthropic:claude-sonnet-4-6

tests:
  - description: "Answers factual question from context"
    vars:
      question: "What is the return policy?"
      context: "Returns accepted within 30 days..."
    assert:
      - type: contains
        value: "30 days"
      - type: llm-rubric
        value: "Answer directly addresses the question using only the provided context"

  - description: "Refuses to answer without context"
    vars:
      question: "What is the CEO's salary?"
      context: "[no relevant context]"
    assert:
      - type: llm-rubric
        value: "Response indicates insufficient information, does not hallucinate"
```

---

## L3 — Implementation patterns

### Chunking strategy (start here, optimize later)

```python
# Start: recursive chunking at 300-500 tokens, 10-15% overlap
# This works for 80% of use cases (from 2026 research)

from langchain.text_splitter import RecursiveCharacterTextSplitter

splitter = RecursiveCharacterTextSplitter(
    chunk_size=400,       # tokens
    chunk_overlap=50,     # ~12% overlap
    separators=["\n\n", "\n", ". ", " ", ""]
)

# Optimize only if RAGAS context_precision < 0.7:
# → Try smaller chunks (200 tokens)
# → Try semantic chunking
# → Add parent-child chunk relationships
```

### Hybrid search (retrieval)

```python
# Hybrid = dense (vector) + sparse (BM25) + reciprocal rank fusion
# Consistently improves recall by 15-30% over pure vector search

from qdrant_client import QdrantClient
from qdrant_client.models import SparseVector

# Dense retrieval (semantic similarity)
dense_results = client.search(
    collection_name="documents",
    query_vector=embed(query),
    limit=50  # retrieve top-50
)

# Sparse retrieval (keyword matching — catches exact terms, product codes, names)
sparse_results = client.search(
    collection_name="documents",
    query_sparse_vector=bm25_encode(query),
    limit=50
)

# Reciprocal Rank Fusion
fused = reciprocal_rank_fusion([dense_results, sparse_results])
# Rerank to top-5 before passing to LLM
final = rerank(fused[:20], query)[:5]
```

### LLM client wrapper (Boundary Rule 4 + 5)

```typescript
// src/llm/client.ts — single place for all LLM concerns
export class LLMClient {
  async complete(params: {
    prompt: string
    model: string
    maxTokens: number
    temperature: number
    promptVersion: string  // track which prompt generated this
  }): Promise<LLMResponse> {

    const startedAt = Date.now()
    const callId = randomUUID()

    logger.info({ callId, model: params.model, promptVersion: params.promptVersion,
                  inputTokensEstimate: estimate(params.prompt) }, 'LLM call started')

    try {
      const raw = await this.provider.complete(params)

      logger.info({ callId, model: params.model,
                    inputTokens: raw.usage.input_tokens,
                    outputTokens: raw.usage.output_tokens,
                    duration: Date.now() - startedAt,
                    cost: calculateCost(raw.usage, params.model) }, 'LLM call succeeded')

      return this.normalize(raw)  // never return raw response

    } catch (error) {
      logger.error({ callId, model: params.model, error: error.message,
                     duration: Date.now() - startedAt }, 'LLM call failed')
      throw new ExternalAPIError('LLM call failed', 'LLM_ERROR')
    }
  }
}
```

### Prompt versioning

```typescript
// src/prompts/registry.ts
export const PROMPTS = {
  RAG_SYSTEM: {
    version: 'v2.1',
    template: `You are a helpful assistant. Answer the question using ONLY the provided context.
If the context doesn't contain enough information, say "I don't have enough information."

Context:
{context}

Question: {question}

Answer:`
  },
  // Never hardcode prompts inline in service files
  // Changes to prompts must update version field
  // Run promptfoo regression test before merging prompt changes
}
```

---

## Observability for AI projects

Add to CLAUDE.md and connect to references/observability.md:

```typescript
// Every LLM call must emit these traces to Langfuse/LangSmith
{
  // Request
  prompt_version: 'v2.1',
  model: 'gpt-4o-mini',
  input_tokens: 1240,
  temperature: 0.1,

  // Response
  output_tokens: 180,
  latency_ms: 1340,
  cost_usd: 0.00148,

  // Quality (if evaluation runs inline)
  faithfulness_score: 0.91,
  answer_relevancy_score: 0.87,

  // RAG-specific
  retrieved_chunks: 5,
  context_precision: 0.82,
  query_embedded_ms: 45,
  retrieval_ms: 180,
}
```

### Langfuse setup (open-source, recommended)

```python
# pip install langfuse
from langfuse import Langfuse

langfuse = Langfuse()

# Wrap LLM call with trace
with langfuse.trace(name="rag-query") as trace:
    span = trace.span(name="retrieval")
    chunks = retrieve(query)
    span.end(output={"chunks": len(chunks)})

    generation = trace.generation(
        name="llm-answer",
        model="gpt-4o-mini",
        input={"query": query, "context": chunks},
        output=answer,
        usage={"input": input_tokens, "output": output_tokens}
    )

# Monitor: quality scores over time, cost per query, latency distribution
```

---

## Tech debt log — AI-specific triggers

```markdown
| Shortcut | Trigger to fix |
|---|---|
| No reranking | TODO[context_precision<0.7]: add cross-encoder reranker |
| Fixed chunking | TODO[recall<0.8]: try semantic chunking or parent-child |
| Single embedding model | TODO[doc_types>3]: specialized models per doc type |
| No caching for embeddings | TODO[embedding_cost>$X/day]: add Redis cache for embeddings |
| OpenAI dependency | TODO[vendor_risk]: add LiteLLM for model switching |
| No evaluation in CI | TODO[before_production]: add RAGAS gate to CI pipeline |
| Golden dataset < 50 | TODO[before_production]: expand to minimum 50 examples |
| No guardrails | TODO[public_launch]: add input validation and output filtering |
```

---

## Tool recommendations (2026)

| Category | Recommended | Notes |
|---|---|---|
| RAG framework | LangChain 0.3+ or LlamaIndex | LangChain for flexibility, LlamaIndex for RAG focus |
| Vector DB (managed) | Pinecone | Fastest to production |
| Vector DB (self-hosted) | Qdrant | Best performance/cost ratio, native hybrid search |
| Vector DB (dev/small) | ChromaDB | Zero infra, great for MVP |
| Embeddings (hosted) | text-embedding-3-small | Cost efficient, good quality |
| Embeddings (self-hosted) | BGE or GTE-Qwen2 | For sensitive data |
| LLM abstraction | LiteLLM | Switch models without code changes |
| Evaluation | RAGAS + DeepEval | RAGAS for RAG metrics, DeepEval for CI gates |
| Prompt testing | promptfoo | Regression test prompts before deploy |
| Observability | Langfuse (open-source) | Traces + evaluation in one place |
| Agents | LangGraph | Stateful, production-grade |

---

## Walking skeleton examples per type

### RAG: document Q&A

```
1 document → 1 query → 1 answer (proves pipeline works)
Ship gate: answer is factually correct for 3 test queries on 1 document
Validate: is retrieval finding the right chunk? (check before tuning LLM)
```

### LLM: structured extraction

```
1 raw text → 1 LLM call → 1 structured output (dict/object, not raw string)
Ship gate: extraction is correct for 10 manual test cases
Validate: is output always parseable? (before tuning prompts)
```

### Agent: task execution

```
1 user request → 1 reasoning step → 1 tool call → 1 result
Ship gate: agent completes task correctly for 5 representative requests
Validate: is tool called with correct params? (trace every call)
```
