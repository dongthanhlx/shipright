# AI Projects — Entry Point

> Load the registry pack for your specific type:
> - rag-pipeline → `references/registry/rag-pipeline.md`
> - chatbot → `references/registry/chatbot-telegram-discord.md`
> - ai-agent / multi-agent → references/stacks/ai-agent.md (+ `references/registry/ai-agent.md`)
> - LLM integration only → use `references/registry/web-api.md` + rules below

## The LLM boundary (all AI projects) — Boundary 4 applied to AI

> This is not a new numbered boundary. It is **Boundary 4** (no raw external response passes the
> Adapter layer) specialized for LLMs — plus **Boundary 5** (timeout + fallback), because an LLM
> API is an integration point too. Don't call it "Boundary 5" — that number is failure isolation.

```
The LLM boundary: All LLM calls in a dedicated llm/ or ai/ module ONLY
  Never in service, handler, repository, or generic adapter layers.
  Prompt templates are files in prompts/ directory — never inline strings.
  LLM module returns typed domain objects — never raw LLM response strings.
  ResponseAdapter (ACL) translates between probabilistic LLM output and deterministic domain.
  Boundary 5 also applies: every LLM/tool call has a timeout + a fallback (resilience.md).
```

This IS Eric Evans's Anti-Corruption Layer applied to LLMs — the bridge between a deterministic
domain and a probabilistic system. The same ACL thinking governs MCP servers and agent tools
(references/stacks/mcp.md): each is an adapter for a capability, not a raw pipe into your domain.

## Non-determinism policy (add to CLAUDE.md)

```markdown
## AI non-determinism rules
- Tests assert structure + constraints, NEVER exact output strings
- JSON schema validation for structured outputs (use zod or pydantic)
- Guardrails for prohibited content in system prompt
- Faithfulness check: answer must be grounded in retrieved context
```

## Eval-first policy (add to CLAUDE.md)

```markdown
## Evaluation-first policy
- Create question set (min 20 questions) BEFORE building retrieval
- Run eval baseline BEFORE any prompt or retrieval change
- Run eval after EVERY significant change
- Never merge if faithfulness drops > 5% from baseline
```

## Cost tracking (add to CLAUDE.md)

```markdown
## LLM cost tracking
Every LLM call logs: model + input_tokens + output_tokens + cost_usd + latency_ms
Daily/monthly budget tracked. Alert at 80% of monthly limit.
```

## Deep-dive references

For RAG-specific patterns (chunking, vector DB, RAGAS metrics):
→ `references/stacks/ai-rag.md`

For Telegram/Discord chatbot patterns (Platform Adapter, conversation state):
→ `references/stacks/chatbot-platforms.md`

For agent + multi-agent patterns (workflow-vs-agent, the 5 patterns, state machines, eval, resilience):
→ references/stacks/ai-agent.md

For exposing tools/data to AI hosts via Model Context Protocol:
→ references/stacks/mcp.md
