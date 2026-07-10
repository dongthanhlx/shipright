# Stack Reference: AI Agents & Multi-Agent Systems

> An agent is not magic — it is **an LLM using tools in a loop based on environmental feedback**,
> best built as a **controllable state machine**. Most "agent" needs are actually a workflow.
>
> Master anchors: **Anthropic — Building Effective Agents** (workflow vs agent, the 5 patterns,
> simplicity); **Andrew Ng** (4 agentic patterns: reflection · tool use · planning · multi-agent);
> **Harrison Chase / LangGraph** (agents as explicit, persisted state machines with human-in-the-loop);
> **the eval school — Chip Huyen · Hamel Husain · Shreya Shankar** (you cannot improve what you don't
> evaluate). shipright's lens: the same boundaries, judgment, and resilience hold — an agent just has
> probabilistic failure modes that *compound*.

---

## Decision 0 — workflow or agent? (Anthropic: simplicity first)

> "Find the simplest solution possible; only increase complexity when it demonstrably improves
> outcomes." Agents trade latency, cost, and predictability for autonomy. Earn that trade.
> This is `references/judgment.md` applied to AI — a one-way vs two-way door call.

```
A single LLM call + retrieval + good examples solves it?   → do that. Not an agent.
Fixed, known steps?                                        → a WORKFLOW (predefined code paths).
Open-ended, # of steps can't be predicted in advance?      → an AGENT (LLM directs its own process).
Multiple agents?                                           → almost never at first. See "multi-agent".
```

**Workflow** = LLMs + tools orchestrated through *predefined code paths* (you keep control).
**Agent** = the LLM *dynamically directs its own process and tool usage* (it keeps control).
Prefer the leftmost option that works. Agents are for when you genuinely can't script the path.

---

## The 5 composable workflow patterns (Anthropic)

Build these before reaching for an autonomous agent — they're more reliable and cheaper.

```
1. Prompt chaining     — split into fixed sequential steps, each on the prior output; optional
                         "gate" checks between. Use when the task cleanly decomposes (draft → translate).
2. Routing             — classify the input, send it to a specialized follow-up. Use for distinct
                         categories handled better separately (support triage; cheap model for easy Qs).
3. Parallelization     — run calls simultaneously, then aggregate. Two forms:
                           Sectioning — independent subtasks in parallel (speed).
                           Voting     — same task run N times for diverse takes (guardrails, review).
4. Orchestrator-workers— a central LLM breaks a task into subtasks *not known in advance*, delegates
                         to workers, synthesizes results. Use when subtasks are unpredictable (multi-file edits).
5. Evaluator-optimizer — one LLM generates, another critiques in a loop. Use when there are clear
                         eval criteria and iteration adds value (literary translation, hard search).
```

## Andrew Ng's 4 agentic design patterns (how to think about capability)

```
Reflection  — the model critiques and revises its own output   → often = evaluator-optimizer.
Tool use    — the model calls external tools/functions          → the augmented LLM + MCP (mcp.md).
Planning    — the model decomposes and sequences its own steps  → orchestrator / autonomous loop.
Multi-agent — specialized agents collaborate                    → see below (use sparingly).
```
These are lenses, not a pipeline. Reflection + tool use cover a huge share of real value at low risk.

---

## The autonomous agent = a controllable state machine (LangGraph / Chase)

An agent "is typically just an LLM using tools based on environmental feedback in a loop." Model it
as an explicit state machine so it stays debuggable and controllable — not a black-box while-loop.

```
State (persisted every step — never in-memory only):
  goal, messages/history, scratchpad/plan, tool results, step count, cost so far.

The loop:
  observe → the LLM decides (next tool or done) → act (call tool) → observe result → repeat
  until: goal met · a stop condition trips · a human checkpoint is required.

Make it controllable:
  □ Explicit nodes/edges (or a clear switch), not an opaque recursion — you can trace and resume.
  □ Human-in-the-loop checkpoints before irreversible actions (approve, edit, or reject).
  □ Deterministic stop conditions: max iterations, max cost, max wall-clock, "no progress" detector.
  □ Persist state so a run can pause, resume, and be replayed (this is also your audit trail).
```

Anthropic's 3 principles for any agent: **simplicity** of design, **transparency** (show the plan/steps),
and a well-crafted **agent-computer interface** (tools documented + tested — see mcp.md ACI section).

---

## Multi-agent: when it actually helps (and when it's over-engineering)

> Default to a SINGLE agent with good tools. Multi-agent adds coordination cost and *more* surfaces
> for compounding errors. Reach for it only on a real signal — this is the rule-of-three for agents.

```
Justified when (need most of these):
  □ Genuinely distinct skill sets / tool sets / system prompts that pollute one agent's context.
  □ Subtasks that parallelize independently (orchestrator delegating to workers).
  □ Context window / focus pressure — one agent can't hold the whole job coherently.

Topologies:
  Orchestrator → workers   — one planner delegates, workers report back, planner synthesizes. (Anthropic)
  Sequential pipeline       — specialized agents hand off in order (research → write → review).
  Debate / voting           — parallel agents, then aggregate/critique (evaluator-optimizer at scale).

Costs to respect: each hop is an integration point (Boundary 5), each agent compounds cost + error,
and handoffs lose context. Keep handoffs explicit and typed — an agent-to-agent message is an
interface contract, not a free-form dump.
```

