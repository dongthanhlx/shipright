# Product judgment — "is the need real?" (the other half of the executive question)

> shipright's executive question is: *"Is this a one-way door, **and is the need real today**?"*
> `judgment.md` owns the first half — how much to build, and when to stop.
> **This file owns the second — whether to build it at all, and how you'd know it mattered.**
> A veteran is defined by judgment; a veteran PM is defined by what they *didn't* build.

Load this file when:
- "Should this feature exist?" is a real question (Branch B Step 2b, and any "add X?" you can't answer)
- an outcome check came back NO or DON'T KNOW (Branch E Step 1b) — the diagnosis lives here
- you're writing or revising CLAUDE.md `## Outcome` and the signal isn't obvious
- the project has been shipping steadily and nobody can say what changed for anyone

Do **not** load it for: a bug fix, a config change, an explicit user request with obvious value, or
anything the user has already decided and reaffirmed. Interrogating the value of a 30-minute fix is
the same failure as over-architecting a landing page — judgment applied at the wrong altitude.

---

## 0. The asymmetry — why this file has to exist for an agent specifically

```
FEASIBILITY verifies itself.  You build the thing; the build either works or it doesn't.
                              The proof arrives free, as a side effect of the work.
VALUE verifies nothing.       Nothing about a green test suite, a clean diff, or a successful
                              deploy reports on whether anyone needed it.
```

So "it works" *feels* complete after a build, and the missing half produces **no error**. This is why
value has to be asked **explicitly** — not because it's more important than correctness, but because
correctness announces itself and value doesn't. Everything below is a way of asking it on purpose.

---

## 1. The four big risks (Marty Cagan, *INSPIRED*) — shipright hard-covers one

Before you build, four risks must be addressed. They are not equally handled here:

| Risk | The question | Who can answer it | shipright's coverage |
|---|---|---|---|
| **Value** | Will they actually use it / pay for it? | only real users | **absent → this file** |
| **Usability** | Can they figure out how to use it? | users, watched | partial — `ui-design.md` (the floor), but a floor is not a test |
| **Feasibility** | Can we build it, with what we have? | engineers | **hard-covered** — the whole construction hemisphere |
| **Viability** | Does it work for the business — cost, legal, support, ops? | the business | **absent → §4** |

Cagan's actual point is about **timing**: kill all four *cheaply, in discovery, with prototypes*, before
anyone writes production code. shipright's default path kills feasibility by building and then finds out
about the rest. That order is backwards — and it's backwards in the expensive direction.

**Viability is the one solo builders skip most.** It rarely kills the idea; it kills the *shape*. Who
answers the support emails this feature generates? What does the API bill look like at 100 users, not 3?
Can you legally hold this data? None of these are architecture problems, and all of them change what you
build. Ask them once, out loud, before an integration that carries ongoing cost.

---

## 2. Output ≠ outcome (Melissa Perri, *Escaping the Build Trap*)

> The build trap: **measuring success by outputs rather than outcomes.** Cranking out features on
> schedule instead of against a customer need. The Product Kata's line: *fall in love with the
> problem, not the solution.*

```
OUTPUT   what you shipped         countable, immediate, always available    "the export button is live"
OUTCOME  what changed for someone slower, needs a signal, easy to skip      "they stopped keeping the
                                                                            parallel spreadsheet"
```

**The tell — and it is mechanical, not cultural:** a Shipright state whose `Next:` is always another
feature. Ten features shipped, every quality gate passed, nothing measurably different. This is why the
outcome loop is structural in shipright rather than advice: `## Outcome` holds the signal, `Last shipped`
carries the pending check, Branch E Step 1b asks it *before* `Next`. See `judgment.md` §3b.

---

## 3. The riskiest assumption — the product version of the one-way door (Teresa Torres)

shipright already reasons this way about *technical* decisions. Point the same reasoning at the bet:

```
TECHNICAL  "if this is wrong, what does fixing it cost — an afternoon, or a migration?"
PRODUCT    "if this belief is wrong, what was the whole build worth — a little less, or nothing?"
```

An assumption whose failure makes the work **pointless** is a product one-way door, and it deserves the
same treatment: get it right before building on top. The difference is that you can't get it right by
thinking harder — you get it right by testing it. Torres's chain: outcome → opportunity → solution →
**assumption test**, testing the riskiest belief first, and *stopping or pivoting when a test disproves it*.

**Finding it:** list what must be true for this to matter, then ask which one you have the least evidence
for. It is almost always about the **user** (do they have this pain, will they change behavior), not about
the tech — the tech assumptions are the ones building will verify for you anyway.

**Testing it — the ladder, cheapest first. Stop at the first rung that answers:**
```
1. Ask one real user about their CURRENT behavior — what they do today, not what they'd do.  (minutes)
   The Mom Test: their world and their past, never your solution or their prediction.
2. Look at what already exists — the spreadsheet, the Slack thread, the manual workaround they
   built. A workaround is the strongest possible evidence of a real job.                      (minutes)
3. Do it manually for one user, by hand, before automating any of it.                          (hours)
4. Build the walking skeleton and put it in front of 3 people.                                  (days)
```
A/B tests, cohort analysis and funnels are **not** on this ladder — those need traffic you don't have.
At MVP scale, one honest conversation beats any number you could compute.

**The rule that makes it a test:** it must be able to come back **NO**. If no possible result would
change what you do, you're not testing — you're collecting reassurance, and you should skip it and build.

---

## 4. The value fork — "should this exist?" (Branch B Step 2b, expanded)

Four questions. Ask them in the user's words, not as a form:

```
1. WHICH OUTCOME does this serve?  (CLAUDE.md ## Outcome)
   → serves it → good, proceed to sizing.
   → serves none → it's not automatically wrong; it may be a NEW outcome. Say that out loud:
     "this doesn't serve [current outcome] — is it a new direction, or a detour?" A project with
     three unrelated outcomes and one developer has a focus problem, not a backlog problem.

2. What happens if we DON'T build it?  (the cost of NOT — Reinertsen's cost of delay, asked
   as a question rather than computed as a number)
   → "we lose X" / "Y stays broken"  → real. build it.
   → "nothing much, it'd just be nice" → THAT IS THE ANSWER. Log it, don't build it.
   This single question kills more unnecessary work than any scoring framework, and costs 10 seconds.

3. What's the CHEAPEST thing that would tell us it's worth building?  (§3 ladder)
   Ask it when the build is expensive AND the value is unproven. If the build is a day and the
   test is a day, skip the test and build — the build IS the cheapest test. Say so and move.

4. What are we NOT building by building this?  (opportunity cost — Shreyas Doshi)
   The real cost of a feature is never its effort; it's the thing that didn't get built. Name the
   runner-up explicitly. If the runner-up is obviously better, you just saved the sprint.
```

**Routing the outcome of the fork:**
```
Clear value + reasonable effort         → build it. Don't add ceremony to an easy yes.
Clear value + expensive                 → cut SCOPE to the load-bearing part (judgment.md §3b),
                                          not the quality floor. Ship the smaller complete thing.
Unproven value + cheap                  → build it. The build is the test. Ship it and check §2.
Unproven value + expensive              → STOP. This is the only quadrant that must not proceed.
                                          Run the §3 test first. This quadrant is where projects die.
User already decided and reaffirmed it  → build it. State your concern once, then go. Repeating
                                          the objection isn't judgment, it's friction.
```

---

## 5. The strategy kernel (Rumelt · Will Larson) — CLAUDE.md is a guiding policy missing its diagnosis

Rumelt: a real strategy has a **kernel** — *diagnosis → guiding policy → coherent action*. The #1 cause
of bad strategy is a weak diagnosis; the #2 is **confusing a goal with a strategy** ("increase sales 20%"
is a goal — it names no obstacle and no approach). Larson's engineering version runs the same spine:
explore → **diagnose** → refine → **set policy** → operate.

