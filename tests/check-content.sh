#!/usr/bin/env bash
# Content checks for the skill itself — the same script CI runs (validate.yml), so a local pass
# means a CI pass. Run from anywhere:  bash tests/check-content.sh
#
# Each check prints ✓ or the offending items, and the script exits non-zero if any check failed.
# Budgets below are a RATCHET: lower them when the core is slimmed, never raise them to make a PR pass.

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

SKILL_MD_MAX_BYTES=33000      # the always-loaded core (cut back in v1.16, v1.23, v1.28)
# Not budgets — hard limits set elsewhere:
DESCRIPTION_MAX_CHARS=1024    # Agent Skills spec: description must be 1–1024 characters
LISTING_MAX_CHARS=1536        # Claude Code truncates description + when_to_use beyond this in the listing

failed=0
ok()   { echo "✓ $1"; }
bad()  { echo "✗ $1"; failed=1; }

# ---------------------------------------------------------------- frontmatter + required files
fm_ok=1
for field in "name: shipright" "version:" "description:"; do
  grep -q "^${field}" SKILL.md || { bad "SKILL.md frontmatter is missing '${field}'"; fm_ok=0; }
done
[ "$fm_ok" = 1 ] && ok "SKILL.md frontmatter has name / version / description"

files_ok=1
for f in references/branches/{a-new-project,b-add-feature,c-fix-bug,d-refactor,e-resume,f-incident}.md \
         references/examples/orders-api-CLAUDE.md references/examples/orders-api-ARCHITECTURE.md; do
  [ -f "$f" ] || { bad "missing required file: $f"; files_ok=0; }
done
[ "$files_ok" = 1 ] && ok "branch + example files present"

# ---------------------------------------------------------------- links and orphans
# CHANGELOG is a historical record — allowed to mention intentionally-removed files.
links_ok=1
while IFS= read -r ref; do
  [ -f "$ref" ] || { bad "broken link: $ref"; links_ok=0; }
done < <(grep -rhoE 'references/[a-zA-Z0-9/_-]+\.md' --include='*.md' --exclude=CHANGELOG.md . | sort -u)
[ "$links_ok" = 1 ] && ok "no broken references/… links"

orphans_ok=1
while IFS= read -r f; do
  base=$(basename "$f")
  grep -rqF "$base" --include='*.md' --exclude="$base" --exclude=CHANGELOG.md . \
    || { bad "orphan (referenced nowhere live): $f"; orphans_ok=0; }
done < <(find references -name '*.md')
[ "$orphans_ok" = 1 ] && ok "no orphaned reference files"