---

## Boundaries for agents (the same rules, probabilistic edition)

```
□ Tools only via a registered tool registry — never ad-hoc function calls (auditable, least-privilege).
□ Agent state is persisted (DB/Redis) between steps — NEVER assume clean in-memory state (Boundary 5 sibling).
□ LLM calls stay behind the LLM boundary / ACL (ai-projects.md); raw model output never enters the domain untyped.
□ Agent-to-agent and agent-to-tool messages are typed interface contracts (OCP/LSP still apply).
□ Prompts/plans are versioned artifacts, not inline strings.
```

## Resilience — compounding errors are the agent-specific failure (Nygard)

```
□ Cap everything: max iterations, max tool calls, max cost/run, max depth. Unbounded agent = outage.
□ Timeout on every tool/LLM call (Boundary 5); idempotent tools so retries/re-plans don't double-act.
□ Tool errors are DATA — return them so the agent can adapt; don't throw and kill the run.
□ Circuit-break a flapping tool; degrade to a partial answer over a crash.
□ Sandbox side-effecting agents; test in a sandbox before production (Anthropic).
□ A "no progress" detector (same action repeated / looping) → stop and escalate to a human.
```

## Guardrails & security

```
□ Input + output guardrails (prohibited content, PII, schema) — parallelization/voting is a good fit.
□ Untrusted content: tool results, retrieved docs, another agent's output are DATA, never instructions
  (prompt injection — OWASP LLM01). The architecture prevents unauthorized actions, not the model.
□ Least privilege / excessive agency (LLM06): each tool narrow-scoped; no arbitrary-exec in a loop.
□ Human approval before irreversible actions. Watch the lethal trifecta (see references/stacks/mcp.md).
```

---

## Evaluation — the foundation, not an afterthought (the eval school)

> Chip Huyen / Hamel Husain / Shreya Shankar: you cannot improve what you don't measure, and vibes
> are not evaluation. For agents, evaluate the **trajectory**, not just the final string.

```
□ Build an eval set BEFORE building the agent (≥ 20 real cases). Run it before AND after every change.
□ Trajectory-level metrics: did it pick the right tools, with the right args, in a sane order, and STOP?
□ Task success against ground truth where it exists (the environment gives "ground truth" — Anthropic).
□ Error analysis: read the traces. Cluster failures. Fix the top cluster. Repeat (the eval flywheel).
□ LLM-as-judge with rigor — validate the judge against human labels ("who validates the validators").
□ Never assert exact output strings — assert structure, constraints, and trajectory properties.
Tools: DeepEval / Confident-AI (agents), RAGAS (RAG), LangSmith / Arize Phoenix (trace + eval).
```

## Observability — trajectory is the Correlation ID of an agent

```
Per run:  runId + full trajectory (steps, decisions, tool calls, retries, stop reason).
Per step: { runId, step, tool, args (sanitized), duration, ok/error, tokens, cost_usd }.
One trace = the whole run (LangSmith / Arize Phoenix / OpenTelemetry GenAI). Ties to observability.md.
```

---

## Framework decision (Anthropic: start from the API; understand the code under any framework)

```
Raw SDK (Anthropic/OpenAI) — most control, least magic. Start here to learn the loop.
LangGraph                  — explicit state-machine agents, persistence, human-in-the-loop. Control-first.
AutoGen                    — conversational multi-agent. CrewAI — role-based multi-agent (research).
```
Frameworks speed startup but can obscure prompts/responses and invite needless complexity — add one
only when it demonstrably helps, and read its underlying code.

---

## Debt signals + CLAUDE.md additions

```markdown
## Agent conventions
- Workflow before agent; single agent before multi-agent. Justify autonomy against judgment.md.
- Agent = explicit persisted state machine. Stop conditions: max iterations/cost/time + no-progress.
- Tools via registry only; state persisted; agent/tool messages are typed contracts.
- Untrusted-by-default; least privilege; human approval before irreversible actions.
- Eval set exists and runs before/after every prompt/tool/graph change. Trajectory-level, not strings.
- Every run logs runId + full trajectory + per-step tokens/cost. Never log secrets/PII.

## Debt signals
- TODO[step-count-p95>N]: agent looping — add a no-progress detector / better stop condition
- TODO[cost>$X/run]: cache tool results, cap iterations, or route easy cases to a workflow
- TODO[multi-agent-considered]: prove a single agent with tools can't do it before splitting
- TODO[success<target]: run error analysis on traces, fix the top failure cluster
```

---

## Ubiquitous Language
Name agents, tools, and states in domain terms: a `RefundOrchestrator` with a `PENDING_APPROVAL`
state, not a `Manager` in a `state2`. The agent's own reasoning reads these names — make them mean
something. Define them in CLAUDE.md before writing the graph.
