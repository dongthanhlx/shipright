# Registry pack — web-api

> One project-type pack. Load it together with the trigger index in `references/registry.md`,
> never the other packs. Install names, commands and the consent rule: registry.md §Install recipes.

HTTP REST API, GraphQL, or backend service. No AI components.

```
install:
  required:
    - addyosmani/agent-skills
      skills: [incremental-implementation, test-driven-development, code-review-and-quality]
      when: traction stage
    - addyosmani/agent-skills
      skills: [spec-driven-development, security-and-hardening]
      when: growth stage
  optional:
    - addyosmani/agent-skills
      skills: [api-and-interface-design]
      when: external consumers exist
  mvp-only:
    - addyosmani/agent-skills
      skills: [debugging-and-error-recovery]
      when: always

tested-with: addyosmani/agent-skills commit 2025-06
load: references/stacks/<language>.md — the project's language file (Node/Python/Go/PHP): compile-time
      boundary enforcement, timeout/context idioms, error taxonomy, language security footguns.
      Load it before the first implementation, not just at scaffold time.

shipright-adds-to-CLAUDE:
  boundary-1: "Service never imports db — grep check: grep -r 'shared/db' src/modules/ must be empty"
  boundary-2: "Handler zero domain if/else — only parse → call service → format"
  debt-signals:
    - "TODO[rps>500]: add Redis caching layer"
    - "TODO[p95>200ms]: add query index + connection pool"
    - "TODO[team>5]: add module ownership matrix"
  clean-code:
    - "Functions max 20 lines. Files max 300 lines."
    - "Names reveal intent. No Manager, Handler, Utils when domain term exists."
```
