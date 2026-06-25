# shipright v0.7.0

> **Ship your MVP fast. Grow it right.**

The Project Brain for AI coding workflow. Sets up the minimal irreversible architecture decisions, enforces three masters of software quality (Evans + Uncle Bob + Fowler), orchestrates community skills at the right moment, and tracks project state across sessions.

Works in your language. Write Vietnamese, English, or any language — shipright responds accordingly.

```
/shipright
```

---

## What it does

**Layer 1 — Always active:** 4 boundary rules + 3-master quality system + 6-branch routing
**Layer 2 — Registry:** Project type → curated skill pack + CLAUDE.md additions
**Layer 3 — On demand:** Branch files (one per session), reference files (load on signal)

| You say | Shipright does |
|---|---|
| New project | Check state → intake + registry → constitution → skeleton |
| Add feature | Read CLAUDE.md → health check → complexity tier → quality gate |
| Fix bug | Classify → reproduce → locate → root cause → fix |
| Refactor | Fowler smell → define done → characterization tests → atomic steps |
| Resume after break | Read state section → continue in 30 seconds |
| Production incident | Triage → mitigate first → investigate → post-incident |

---

## The 4 boundaries — never negotiable

```
1. Dependencies point inward only
2. Each layer has one job (handler / service / repository)
3. Modules do not share databases
4. No raw external response passes the Adapter layer
```

Backed by Uncle Bob's Dependency Rule, Fowler's internal quality research,
and Eric Evans's Anti-Corruption Layer pattern.

---

## Three masters, one quality system

| Master | Dimension | When |
|---|---|---|
| Evans (DDD) | Model the right domain | L0: Ubiquitous Language, domain types |
| Uncle Bob (SOLID) | Structure it correctly | L3: quality gate before every commit |
| Fowler (Refactoring) | Keep it clean as it evolves | Branch D: smell-driven refactoring |

Compound Engineering: every AI violation → specific rule added to CLAUDE.md.
CLAUDE.md gets smarter every session.

---

## Persistent state

Shipright writes a state section to CLAUDE.md after milestones:
```markdown
## Shipright state
Level: L3
Active: payments module
Next: implement PaymentService.charge() — RED test exists line 47
Last updated: 2025-06-21
```

Branch E reads this instantly. Resume in 30 seconds, not 5 minutes.

---

## Registry — curated skill packs per project type

`references/registry.md` maps project type → required skills + CLAUDE.md additions:

| Project type | Registry entry | Key installs |
|---|---|---|
| REST API / backend | web-api | addyosmani/agent-skills |
| RAG / knowledge base | rag-pipeline | RAGAS + addyosmani |
| Telegram/Discord bot | chatbot-telegram-discord | grammy/discord.js + addyosmani |
| Browser extension | browser-extension | jest-webextension-mock |
| AI agent | ai-agent | DeepEval + addyosmani |
| Full-stack web | full-stack-web | addyosmani + taste-skill |
| CLI tool | cli-tool | optional |

---

## Ecosystem

Shipright orchestrates. These execute.

| Skill | Stage | What it handles |
|---|---|---|
| addyosmani/agent-skills | Traction+ | Implementation, TDD, code review, security |
| taste-skill | When UI needed | Landing pages, portfolios, product UI |
| RAGAS | RAG projects | Evaluation metrics (Hit Rate, Faithfulness) |
| LangSmith / Arize | AI projects | LLM tracing and observability |
| vercel-labs/agent-skills | Dashboards | Data-heavy UI, a11y, UX correctness |

**Never install all addyosmani skills at once.** Context budget is finite.
Registry tells you exactly which skills to install for your project type.

---

## Install

**Personal — git (enables update notifications):**
```bash
git clone https://github.com/dongthanhlx/shipright ~/.claude/skills/shipright
```

**Update:**
```bash
git -C ~/.claude/skills/shipright pull
```

**Session start update check (optional):**
```json
// ~/.claude/settings.json
{
  "hooks": {
    "SessionStart": [{
      "type": "command",
      "command": "~/.claude/skills/shipright/hooks/check-update.sh"
    }]
  }
}
```

---

## Structure

```
shipright/
  SKILL.md                    # Project Brain core (~3,500 tokens always loaded)
  hooks/check-update.sh       # SessionStart update checker
  references/
    onboarding.md             # State check + 6-branch router
    registry.md               # Project type → curated skill pack (NEW v0.7)
    branches/
      a-new-project.md        # MVP/Production + registry integration + state tracking
      b-add-feature.md        # Health check + complexity tiers + quality gate
      c-fix-bug.md            # Classify → reproduce → root cause
      d-refactor.md           # Fowler smells + characterization tests
      e-resume.md             # State-first orient (30s resume) + git fallback
      f-incident.md           # Triage → mitigate → investigate
    code-quality.md           # Evans + Uncle Bob + Fowler: full quality system
    observability.md          # Correlation ID, logging, API tracing, retrofit
    scaling-guide.md          # Stage 1→2→3 + Strangler Fig templates
    third-party-apis.md       # Adapter pattern, 3-layer testing, resilience
    ui-design.md              # taste-skill: page type → correct skill → dials
    l0-templates.md           # CLAUDE.md + ARCHITECTURE.md templates + state section
    levels.md                 # L0→L4, gates, Conway's Law, graduate checklist
    boundaries.md             # 4 boundary rules with code examples
    requirement-drift.md      # Expand-Contract + 3 architecture scenarios
    debug-intermittent.md     # Intermittent / production-only / resource leak bugs
    prompts.md                # Copy-paste Claude Code prompts
    stacks/
      nodejs.md
      python.md
      ai-projects.md          # AI entry point + 5th boundary rule
      ai-rag.md               # RAG deep dive: eval loop, vector DB, metrics
      chatbot-platforms.md    # Telegram/Discord: adapter, state, security
      browser-extension.md    # MV3: manifest, components, chrome.* APIs
    examples/
      news-crawler-CLAUDE.md
      news-crawler-ARCHITECTURE.md
```

---

## Roadmap

- [x] 6-branch routing
- [x] MVP mode vs production mode
- [x] 4 boundary rules (non-negotiable)
- [x] Three masters quality system (Evans + Uncle Bob + Fowler)
- [x] Complexity-based skill activation (Tier S/M/L/XL)
- [x] Observability: Correlation ID, tracing, API tracing, retrofit
- [x] Scaling guide: Stage 1→2→3 + Strangler Fig
- [x] AI/RAG/chatbot/browser-extension stack support
- [x] **v0.7: Registry (project type → curated skill pack)**
- [x] **v0.7: Persistent state (CLAUDE.md state section)**
- [x] **v0.7: Session-start state check (30-second resume)**
- [x] **v0.7: Ecosystem dispatch (who owns what)**
- [ ] Go stack file
- [ ] references/registry.md community contributions
- [ ] PreToolUse boundary enforcement hook

---

## License

MIT
