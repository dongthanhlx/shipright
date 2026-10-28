# Registry pack — full-stack-web

> One project-type pack. Load it together with the trigger index in `references/registry.md`,
> never the other packs. Install names, commands and the consent rule: registry.md §Install recipes.

Web app with frontend + backend (React/Next.js + API).

```
install:
  required:
    - addyosmani/agent-skills
      skills: [incremental-implementation, test-driven-development, code-review-and-quality]
  ui:
    - taste-skill (page-type dependent — read references/ui-design.md)
    - vercel-labs/agent-skills web-design-guidelines (for dashboard/admin pages)
  framework:
    - vercel-labs/agent-skills vercel-react-best-practices
      when: writing or reviewing React/Next.js code (this entry's default stack)
      why: shipright's performance.md is the measure-first LADDER (stack-agnostic); this is the
           React/Next execution detail — waterfalls, bundle size, server-vs-client, re-renders
  verification:
    - addyosmani/agent-skills browser-testing-with-devtools
      when: confirming the UI actually works/looks right (needs the chrome-devtools MCP server)

tested-with: React 18+, Next.js 14+, addyosmani 2025-06
load: references/stacks/nodejs.md (or the API's language file) for the SYSTEM floor, AND
      references/ui-design.md for the EXPERIENCE floor — a full-stack product owes both (judgment.md §5b)

shipright-adds-to-CLAUDE:
  frontend-boundary: "UI components never contain business logic. Data fetching in hooks/services only."
  api-boundary: [standard boundary rules 1-4 apply to API layer]
  ui-page-types:
    landing-portfolio: design-taste-frontend
    product-ui: minimalist-ui   # install name — the folder is minimalist-skill, which fails with --skill
    dashboard-admin: vercel-labs (NOT taste-skill)
    multi-step-forms: addyosmani/api-and-interface-design
  debt-signals:
    - "TODO[users>1000]: add CDN + static asset optimization"
    - "TODO[team>3]: add component documentation (Storybook)"
```
