# Registry pack — ai-agent

> One project-type pack. Load it together with the trigger index in `references/registry.md`,
> never the other packs. Install names, commands and the consent rule: registry.md §Install recipes.

LLM-powered agent with tool calling, planning, multi-step reasoning.

```
install:
  required:
    - addyosmani/agent-skills
      skills: [incremental-implementation, spec-driven-development, code-review-and-quality]
  evaluation:
    - DeepEval OR Confident-AI (agent trajectory evaluation)
    - Note: RAGAS is for RAG, not agent evaluation — different metrics
  optional:
    - datadog-labs/dd-llmo-eval-trace-rca (root cause analysis)
    - LangSmith (LLM tracing with agent trajectory)

tested-with: LangGraph 0.2+, AutoGen 0.4+

load: references/stacks/ai-agent.md — full guide (workflow-vs-agent, the 5 patterns, agent as a
      controllable state machine, when multi-agent helps, resilience, guardrails, trajectory eval)

framework-decision:
  single-agent: LangChain + tool calling
  multi-agent: LangGraph (state machines) or AutoGen (conversational)
  research: CrewAI (role-based agents)

shipright-adds-to-CLAUDE:
  boundary-tools: "Tool calls only via registered tool registry. Never direct function calls."
  boundary-state: "Agent state persisted between steps. Never assume clean state."
  eval-policy: "Trajectory-level evaluation: tool calls + planning steps + output quality"
  cost-tracking: "Log per-step: model + tokens + tool_calls + latency. Agents compound cost."
  debt-signals:
    - "TODO[error-rate>5%]: add retry with exponential backoff per tool call"
    - "TODO[cost>$X/day]: add caching layer for repeated tool calls"
    - "TODO[hallucination>10%]: add output validation guardrails"
```
