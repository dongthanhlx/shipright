# AI Projects — Entry Point

> Load `references/registry.md` for your specific type:
> - rag-pipeline → registry entry: rag-pipeline
> - chatbot → registry entry: chatbot-telegram-discord
> - ai-agent → registry entry: ai-agent
> - LLM integration only → use web-api entry + rules below

## The 5th boundary rule (all AI projects)

```
Boundary 5: All LLM calls in dedicated llm/ or ai/ module ONLY
  Never in service, handler, repository, or adapter layers.
  Prompt templates are files in prompts/ directory — never inline strings.
  LLM module returns typed domain objects — never raw LLM response strings.
  ResponseAdapter (ACL) translates between probabilistic LLM output and deterministic domain.
```

This IS Eric Evans's Anti-Corruption Layer applied to LLMs.
Evans (2026): "When calling an LLM, we bridge between deterministic and probabilistic
systems — an ACL is appropriate here."

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

For agent patterns (tool calling, trajectory evaluation):
→ references/registry.md — ai-agent entry
