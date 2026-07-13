# Stack Reference: PHP (8.3+)

Use these concrete names when SKILL.md says generic terms. Modern PHP is strongly typed in practice —
lean on it: `declare(strict_types=1)`, typed properties, enums, readonly, constructor promotion, and
**PHPStan/Psalm at max level** as your compile-time check (PHP has no compiler; static analysis is it).

## Mapping: generic → PHP specific
```
module / bounded context → a namespace + directory (PSR-4 autoload via composer)
public boundary          → the exported classes of a namespace; hide internals with `@internal` +
                           enforce with Deptrac (there is no compiler-enforced internal/ like Go)
schema validation        → Symfony Validator / Laravel FormRequest / webmozart/assert on DTOs
test runner              → PHPUnit or Pest (Pest = modern, expressive)
build/type check         → phpstan analyse (level max) OR psalm  ← this is your "does it compile"
http framework           → Symfony or Laravel; handlers/controllers stay thin
db client                → Doctrine ORM (Symfony) / Eloquent (Laravel) / PDO — never string-built SQL
migration tool           → Doctrine Migrations / Laravel migrations
http client              → Guzzle (+ retry middleware); set a timeout ALWAYS
structured logging       → Monolog (JsonFormatter)
config / env validation  → symfony/dotenv + validate required vars at boot (fail fast)
dependency injection     → the framework container; constructor injection (matches shipright's DI)
scheduler                → Symfony Scheduler/Messenger or Laravel scheduler (console command + cron)
boundary enforcement     → Deptrac — a fitness function for module boundaries (evolutionary-architecture.md)
```

## Framework — pick a default, keep it at the edge

Recommend with a reason; keep the framework in the controller/infrastructure layer so the domain
stays framework-free — a TWO-WAY door (swappable), so the choice is cheap to change (judgment.md +
references/evolutionary-architecture.md). shipright's boundaries work identically in either.
```
Laravel — default for most: speed, DX, ecosystem (Eloquent, queues, scheduler, Horizon). Product apps.
Symfony — when you want stricter architecture, decoupled components, and DDD rigor (Doctrine, Messenger).
Slim / Mezzio — micro / API-only, when you want minimal.
```
Confine Eloquent/Doctrine + the framework to the controller + Infrastructure layer; the domain and
services import NEITHER. A domain entity that extends `Model` (Eloquent) is a Boundary-2/4 violation
and welds you to the framework.

## Project init prompt
```
Read CLAUDE.md and ARCHITECTURE.md.
Create a PHP project skeleton (PHP 8.3+):
- composer.json: PSR-4 autoload (App\ → src/), require-dev phpstan/phpunit(or pest)/deptrac
- phpstan.neon: level max; every file declare(strict_types=1)
- src/Modules/<Module>/: domain (entities + value objects), Service, Repository interface, Controller (thin)
- src/Modules/<Module>/Infrastructure/: the Doctrine/Eloquent repository implementation (the ONLY DB code)
- src/Shared/: Logger (Monolog), HttpClient (Guzzle + timeout), exceptions (AppException hierarchy)
- config/: env loaded + validated at boot, throws on missing required var
- deptrac.yaml: layers (Controller → Service → Repository) + forbidden dependencies
Gate: phpstan analyse (level max) and the test suite must pass; deptrac has zero violations.
```

## Error hierarchy (PHP — exceptions)
```php
// src/Shared/Exception/AppException.php
abstract class AppException extends \Exception {
    public function __construct(string $message, public readonly string $code, private int $http) {
        parent::__construct($message);
    }
    public function httpStatus(): int { return $this->http; }
}
// Domain (operational — expected, 4xx)
final class ValidationException extends AppException {}      // 400/422
final class NotFoundException  extends AppException {}       // 404
final class ConflictException  extends AppException {}       // 409
// Infrastructure (our problem — 5xx + alert)
final class DatabaseException     extends AppException {}    // 503
final class ExternalServiceException extends AppException {} // 502
// Rule: Services throw these — Services have ZERO HTTP knowledge. The controller/handler maps
// exception class → status. A declined-but-expected case (quota, dedup) → return a Result-like
// value object, not an exception (Ousterhout: don't use exceptions for normal control flow).
```

## Idempotency pattern (PHP + PostgreSQL)
```php
// API mutation: idempotency key as a unique column.
//   INSERT ... ON CONFLICT (idempotency_key) DO NOTHING RETURNING id
// Empty result → key seen → load and return the existing row. Never an in-process static/array.
// Cron/worker overlap: pg_try_advisory_lock($id) at job start; release in a finally{}.
// Money: use brick/money or integer minor units — NEVER float, NEVER (int) casts on money strings.
```

---

## Security — top PHP pitfalls (see references/security.md for the spine)

PHP has a few footguns that cause most real breaches. Grounded in OWASP + the PHP security guide.

```
A05 Injection
  ✗ $db->query("SELECT * FROM u WHERE id = $id")           → SQLi
  ✓ prepared statement: $db->prepare('... WHERE id = ?')->execute([$id])   // or the ORM
  ✗ echo $userInput;  in a template                        → XSS
  ✓ Twig/Blade auto-escape ({{ }}); htmlspecialchars($x, ENT_QUOTES) if raw PHP
  ✗ shell_exec / exec / system with user input; eval($x)   → command / code injection

A08 Object injection (the classic PHP RCE)
  ✗ unserialize($untrusted)                                 → arbitrary object instantiation → RCE
  ✓ NEVER unserialize untrusted input. Use json_decode for external data. Avoid PHP serialization across trust boundaries.

A01 Broken Access Control + PHP-specific footguns
  ✗ Mass assignment: User::create($request->all())         → attacker sets is_admin=true
  ✓ Explicit allow-list: $fillable / DTO with named fields only. Never bind the whole request to a model.
  ✗ Loose comparison: if ($token == $expected)             → type juggling ("0e123"==0, 0=="abc" pre-8.0) → auth bypass
  ✓ hash_equals($expected, $token) for secrets; use === everywhere; strict_types=1.

A07 Auth  ✓ password_hash()/password_verify() (bcrypt/argon2) — never md5/sha1. CSRF tokens on state-changing forms.
A03 Supply chain  ✓ commit composer.lock; run `composer audit` in CI; avoid abandoned packages.
Secrets  ✓ from env only; never in code/logs. Disable display_errors in production.
```

Boundary check:
```bash
grep -rEn "unserialize\(|eval\(|shell_exec|\bexec\(|->all\(\)" src/ && echo "review: RCE / mass-assignment surface"
grep -rEn '\$(db|pdo)->query\(.*\$' src/ && echo "review: string-built SQL"
vendor/bin/deptrac analyse   # module-boundary fitness function — must be zero violations
```

---

## Ubiquitous Language for this stack

Name classes and namespaces in domain terms. PHP's `Manager`/`Handler`/`Helper`/`Util` habit is strong —
resist it: `FulfilmentPolicy`, not `OrderManager`; `Money`, not a bare int. Define the terms in CLAUDE.md
before writing code.

```markdown
## Ubiquitous Language
| Term | Meaning | Not |
|---|---|---|
| [your term] | [precise definition] | [generic alias Claude would default to] |
```