**shipright is closer to this than it looks — it already produces two of the three parts:**

```
DIAGNOSIS        what is actually in the way?              → MISSING. `## Project` is a goal
                                                             statement; `## Outcome` names the
                                                             change but not the obstacle.
GUIDING POLICY   the approach that constrains choices      → the 5 boundaries · the mode
                                                             (Validation/Foundation) · the one-way
                                                             doors. Already a real policy.
COHERENT ACTION  the steps that carry out the policy       → ARCHITECTURE.md · ADRs · the tech-debt
                                                             log with triggers · the lifecycle spine.
```

So the cheap fix, when a project has genuine direction ambiguity, is **one line of diagnosis** in
CLAUDE.md above `## Outcome`: *"The real obstacle is [X]"* — the thing that, unaddressed, makes every
feature fail to land. Not the goal restated. Not a list of problems. The one barrier.

**When to bother:** only when direction is genuinely unclear, or the same kind of work keeps failing to
produce results. A weekend script has no strategy problem, and writing a kernel for one is exactly the
over-application `judgment.md` §5 warns about. **Bad-strategy tells worth catching:** a roadmap that is
a feature list; a goal presented as a plan; "and also" objectives that don't constrain each other.

---

## 6. What this file deliberately does NOT do — recorded so it isn't re-proposed

```
RICE · WSJF · Cost of Delay as a formula · Kano · MoSCoW
  Org-scale artifacts for triaging a backlog across teams with real traffic data. For a solo or
  small builder they are ceremony that produces a number nobody trusts — and a scoring rubric is
  exactly the over-engineering shipright warns about everywhere else. The useful residue is already
  §4: the cost of NOT, and opportunity cost, as questions.

Full opportunity solution trees
  Need a product trio and weekly customer interviews. The useful residue — the chain
  outcome → opportunity → solution → assumption test — is §3, as reasoning, not a diagram.

Amazon PR/FAQ (working backwards)
  The heavyweight version of "define the customer experience before building". The lightweight
  version is already Branch A Step 2a's playback, and CLAUDE.md `## Outcome` is its durable half.

Pre-mortems as a standing ritual
  Already covered where it fires: Branch A surfaces "the risk I see", and §3 asks what belief being
  wrong makes this pointless. That IS the pre-mortem, at the moment it's useful.
```

The gap this file fills was never a shortage of frameworks. It was that **nothing ever asked whether
the thing was worth building, and nothing ever came back to find out.**
