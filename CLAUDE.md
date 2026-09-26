# CLAUDE.md — shipright (the skill repo itself)

## Git policy
Default branch: main — protected; never commit or push to it directly
Commit:   auto on feature branches at green (CI checks + hook self-test pass)
Push:     ask first
PR:       ask first (no `gh` here — give the compare URL + a ready title/body)
Merge:    always ask — the maintainer merges on GitHub
Strategy: merge commit (matches history) · Style: Conventional Commits, "type: vX.Y.Z — summary"
