# Stack Reference: Go

Use these concrete names when SKILL.md says generic terms.
Go is not class-based: a **module is a package**, the **public API is its exported identifiers**,
and **dependency injection is constructor functions**. Two Go features map directly onto shipright
boundaries — lean on them.

## Mapping: generic → Go specific
```
module / bounded context → a package (one directory)
public boundary          → exported identifiers (Capitalized) in the package
private internals        → unexported (lowercase) + the internal/ directory (compiler-enforced)
schema validation        → go-playground/validator OR explicit checks in a constructor
test runner              → go test ./... (stdlib testing, table-driven) + testify for asserts
build check              → go build ./...   and   go vet ./...
http server              → net/http (stdlib, idiomatic) or chi; handlers stay thin
db client                → pgx (pgxpool) + sqlc (type-safe queries from SQL) — avoid ORM magic
migration tool           → goose or golang-migrate (SQL files)
http client              → &http.Client{Timeout: ...} (NEVER http.DefaultClient — no timeout)
structured logging       → log/slog (stdlib, structured JSON)
config / env validation  → envconfig OR parse + validate in one func at startup (fail fast)
dependency injection     → constructor funcs NewXxx(deps...) wired in cmd/<app>/main.go
cancellation / timeout   → context.Context threaded through every call (first arg)
```

## Two boundaries Go enforces for you

```
Boundary 1 (no deep imports) → put module internals under internal/. The Go compiler FORBIDS any
  package outside the internal/ parent from importing it. This is stronger than the v0.9 hook —
  it's a compile error, not a lint. Expose the public API from the package root.
    internal/orders/         ← package orders (the public API: NewService, Order, Repository)
    internal/orders/store/   ← internal/, only orders/ may import it
  Cross-package calls import the package ("…/internal/orders"); you physically cannot reach inside.

Boundary 2 (service never touches db) → the service holds a Repository INTERFACE (defined in the
  consumer package — Go interfaces are implicit). Only the repository implementation imports pgx.
  Grep guard: a service file importing pgx/database/sql is the violation.
```

> Note: the v0.9 `boundary-guard.sh` hook targets TS/JS/Python file conventions (`*.service.ts`,
> `shared/db`). In Go, the `internal/` directory gives you compile-time Boundary 1 enforcement for
> free; use the grep checks below for Boundary 2.

## Framework — pick a default, keep it at the edge

