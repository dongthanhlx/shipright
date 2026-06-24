# shipright v0.5.9

> **Ship your MVP fast. Grow it right.**

The project constitution skill for Claude Code. Sets up the minimal irreversible architecture decisions that let your codebase grow without rot — then orchestrates the right skills at the right moment.

Works in your language. If you write in Vietnamese, French, Spanish, or any language, shipright responds in kind.

```
/shipright
```

---

## What it does

Asks one question first, then loads only what's needed:

| You say | Shipright does |
|---|---|
| New project | Intake → L0 constitution → walking skeleton → validate → feature loop |
| Add a feature | Read codebase → health check → complexity tier → implement safely |
| Fix a bug | Classify → reproduce → locate → root cause → fix |
| Refactor | Define done → characterization tests → atomic steps |
| Resume after break | Git orient → detect level → find last position → next action |
| Production incident | Triage → mitigate first → investigate → post-incident |

---

## The one thing that never changes

**4 boundaries. Absolute. In MVP and in production.**

```
1. Dependencies point inward only
   Service never imports db. Module never imports another module's internals.

2. Each layer has one job
   Handler: parse → call service → format. No domain logic.
   Service: business rules only. No HTTP, no DB.
   Repository: DB queries only. Returns typed domain objects.

3. Modules do not share databases
   Module A needs data from B → call B's public interface. Never query B's table.

4. No raw external response passes the Adapter layer
   Every third-party API has exactly one Adapter/Normalizer.
   Raw response never enters service or domain logic.
```

These are cheap to do right from day one. Everything else is signal-driven.

---

## Install

**Personal** — works across all your projects:
```bash
git clone https://github.com/[username]/shipright ~/.claude/skills/shipright
```

**Project-scoped** — team shares via git:
```bash
git clone https://github.com/[username]/shipright .claude/skills/shipright
```

**Update:**
```bash
git -C ~/.claude/skills/shipright pull
```

**Enable update notifications at session start (optional):**

Add to `~/.claude/settings.json`:
```json
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

## Ecosystem

Shipright orchestrates. These skills execute specific parts. Install only what you need.

| Skill | When to add | Install |
|---|---|---|
| `debugging-and-error-recovery` | MVP stage — bugs happen from day one | addyosmani/agent-skills |
| `incremental-implementation` | Traction — features span multiple files | addyosmani/agent-skills |
| `test-driven-development` | Traction — prevent regression | addyosmani/agent-skills |
| `code-review-and-quality` | Traction — team consistency | addyosmani/agent-skills |
| `spec-driven-development` | Growth — complex features need specs | addyosmani/agent-skills |
| `design-taste-frontend` | When building landing pages / portfolios | taste-skill |
| `minimalist-skill` | When building product UI (Notion/Linear feel) | taste-skill |
| `web-design-guidelines` | Dashboard / admin / data-heavy UI | vercel-labs/agent-skills |

Do NOT install all 24 addyosmani skills at once. Context budget is finite.

---

## What's inside

```
shipright/
  SKILL.md                              # brain (~4,800 tokens, always loaded)
  hooks/check-update.sh                 # SessionStart update checker
  references/
    onboarding.md                       # thin router (~400 tokens)
    branches/
      a-new-project.md                  # new project: MVP vs production
      b-add-feature.md                  # add feature: health check + complexity tiers
      c-fix-bug.md                      # fix bug: classify → reproduce → locate → fix
      d-refactor.md                     # refactor: define done + characterization tests
      e-resume.md                       # resume: git orient + detect level
      f-incident.md                     # incident: triage → mitigate → investigate
    examples/
      news-crawler-CLAUDE.md            # real CLAUDE.md output
      news-crawler-ARCHITECTURE.md      # real ARCHITECTURE.md output
    levels.md                           # L0→L4, gates, Conway's Law, graduate checklist
    l0-templates.md                     # CLAUDE.md + ARCHITECTURE.md templates (4 boundaries)
    boundaries.md                       # 4 boundary rules with code examples
    observability.md                    # Correlation ID, logging, API tracing, retrofit
    scaling-guide.md                    # 3-stage scaling playbook + Strangler Fig
    requirement-drift.md                # Expand-Contract + 3 architecture change scenarios
    third-party-apis.md                 # 3-layer testing, Adapter pattern, resilience
    ui-design.md                        # taste-skill ecosystem: page type → correct skill
    debug-intermittent.md               # intermittent / production-only / resource leak bugs
    prompts.md                          # copy-paste Claude Code prompts
    stacks/
      nodejs.md                         # Node.js/TypeScript concrete prompts
      python.md                         # Python/FastAPI concrete prompts
```

**Token usage (typical session):**

| Loaded | Tokens |
|---|---|
| SKILL.md | ~4,800 |
| + onboarding router | ~400 |
| + one branch file | ~500–1,500 |
| + one reference file | ~1,500–3,000 |
| **Typical total** | **~7,000–10,000** |

---

## Roadmap

- [x] 6 onboarding branches (new / feature / bug / refactor / resume / incident)
- [x] MVP mode vs production mode
- [x] Complexity-based agent-skills activation (Tier S/M/L/XL)
- [x] Third-party API strategy (Adapter pattern + 3-layer testing)
- [x] taste-skill ecosystem mapping (page type → correct skill)
- [x] CLAUDE.md evolution guide (.claude/rules/ + compound engineering)
- [x] Conway's Law team growth signals
- [x] Update notifications via SessionStart hook
- [ ] Go stack file (`references/stacks/go.md`)
- [ ] CONTRIBUTING.md
- [ ] Plugin version with PreToolUse boundary enforcement hook

---

## License

MIT
