# Security — the architectural spine (where security lives, and why)

> shipright owns **WHERE security lives in the architecture** and **WHY** (the design principles +
> which layer/boundary stops which threat). It does NOT re-implement how-to depth — for that,
> dispatch to `addyosmani/agent-skills: security-and-hardening` (activate the moment auth / payments
> / untrusted input appears — see registry trigger index).
>
> **Reviewing the actual diff is `/security-review` — bundled with Claude Code, free, always available.**
> Design principles do not catch what got written; run it on the change whenever this file applies, and
> never tell the user to install something for a review they already have. Design here → review there.
>
> Masters: **Saltzer & Schroeder** (1975 — the 8 timeless design principles); **OWASP** (Top 10
> 2025, API Security Top 10, ASVS, Cheat Sheet Series); **Adam Shostack** (threat modeling). For AI:
> **Simon Willison + OWASP LLM Top 10** (mcp.md / ai-agent.md). For smart contracts: Trail of Bits /
> OpenZeppelin (blockchain.md).

Load this at L0 for anything with auth, payments, PII, or untrusted input — and whenever the
`security-and-hardening` trigger fires.

---

## 1. Saltzer & Schroeder — the 8 principles (still true 50 years on)

```
Least privilege        — every component gets the minimum access it needs. Nothing ambient/global.
Fail-safe defaults     — deny by default; access is granted explicitly, never assumed. (A01)
Economy of mechanism   — keep the security-critical path small and simple enough to audit.
Complete mediation     — check EVERY access, every time — not just the first. No trusted shortcuts. (A01)
Open design            — security must not depend on secrecy of the design, only of the keys. (A04)
Separation of privilege— require more than one condition for sensitive actions (2FA, dual control).
Least common mechanism — don't share state/resources across trust boundaries (bulkheads — resilience.md).
Psychological acceptability — the secure path must be the easy path, or people route around it.
```
These are the "why" behind every rule below. When a control feels arbitrary, name the principle.

## 2. Threat model in one pass (Adam Shostack's 4 questions)

Do this at L0 for any sensitive feature — 30 minutes, not a ceremony:
```
1. What are we building?      → the data flow diagram you already have in ARCHITECTURE.md.
2. What can go wrong?          → walk each trust boundary (STRIDE: Spoofing, Tampering, Repudiation,
                                 Info disclosure, DoS, Elevation of privilege).
3. What are we going to do?    → a control per real threat (not per imagined one — judgment.md).
4. Did we do a good job?       → a test per control. Security controls without tests decay.
```
This is A06 Insecure Design: the cheapest vulnerability to fix is the one you designed out at L0.

---

## 3. OWASP Top 10 (2025) → where shipright's architecture stops it

shipright's boundaries already buy several of these structurally. Map the threat to the layer that owns it:

| OWASP 2025 risk | Owned by | The control |
|---|---|---|
| A01 Broken Access Control | **Service layer** | Authorize in the domain, on every request (complete mediation). Deny by default. #1 real-world breach. |
| A02 Security Misconfiguration | config/ + deploy | Fail-fast env validation (zod/pydantic); no debug in prod; secure headers; least-privilege infra. |
| A03 Software Supply Chain | build/CI | Lockfiles, pin versions, per-language audit (below), minimal deps. Newly elevated — take seriously. |
| A04 Cryptographic Failures | shared/ + adapter | TLS everywhere; hash passwords (argon2/bcrypt); no home-rolled crypto; secrets in a vault, not code. |
| A05 Injection | **Handler + Repository + Adapter** | Validate at the boundary; parameterized queries only; output-encode; never build SQL/HTML/shell from input. |
| A06 Insecure Design | **L0 / threat model** | The Shostack pass above. Boundaries + ACL are design-level controls. |
| A07 Authentication Failures | Handler + shared/auth | Strong session/JWT handling, rate-limit login, MFA for sensitive; don't invent auth. |
| A08 Software/Data Integrity | CI + adapter | Verify signatures/webhooks; no untrusted deserialization; SRI; signed artifacts. |
| A09 Logging & Alerting Failures | **observability.md** | Structured logs + alerts; audit sensitive actions; NEVER log secrets/PII. |
| A10 Mishandling Exceptional Conditions | **error-handling.md + resilience.md** | Error taxonomy; fail safe not open; timeouts/circuit breakers (Boundary 5). New in 2025 — shipright already covers it. |

