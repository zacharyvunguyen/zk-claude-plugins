#!/usr/bin/env bash
# tdd-gate.sh — Stop hook implementing the tdd-ak test-first discipline gate.
#
# Loop-engineering principle: a "write the test first" rule as prose in CLAUDE.md
# is NOT a guardrail. Only hooks enforce deterministically. This is that gate —
# a nudge (not a hard block), modeled on review-gate.sh.
#
# Behavior:
#   - No-op outside a git repo.
#   - No-op if the only uncommitted changes are docs/markdown/config-ish files.
#   - No-op if ANY changed file looks like a test (assume TDD was followed).
#   - When uncommitted CODE changed but NO test file changed, BLOCK the stop
#     ONCE per session and tell Claude to follow tdd-ak (RED test first).
#   - A per-session flag prevents looping.
#
# Disable anytime via /hooks, or delete the Stop entry in ~/.claude/settings.json.

input="$(cat 2>/dev/null)"
sid="$(printf '%s' "$input" | jq -r '.session_id // "nosession"' 2>/dev/null)"
[ -z "$sid" ] && sid="nosession"
flag="${TMPDIR:-/tmp}/claude-tdd-gate-${sid}"

# Already nudged this session -> allow the stop.
[ -f "$flag" ] && exit 0

# Not a git repo -> nothing to gate.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Uncommitted files (staged + unstaged + untracked); strip the 2-char status + space.
changed="$(git status --porcelain 2>/dev/null | cut -c4-)"
[ -z "$changed" ] && exit 0

# Keep only code (drop docs/markdown/text/license/gitignore/lock/config). If none -> no-op.
code="$(printf '%s\n' "$changed" \
  | grep -viE '\.(md|mdx|markdown|txt|rst|adoc|json|ya?ml|toml|ini|cfg|lock)$' \
  | grep -viE '(^|/)(docs?/|CHANGELOG|LICENSE|\.gitignore)')"
[ -z "$code" ] && exit 0

# Did any changed file look like a test? If so, assume TDD was followed -> allow.
tests="$(printf '%s\n' "$changed" \
  | grep -iE '(^|/)(tests?|__tests__|spec|specs)/|(_test|_spec|\.test|\.spec|test_|Test)\.' )"
[ -n "$tests" ] && exit 0

# Code changed, no test in the diff: nudge once this session.
: > "$flag"
printf '%s\n' '{"decision":"block","reason":"TDD gate (tdd-ak): this session changed CODE but no test file. If this was a feature/bugfix, you likely skipped test-first. Invoke the tdd-ak skill and confirm each behavior has a test that failed first (Verify RED). If tests genuinely do not apply (prototype, generated, config), say so and stop again — this gate fires once per session."}'
