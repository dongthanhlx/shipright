# shipright

> Build any software project like a senior engineer.

A Claude Code skill that guides developers through structured, testable, scalable software — from empty folder to production-ready codebase. Works for new projects and existing codebases. Any stack.

```
/shipright
```

---

## What it does

Asks one question first, then loads only what's needed:

| You say | shipright does |
|---|---|
| New project | Intake → L0 contract → L1 skeleton → L2 interfaces → L3 implement |
| Add a feature | Read codebase → health check → implement safely |
| Fix a bug | Classify → reproduce → locate → root cause → fix |
| Refactor | Define done → characterization tests → atomic steps |
| Resume after break | Git orient → find last position → next action |
| Production incident | Triage → mitigate → investigate → post-incident |

---

## Install

**Personal** — works across all your projects:
```bash
mkdir -p ~/.claude/skills
git clone https://github.com/[username]/shipright ~/.claude/skills/shipright
```

**Project-scoped** — commit it so the whole team gets it:
```bash
mkdir -p .claude/skills
git clone https://github.com/[username]/shipright .claude/skills/shipright
git add .claude/skills/shipright
git commit -m "chore: add shipright skill"
```

Restart Claude Code. The skill loads automatically.

---

## The 4-level tree

shipright follows a strict level sequence — never skip, never go back:

```
L0  Contract      CLAUDE.md + ARCHITECTURE.md  (before any code)
L1  Skeleton      project compiles, runs, no logic
L2  Interfaces    all layers defined, tests written (RED)
L3  Implement     one feature at a time, tests GREEN
L4  Harden        only when production signals demand it
```

Each level has a gate. You only move forward when the current level passes.

---

## Example output

See what good L0 output looks like:
- [`references/examples/news-crawler-CLAUDE.md`](references/examples/news-crawler-CLAUDE.md)
- [`references/examples/news-crawler-ARCHITECTURE.md`](references/examples/news-crawler-ARCHITECTURE.md)

---

## Token usage

shipright uses progressive disclosure — loads only what the current task needs.

| What's in context | Tokens |
|---|---|
| SKILL.md (always) | ~4,800 |
| Onboarding router | ~400 |
| One branch file | ~500–1,200 |
| One reference file | ~1,500–3,000 |
| **Typical session** | **~7,000–9,500** |

---

## Supported stacks

| Stack | Prompts | Error hierarchy | Boundary checks |
|---|---|---|---|
| Node.js + TypeScript | ✓ | ✓ | ✓ |
| Python + FastAPI | ✓ | ✓ | — |
| Others | Principles apply | Adapt from examples | — |

Want your stack added? [Open an issue](../../issues/new?template=new-stack.md).

---

## Structure

```
shipright/
  SKILL.md                              # brain (~4,800 tokens)
  CHANGELOG.md
  references/
    onboarding.md                       # thin router (~400 tokens)
    branches/
      a-new-project.md                  # load on [A]
      b-add-feature.md                  # load on [B]
      c-fix-bug.md                      # load on [C]
      d-refactor.md                     # load on [D]
      e-resume.md                       # load on [E]
      f-incident.md                     # load on [F]
    examples/
      news-crawler-CLAUDE.md            # real output example
      news-crawler-ARCHITECTURE.md      # real output example
    levels.md                           # L0→L4 detailed definitions
    l0-templates.md                     # CLAUDE.md + ARCHITECTURE.md templates
    prompts.md                          # copy-paste Claude Code prompts
    boundaries.md                       # the 3 boundary rules
    requirement-drift.md                # when architecture must change
    debug-intermittent.md               # intermittent/production-only bugs
    stacks/
      nodejs.md
      python.md
```

---

## Roadmap

- [x] 6 onboarding branches (new / feature / bug / refactor / resume / incident)
- [x] Real output examples
- [x] Node.js + Python stack files
- [ ] Go stack
- [ ] Plugin version with PreToolUse boundary enforcement hook
- [ ] Community stack contributions

---

## Contributing

PRs welcome. Most useful contributions:
- New stack files (`references/stacks/[lang].md`)
- Better example projects
- Bug reports when shipright gives wrong guidance

---

## License

MIT