# ---------------------------------------------------------------- version consistency
v=$(sed -n 's/^version: *//p' SKILL.md | head -1 | tr -d '\r ')
mm=$(printf '%s' "$v" | cut -d. -f1,2)
ver_ok=1
printf '%s' "$v" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || { bad "SKILL.md version '$v' is not X.Y.Z"; ver_ok=0; }
grep -q "^# Shipright v${mm} " SKILL.md       || { bad "SKILL.md H1 does not say v${mm}"; ver_ok=0; }
grep -q "^# shipright v${v}\$" README.md       || { bad "README.md H1 is not 'shipright v${v}'"; ver_ok=0; }
top=$(grep -m1 -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | tr -d '#[] ')
[ "$top" = "$v" ]                               || { bad "CHANGELOG top entry is [$top], SKILL.md says $v"; ver_ok=0; }
# plugin.json's version PINS plugin users until it changes — a missed bump strands them.
pv=$(sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' .claude-plugin/plugin.json | head -1)
[ "$pv" = "$v" ]                                || { bad ".claude-plugin/plugin.json version is '$pv', SKILL.md says $v"; ver_ok=0; }
[ "$ver_ok" = 1 ] && ok "version $v agrees across SKILL.md, its H1, README, CHANGELOG and plugin.json"

# ---------------------------------------------------------------- plugin manifests
json_ok() {  # jq, else a python that actually runs
  if command -v jq >/dev/null 2>&1; then jq empty "$1" >/dev/null 2>&1; return; fi
  for py in python3 python; do
    if "$py" -c 'import json' >/dev/null 2>&1; then "$py" -c 'import json,sys; json.load(open(sys.argv[1]))' "$1" >/dev/null 2>&1; return; fi
  done
  return 0  # no parser here; CI has one
}
json_all=1
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json; do
  json_ok "$f" || { bad "$f is not valid JSON"; json_all=0; }
done
grep -q '"source": *"\./"' .claude-plugin/marketplace.json || { bad "marketplace.json must list the repo root (\"./\") as the plugin source"; json_all=0; }
[ "$json_all" = 1 ] && ok "plugin.json, marketplace.json, hooks/hooks.json parse; marketplace points at ./"

# ---------------------------------------------------------------- templated files
# Claude Code substitutes argument placeholders in skill/command content BEFORE any shell runs
# (v1.24.1: an awk positional print crashed the skill). Spelled out here so this file doesn't
# contain the token it forbids: a dollar sign + digit, or the ARGUMENTS token.
ph_re='\$[0-9]|\$ARGUMENTS'
ph_hits=$(grep -nE "$ph_re" SKILL.md commands/*.md 2>/dev/null)
if [ -n "$ph_hits" ]; then bad "argument placeholder in templated content:"; echo "$ph_hits" | sed 's/^/    /'
else ok "no argument placeholders in SKILL.md / commands/"; fi

# ---------------------------------------------------------------- probe parity
# The skill lists in SKILL.md's working context and in the version command must name the same skills.
cmd=commands/version.md
core_skill=$(grep '^skill/core:' SKILL.md | grep -oE '\(spec-driven[^)]*\)' | tr -d '()' | tr '|' '\n' | sort)
core_cmd=$(sed -n '/^for s in /,/; do/p' "$cmd" | tr ' ;\\' '\n\n\n' | grep -E '^[a-z]+(-[a-z]+)+$' | sort)
if [ -n "$core_skill" ] && [ "$core_skill" = "$core_cmd" ]; then ok "core skill list matches commands/version.md"
else bad "core skill list differs: SKILL.md [$(echo $core_skill)] vs $cmd [$(echo $core_cmd)]"; fi

taste_of() { grep -oE 'design-taste-frontend\(-v1\)\?\|.*\|full-output-enforcement' "$1" | head -1; }
taste_skill=$(grep '^skill/ui:' SKILL.md | grep -oE 'design-taste-frontend\(-v1\)\?\|.*\|full-output-enforcement')
taste_cmd=$(taste_of "$cmd")
if [ -n "$taste_skill" ] && [ "$taste_skill" = "$taste_cmd" ]; then ok "taste-skill family matches commands/version.md"
else bad "taste-skill family differs between SKILL.md skill/ui and $cmd"; fi

# ---------------------------------------------------------------- honest load sizes
# The routing table tells the model what each branch costs. It said ~900 for files of ~4.8k tokens
# until v1.28. Estimate = bytes/4 (CR stripped); a claim must be within ±25% of it.
sizes_ok=1
while IFS='|' read -r _ _ path claim _; do
  path=$(printf '%s' "$path" | tr -d ' `'); claim=$(printf '%s' "$claim" | tr -d ' ~')
  [ -f "$path" ] || continue
  case "$claim" in *k) claimed=$(awk -v c="${claim%k}" 'BEGIN{printf "%d", c*1000}') ;; *) claimed="$claim" ;; esac
  actual=$(( $(tr -d '\r' < "$path" | wc -c) / 4 ))
  if [ "$claimed" -lt $(( actual * 3 / 4 )) ] || [ "$claimed" -gt $(( actual * 5 / 4 )) ]; then
    bad "routing table says ~${claim} tokens for ${path}; it is ~${actual}"; sizes_ok=0
  fi
done < <(grep -E '^\| [A-F] \| `references/branches/' SKILL.md)
[ "$sizes_ok" = 1 ] && ok "routing-table token sizes are within ±25% of the files"

# ---------------------------------------------------------------- budgets (ratchet)
# Counted without CR: a Windows checkout (core.autocrlf) adds one byte per line, CI's doesn't.
bytes=$(tr -d '\r' < SKILL.md | wc -c | tr -d ' ')
if [ "$bytes" -le "$SKILL_MD_MAX_BYTES" ]; then ok "SKILL.md ${bytes} bytes ≤ budget ${SKILL_MD_MAX_BYTES}"
else bad "SKILL.md is ${bytes} bytes, over the ${SKILL_MD_MAX_BYTES} budget — slim it, don't raise the budget"; fi

# A folded frontmatter field, whitespace-collapsed (ends at the next top-level key).
fm_field() {
  awk -v k="^$1:" '$0 ~ k {f=1; next} f && /^[a-z_-]+:/ {exit} f && /^---/ {exit} f' SKILL.md     | tr -s ' 
	' ' ' | sed 's/^ //; s/ $//'
}
desc_len=$(fm_field description | wc -c | tr -d ' ')
wtu_len=$(fm_field when_to_use | wc -c | tr -d ' ')
listing=$(( desc_len + wtu_len ))
if [ "$desc_len" -le "$DESCRIPTION_MAX_CHARS" ]; then ok "description ${desc_len} chars ≤ ${DESCRIPTION_MAX_CHARS} (Agent Skills spec)"
else bad "description is ${desc_len} chars — the Agent Skills spec allows ${DESCRIPTION_MAX_CHARS}; move trigger phrases to when_to_use"; fi
if [ "$listing" -le "$LISTING_MAX_CHARS" ]; then ok "description + when_to_use ${listing} chars ≤ ${LISTING_MAX_CHARS} (Claude Code listing)"
else bad "description + when_to_use is ${listing} chars — Claude Code truncates the listing at ${LISTING_MAX_CHARS}"; fi

exit "$failed"
