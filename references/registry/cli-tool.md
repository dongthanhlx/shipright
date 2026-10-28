# Registry pack — cli-tool

> One project-type pack. Load it together with the trigger index in `references/registry.md`,
> never the other packs. Install names, commands and the consent rule: registry.md §Install recipes.

Command-line tool or script. Minimal architecture needed.

```
install:
  optional:
    - addyosmani/agent-skills
      skills: [test-driven-development]
      when: complex business logic exists

tested-with: Node.js 24 LTS, Python 3.13+
load: references/stacks/<language>.md — the CLI's language file. A CLI has no UI/UX floor but still
      owes the system floor when it grows past a script (judgment.md §5)

note: "CLIs rarely need full DDD/SOLID treatment. Flat functions are often correct."

shipright-adds-to-CLAUDE:
  minimal: "Single responsibility per command. Parse args → validate → execute → output."
  testing: "Test each command handler independently. Mock I/O."
  debt-signals:
    - "TODO[commands>10]: extract command registry pattern"
    - "TODO[shared-logic>3-commands]: extract shared service"
```