Go rewards small, explicit code — the stdlib is enough for most services. The domain never imports
the router, so it stays a TWO-WAY door (swappable). Recommend, don't over-frame.
```
Default: net/http (stdlib, idiomatic) + chi — a lightweight router/middleware, no lock-in.
Gin / Echo — when you want batteries (binding, validation, middleware) and accept the dependency.
Avoid heavy "enterprise" frameworks — they fight Go's grain.
```
Confine it to the handler layer; internal/ domain packages never import the router. (This is also
why Go's internal/ + boundary discipline makes the framework trivially swappable — evolutionary-architecture.md.)

## Project init prompt
```
Read CLAUDE.md and ARCHITECTURE.md.
Create a Go project skeleton:
- go.mod (module path), Go 1.22+
- cmd/<app>/main.go: the composition root — construct repos, services, handlers, wire HTTP
- internal/<module>/ per module: domain.go (types + invariant methods), service.go
  (Service struct + Repository interface, methods take context.Context), handler.go (thin HTTP)
- internal/<module>/store/: Repository implementation (pgx) — the ONLY place importing pgx
- internal/platform/: db (pgxpool), logger (slog), httpclient (http.Client with Timeout)
- config/config.go: load + validate env once at startup, return error (fail fast)
- Every method that does I/O takes ctx context.Context as its first argument
- Stubs return errors.New("not implemented")
Gate: go build ./... and go vet ./... must pass.
```

## Error handling (Go idioms — explicit, no exceptions)
```go
// internal/platform/apperr/apperr.go — taxonomy via sentinel + typed errors
var (
    ErrNotFound = errors.New("not found")   // operational, expected
    ErrConflict = errors.New("conflict")    // operational (e.g. duplicate)
)

type ValidationError struct{ Field, Msg string }     // operational → 400/422
func (e *ValidationError) Error() string { return e.Field + ": " + e.Msg }

type GatewayError struct{ Err error }                // infrastructure → 502 + alert
func (e *GatewayError) Error() string { return "payment gateway: " + e.Err.Error() }
func (e *GatewayError) Unwrap() error { return e.Err }

// Wrap as it propagates so the cause survives:  fmt.Errorf("charge order %s: %w", id, err)
// Classify ONCE at the HTTP edge (handler) — services never know HTTP:
//   errors.Is(err, ErrNotFound)        → 404
//   var ve *ValidationError; errors.As(err, &ve) → 400
//   var ge *GatewayError;    errors.As(err, &ge) → 502 + log/alert
// A declined payment is OPERATIONAL (don't retry); a gateway timeout is INFRASTRUCTURE (retry).
```

## Boundary 5 — context timeouts on every outbound call (the resilience hemisphere)
```go
// Outbound HTTP / DB / RPC must be bounded. context.WithTimeout is the Go idiom for Boundary 5.
ctx, cancel := context.WithTimeout(ctx, 4*time.Second)
defer cancel()
row := pool.QueryRow(ctx, "SELECT ...", id)        // DB call is cancelled at 4s, never hangs
resp, err := s.http.Do(req.WithContext(ctx))       // http.Client also has its own Timeout set

// Retry only transient errors, with backoff+jitter; never retry a context deadline blindly.
// Idempotency keys live in the DB (see below) so a retry after a timeout never double-charges.
// See references/resilience.md for the full 8 stability patterns.
```

## Idempotency pattern (Go + PostgreSQL/pgx)
```go
// Cron / worker: advisory lock prevents overlapping runs (lost on restart? no — it's in PG)
func runWithLock(ctx context.Context, pool *pgxpool.Pool, lockID int64, fn func() error) error {
    var got bool
    if err := pool.QueryRow(ctx, "SELECT pg_try_advisory_lock($1)", lockID).Scan(&got); err != nil {
        return err
    }
    if !got { slog.Warn("job already running, skipping", "lock", lockID); return nil }
    defer pool.Exec(ctx, "SELECT pg_advisory_unlock($1)", lockID)
    return fn()
}

// API mutation: idempotency key as a unique column.
//   INSERT INTO orders (..., idempotency_key) VALUES (..., $1)
//   ON CONFLICT (idempotency_key) DO NOTHING RETURNING id;
// Empty result → the key was seen → load and return the existing row. Never an in-memory map.
```

## Boundary checks (run before every commit)
```bash
go build ./...                 # compiles — and internal/ violations fail HERE (Boundary 1)
go vet ./...                   # catches a class of real bugs
golangci-lint run              # if installed: staticcheck, errcheck, etc.
go test ./...                  # table-driven tests; -race on anything concurrent

# Boundary 2 — a service must not import the DB driver directly:
grep -rEn "jackc/pgx|database/sql" internal/*/service.go && echo "VIOLATION: service imports db driver"

# Boundary 5 — outbound HTTP without a timeout (a common Go production outage):
grep -rn "http.DefaultClient\|http.Get(" internal/ && echo "WARNING: unbounded HTTP call — set a Timeout/ctx"
```

## Concurrency note (Go-specific)
```
Go makes concurrency easy and data races easy too. Two rules:
- Run `go test -race ./...` in CI on anything with goroutines.
- Share memory by communicating (channels) OR protect it with a sync.Mutex — never both ad hoc.
- A goroutine that outlives its request leaks. Always give long-lived goroutines a ctx to stop.
```

---

## Security — top Go pitfalls (see references/security.md for the spine)

Go is memory-safe and its stdlib defaults are good — but two footguns are easy to hit:

```
A05 Injection
  ✗ text/template rendering HTML → XSS (text/template does NOT escape)
  ✓ html/template — it auto-escapes contextually (HTML/JS/URL). Use it for anything a browser renders.
  ✗ fmt.Sprintf("... WHERE id = %s", id) into a query → SQLi
  ✓ db.QueryContext(ctx, "... WHERE id = $1", id)   // parameterized / sqlc-generated
  ✗ exec.Command("sh", "-c", userInput) → command injection
  ✓ exec.CommandContext(ctx, "convert", userFile)   // no shell, args separated

A01 Broken Access Control
  ✓ Authorize in the service, every request, deny-by-default. Middleware authenticates; the domain authorizes.

Other
  ✓ Secrets from env/secret store — never in code or logs (slog: don't log the struct with the token).
  ✓ http.Server: set ReadHeaderTimeout (Slowloris/DoS); validate + bound request bodies.
  ✓ Passwords: golang.org/x/crypto/bcrypt or argon2 — never a bare hash.

A03 Supply chain
  ✓ commit go.sum; run `govulncheck ./...` in CI (official Go vuln scanner); minimal deps.
```

Boundary check:
```bash
grep -rEn "text/template" internal/ && echo "review: use html/template for browser output (XSS)"
grep -rEn "fmt\.Sprintf.*(SELECT|INSERT|UPDATE|DELETE)|exec\.Command\(\"sh\"" internal/ && echo "review: injection surface"
```

---

## Ubiquitous Language for this stack

Define domain terms in CLAUDE.md BEFORE naming any package, type, or function.
Claude will use these terms for all generated code in this project.

Go-specific naming: the package name IS part of the name — avoid stutter.
- package `orders` + type `OrderService` → call it `orders.Service` (not `orders.OrderService`)
- `DataProcessor` → `FeedNormalizer` (domain term)
- `utils` / `helpers` / `common` packages → banned; name by what they own (`apperr`, `httpx`)

Add to CLAUDE.md:
```markdown
## Ubiquitous Language
| Term | Meaning | Not |
|---|---|---|
| [your term] | [precise definition] | [generic alias Claude would default to] |
```
