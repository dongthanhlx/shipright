# Stack Reference: Python + FastAPI

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
