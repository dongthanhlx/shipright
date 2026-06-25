## Branch B — Existing project, add feature

> Read CLAUDE.md and ARCHITECTURE.md FIRST. Check Shipright state section.
> Ubiquitous Language in CLAUDE.md → use those terms, not generic names.

---

## Step 0 — Check state & registry

If Shipright state exists in CLAUDE.md:
```
"Last session: [Level], [module], next: [action]. Work on that, or a new feature?"
```

If no state → intake:
```
Q1: "Project name and one sentence: what does it do?"
Q2: "Feature: 'User can [do what] to [achieve what]'"
Q3: "New module needed, or extend existing?"
```

If project type unknown → check registry for matching entry, load it.
Note any required skills not installed → mention once, then proceed.

---

## Step 1 — Read codebase (structured report)

```
Read without modifying. Report:

## Codebase report: [name]
Entry points:    [file → what it starts]
Module map:      [module] → [1-sentence job] → [depends on]
Data flow:       Request → [A] → [B] → [C] → Response
Ubiquitous Lang: [domain terms actually used in code vs CLAUDE.md list]
Drift:           [any generic names where domain term should be used]
Landmines:       [global state, tight coupling, boundary violations]
Feature touches: [which modules affected]
```

Domain term drift = immediate fix before new feature.
Generic `OrderManager` when `FulfillmentPolicy` exists in Ubiquitous Language → rename.

---

## Step 2 — Health check

```
TIER 1 — Blockers (fix before feature):
□ Boundary violations? (service imports db, module imports module internals)
□ Circular deps? (npx madge --circular src/)
□ Empty catch blocks swallowing errors?

TIER 2 — Warnings (proceed with care, document):
□ Tests covering touched modules?
□ File > 300 lines?
□ Function > 20 lines in area being changed?

Verdict: SAFE / TIER1-BLOCKER / TIER2-CAUTION
```

TIER1-BLOCKER effort > 20% deadline → workaround + TODO[fix-before-scale], proceed.

---

## Step 3 — Classify complexity

```
1 file, obvious change            → Tier S (trivial, < 30 min)
2–5 files, clear scope            → Tier M (simple, < 2 hrs)
5–10 files OR unclear reqs        → Tier L (complex, 2–8 hrs)
10+ files OR multiple devs        → Tier XL (system-level, days)
```

**Tier S — No external skills needed**
```
Shipright handles: implement → quality gate → commit
Exception: bug → always activate debugging-and-error-recovery if installed
```

**Tier M — TDD + review**
```
[addyosmani test-driven-development]: activate
[addyosmani code-review-and-quality]: activate before merge
[neither]: write test (RED) → implement → GREEN → quality gate
```

**Tier L — Spec first**
```
[addyosmani spec-driven-development]: activate FIRST, get approved
  → then: /build auto (incremental + TDD internally)
  → then: code-review-and-quality before merge
[not installed]:
  1. Write acceptance criteria explicitly (what is true when done)
  2. Break into subtasks ordered by dependency
  3. Implement one subtask → test → GREEN → commit
  4. Feature flag if incomplete work must merge
```

**Tier XL — Architecture update first**
```
1. Update ARCHITECTURE.md (module added/changed)
2. Note in Shipright state: "architecture updated for [feature]"
3. [addyosmani]: spec → planning → /build auto → security → review
4. Feature flag always
```

---

## Step 4 — Implement

**Extend existing module:**
```
[Tier M+] Write test (RED) before code — Outside-In TDD
Interface emerges from what test needs to call.
Implement inside-out: repository → service → handler
```

**New module:**
```
1. Update ARCHITECTURE.md: module name, job, public API, forbidden deps
2. Commit: "docs: add [module] to ARCHITECTURE.md"
3. Create module skeleton (index.ts + types.ts + stubs)
4. L2: define interface + write RED tests
5. L3: implement
```

---

## Step 5 — Quality gate (before every commit)

**Automated:**
```bash
grep -r "shared/db\|shared/database" src/modules/ # must be empty
npx tsc --noEmit 2>/dev/null || python -m mypy src/  # must pass
```

**DDD (Evans):**
- [ ] All new names from Ubiquitous Language in CLAUDE.md?
- [ ] New Entity has id + equals-by-id?
- [ ] New Value Object immutable (readonly / Object.freeze)?
- [ ] Repository interface in domain, implementation in infrastructure?

**SOLID (Uncle Bob):**
- [ ] Function > 20 lines? → extract with domain name
- [ ] AND/OR in function name? → split
- [ ] New type added by modifying existing switch? → new class instead
- [ ] Interface method no implementation uses? → split interface

**Fowler smells:**
- [ ] Feature Envy? (method uses another class's data more) → move it
- [ ] Primitive Obsession? (string/int where Value Object belongs) → create type
- [ ] Comment explaining WHAT? → rename instead

**Violation found:** fix → add specific rule to CLAUDE.md (compound engineering)
**Load** `references/code-quality.md` for fix guidance on specific violation.

---

## Step 6 — Update state

After feature complete, update CLAUDE.md Shipright state:
```markdown
## Shipright state
Level: L3
Active: [module just completed]
Next: [next feature or "validate with users"]
Last updated: [date]
```

---

## UI features

Load `references/ui-design.md` — page type → correct taste-skill variant.
Skip for: backend API, CLI, background jobs, dashboards (use vercel-labs instead).