Key insight: **Boundary 4 (Adapter/ACL)** isolates injection + SSRF at the edge; **Boundary 5** + the
error taxonomy cover A10; **least privilege + fail-safe defaults** are the spine of A01/A07.

---

## 4. The controls shipright always insists on

```
Secrets      — never in source, logs, error messages, tool args, or client code. Env/secret manager
               only. Rotate on exposure. (Ties to observability.md "never log" list + A04.)
AuthZ        — access control is a SERVICE-layer decision, enforced on every call, deny-by-default.
               A handler authenticates (who are you); the service authorizes (may you do this). (A01)
Input        — untrusted until validated at the boundary (zod/pydantic/validator). The model/user/
               tool/webhook/retrieved-doc are all input. Parameterized queries, always. (A05)
Supply chain — lockfile committed; pinned versions; scanner in CI; minimal dependency surface. (A03)
Transport    — TLS for everything; HSTS; secure+httpOnly+sameSite cookies. (A04/A07)
Fail safe    — on error, deny/close, don't open. Timeouts + circuit breakers. (A10 + resilience.md)
```

## 5. Per-language injection & supply-chain pitfalls (what Claude gets wrong)

The deep per-stack lists live in each stack file's Security section. The cross-cutting essentials:

```
Node.js  — child_process.exec(userInput) → command injection (use execFile + args array).
           eval / new Function on input; prototype pollution (guard __proto__); JWT alg "none".
           Supply chain: npm audit / socket.dev; commit package-lock.json; avoid postinstall-heavy deps.
Python   — SQLAlchemy text(f"...{x}") / raw % SQL → SQLi (bind params). pickle/yaml.load on untrusted
           input → RCE (use yaml.safe_load, never pickle untrusted). subprocess(shell=True); jinja2
           autoescape off. Supply chain: pip-audit / Bandit (SAST); pin in requirements/uv.lock.
Go       — text/template for HTML → XSS (use html/template — it auto-escapes contextually).
           fmt.Sprintf into SQL → SQLi (use parameterized database/sql / sqlc). os/exec with a shell.
           Supply chain: govulncheck; go.sum committed; minimal-version selection.
Desktop  — see desktop.md §4: secrets at rest on the user's disk (OS secret store + envelope, and say
           honestly it doesn't stop same-user malware); unsigned exe/updates; running elevated; DLL
           planting from user-writable dirs; tokens and cookies leaking into support-bundle logs.
Browser  — see browser-extension.md: content script trusts a hostile DOM; innerHTML XSS; chrome.storage
           is NOT encrypted; validate message sender; MV3 forbids remote code — keep it that way.
```

---

## 6. When it's beyond shipright (graduate — don't fake it)

```
Compliance: SOC2 / PCI-DSS / HIPAA / GDPR  → specialized skills + human legal/security review.
Pen testing, red team, formal audit         → hire it. shipright's guidance is not an audit.
Cryptography design (not use)               → consult a cryptographer. Use vetted libraries; never invent.
Smart contract mainnet                      → professional audit is mandatory (blockchain.md).
```
shipright makes the architecture secure-by-structure and catches the common mistakes. It is not a
substitute for a security professional on high-stakes systems. Say so.

---

## Add to CLAUDE.md when security matters

```markdown
## Security conventions
- AuthZ in the service layer, every request, deny-by-default (A01 — least privilege, complete mediation).
- All input validated at the boundary; parameterized queries only; never build SQL/HTML/shell from input.
- Secrets in [vault/env] only — never in code, logs, errors, or client. Rotate on exposure.
- Supply chain: lockfile committed; [pip-audit/npm audit/govulncheck] runs in CI; deps pinned.
- Fail safe: on error, deny/close; timeouts + circuit breakers on every integration point (Boundary 5).
- Threat model (Shostack 4 questions) recorded in ARCHITECTURE.md for [auth/payments/PII] flows.
- [Trigger] security-and-hardening skill active for: [auth / payments / untrusted input].
```
