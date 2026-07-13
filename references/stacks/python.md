# Stack Reference: Python (FastAPI recommended — see Framework)

## Mapping: generic → Python specific
```
public boundary file    → __init__.py (explicit exports with __all__)
schema validation       → pydantic v2
test runner             → pytest + pytest-asyncio
build check             → mypy --strict
http validation         → pydantic BaseModel
db client               → SQLAlchemy 2.0 async + asyncpg
migration tool          → alembic
http client             → httpx (with retry via tenacity)
structured logging      → structlog
env validation          → pydantic BaseSettings
scheduler               → APScheduler or celery beat
```

## Framework — pick a default, keep it at the edge

Recommend, don't assume. The domain/service/repository never import the framework → it stays a
TWO-WAY door (swappable — judgment.md + references/evolutionary-architecture.md).
```
Default: FastAPI — async, typed, DI via Depends, OpenAPI free. Best for APIs (this file's examples use it).
Django — batteries-included (admin, ORM, auth, migrations); content/CRUD-heavy apps or fast internal tools.
Flask / Litestar — micro / full control (Litestar = modern, typed, DI — a strong FastAPI alternative).
```
Keep it at the router layer; services/repositories are framework-free. A domain that imports FastAPI,
or a model that subclasses `django.db.models.Model`, is a Boundary-2/4 violation that welds you to the framework.

## Project init prompt
```
Read CLAUDE.md and ARCHITECTURE.md.
Create Python + FastAPI project skeleton:
- pyproject.toml: python 3.12+, dependencies listed
- mypy.ini: strict = True
- pytest.ini: asyncio_mode = auto, cov-fail-under = 80
- Each module: __init__.py (explicit __all__), types.py (Pydantic models), [name]_service.py (stub — raises NotImplementedError)
- shared/: db.py (SQLAlchemy async engine), logger.py (structlog), errors.py (exception hierarchy), http_client.py (httpx with tenacity retry)
- config/settings.py: pydantic BaseSettings, fails on startup if required vars missing
- docker-compose.yml: app (python:3.12-slim) + postgres:16
Gate: mypy --strict src/ must pass with zero errors.
```

## Error hierarchy (Python)
```python
# shared/errors.py
class AppError(Exception):
    def __init__(self, message: str, code: str):
        super().__init__(message)
        self.code = code

class DomainError(AppError): pass
class ValidationError(DomainError): http_status = 400
class NotFoundError(DomainError): http_status = 404
class ConflictError(DomainError): http_status = 409
class ForbiddenError(DomainError): http_status = 403

class InfrastructureError(AppError): pass
class DatabaseError(InfrastructureError): http_status = 503
class ExternalAPIError(InfrastructureError): http_status = 502
```

## Module structure (Python)
```
src/modules/orders/
  __init__.py          # exports: OrderService, IOrderRepository, Order
  types.py             # Pydantic models: Order, CreateOrderDTO
  service.py           # class OrderService
  repository.py        # Protocol IOrderRepository + class OrderRepository
  router.py            # FastAPI APIRouter (thin: parse → service → format)
  service_test.py      # pytest, mock IOrderRepository with unittest.mock
```

---

## Security — top Python pitfalls (see references/security.md for the spine)

The mistakes Claude makes most in Python, with the safe pattern. Grounded in OWASP + Bandit's rules.

```
A05 Injection
  ✗ session.execute(text(f"SELECT * FROM u WHERE id = {id}"))   → SQLi
  ✓ session.execute(text("SELECT * FROM u WHERE id = :id"), {"id": id})   // bind params
    (or use the SQLAlchemy ORM / typed query — never f-string SQL)
  ✗ subprocess.run(cmd, shell=True) with input; os.system(...)  → command injection
  ✓ subprocess.run(["convert", user_file], shell=False)          // args list, no shell

A08 Insecure deserialization (RCE)
  ✗ pickle.loads(untrusted) ; yaml.load(untrusted)               → arbitrary code execution
  ✓ never unpickle untrusted data; yaml.safe_load(...) only; prefer JSON/pydantic for input.

A01 Broken Access Control
  ✓ Authorize in the SERVICE, every request, deny-by-default. FastAPI Depends() for the auth
    principal, but the AUTHZ decision belongs in the domain — not just a route decorator.

A05 Template / SSRF
  ✗ Jinja2 with autoescape disabled → XSS.   ✓ keep autoescape ON.
  ✗ httpx.get(user_url) → SSRF.   ✓ allow-list host/scheme; block private ranges (Boundary 4).

Other
  ✓ Passwords: argon2/bcrypt (passlib) — never sha256/plain.
  ✓ Secrets via pydantic BaseSettings from env — never hardcoded; never logged (structlog processors).
  ✓ Validate every request body with a Pydantic model at the router boundary.

A03 Supply chain
  ✓ pin (requirements.txt hashes / uv.lock); `pip-audit` + `bandit -r src/` in CI.
```

Boundary check:
```bash
grep -rEn "shell=True|os\.system|pickle\.loads|yaml\.load\(|text\(f\"" src/ && echo "review: injection/deser surface"
```

---

## Ubiquitous Language for this stack

Define domain terms in CLAUDE.md BEFORE naming any class/function.
Claude will use these terms for all generated code in this project.

Common mistake: letting Claude default to generic names:
- `UserService` → should be `SubscriberEnrollmentService` (domain term)
- `DataProcessor` → should be `FeedNormalizer` (domain term)
- `ItemRepository` → should be `ArticleRepository` (domain term)

Add to CLAUDE.md:
```markdown
## Ubiquitous Language
| Term | Meaning | Not |
|---|---|---|
| [your term] | [precise definition] | [generic alias Claude would default to] |
```
