#!/usr/bin/env bash
# tdd-gate.sh (v2) — Stop hook enforcing the zk:tdd-ak test-first discipline.
#
# Loop-engineering principle: a "write the test first" rule as prose is NOT a
# guardrail. Only hooks enforce deterministically. This is that gate.
#
# What it does (once the model finishes responding / tries to stop):
#   - Looks at uncommitted CHANGES in the repo.
#   - If CODE changed but NO test file is among the changes, it acts per `mode`.
#   - Multi-language test detection; skips docs/config; skips spike branches;
#     honors per-project + global config; degrades gracefully without jq.
#
# Modes:
#   off    -> never fires
#   nudge  -> blocks the stop ONCE per session, then allows (default)
#   block  -> blocks every stop until a test appears or the repo opts out
#
# Config precedence (highest first):
#   1. repo-root .tdd-ak.json  { "mode":"", "spikeBranches":"", "ignoreGlobs":"" }
#   2. env from /plugin configure: CLAUDE_PLUGIN_OPTION_MODE / _SPIKE_BRANCHES / _IGNORE_GLOBS
#   3. built-in defaults
#
# Exit 0 = allow stop. Print a JSON {"decision":"block",...} = block the stop.
# Disable anytime via /plugin configure (mode=off), a repo .tdd-ak.json, or /hooks.

set -u

input="$(cat 2>/dev/null || true)"

# --- session id (jq if present, else a portable sed fallback) ---
sid=""
if command -v jq >/dev/null 2>&1; then
  sid="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)"
fi
[ -z "$sid" ] && sid="$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
[ -z "$sid" ] && sid="nosession"

# --- config defaults, then env overrides ---
mode="${CLAUDE_PLUGIN_OPTION_MODE:-nudge}"
spike="${CLAUDE_PLUGIN_OPTION_SPIKE_BRANCHES:-spike/|proto/|prototype/|experiment/|wip/|scratch/|throwaway/}"
ignore="${CLAUDE_PLUGIN_OPTION_IGNORE_GLOBS:-}"

# --- repo-local override (.tdd-ak.json), if jq available ---
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
cfg="${repo_root:+$repo_root/.tdd-ak.json}"
if [ -n "$cfg" ] && [ -f "$cfg" ] && command -v jq >/dev/null 2>&1; then
  v="$(jq -r '.mode // empty' "$cfg" 2>/dev/null)";          [ -n "$v" ] && mode="$v"
  v="$(jq -r '.spikeBranches // empty' "$cfg" 2>/dev/null)"; [ -n "$v" ] && spike="$v"
  v="$(jq -r '.ignoreGlobs // empty' "$cfg" 2>/dev/null)";   [ -n "$v" ] && ignore="$v"
fi

# --- mode off -> never fire ---
[ "$mode" = "off" ] && exit 0

# --- not a git repo -> nothing to gate ---
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# --- spike / prototype branch -> skip (TDD is optional for throwaways) ---
branch="$(git branch --show-current 2>/dev/null || true)"
if [ -n "$branch" ] && [ -n "$spike" ] && printf '%s' "$branch" | grep -qiE "$spike"; then
  exit 0
fi

# --- session flag: nudge fires once; block keeps firing ---
flag="${TMPDIR:-/tmp}/claude-tdd-gate-${sid}"
if [ "$mode" = "nudge" ] && [ -f "$flag" ]; then
  exit 0
fi

# --- collect uncommitted files (staged + unstaged + untracked) ---
changed="$(git -c core.quotepath=false status --porcelain 2>/dev/null | cut -c4-)"
[ -z "$changed" ] && exit 0

# --- drop docs / config / lock / metadata; drop user-supplied ignore globs ---
code="$(printf '%s\n' "$changed" \
  | grep -viE '\.(md|mdx|markdown|txt|rst|adoc|json|jsonc|ya?ml|toml|ini|cfg|conf|lock|env|properties)$' \
  | grep -viE '(^|/)(docs?/|CHANGELOG|LICENSE|README|\.gitignore|\.editorconfig)')"
if [ -n "$ignore" ]; then
  # ignore is a pipe-separated list of extended-regex fragments
  code="$(printf '%s\n' "$code" | grep -viE "$ignore" 2>/dev/null)"
fi
[ -z "$code" ] && exit 0

# --- is any changed file a test? (multi-language) ---
# JS/TS(.test/.spec,__tests__) · Python(test_*, *_test, tests/) · Go(*_test.go)
# Rust(tests/, *_test.rs) · Java/Kotlin(*Test(s), src/test/) · Ruby(*_spec, spec/)
# PHP(*Test.php, tests/) · C#(*Test(s).cs) · Elixir(*_test.exs, test/)
test_re='(^|/)(tests?|specs?|__tests__)/|(_test|_tests|_spec|test_|tests_|\.test\.|\.spec\.)|(test|tests|spec|specs)\.[a-z0-9]+$'
if printf '%s\n' "$changed" | grep -qiE "$test_re"; then
  exit 0
fi

# --- code changed, no test present: act per mode ---
reason='TDD gate (zk:tdd-ak): this session changed CODE but no test file is in the diff. If this was a feature/bugfix you likely skipped test-first. Invoke the zk:tdd-ak skill and confirm each behavior has a test that FAILED first (Verify RED). Genuinely no test needed (prototype/generated/config)? Say so and stop again. Tune with /plugin configure (mode=off|nudge|block) or a repo .tdd-ak.json.'

if [ "$mode" = "nudge" ]; then
  : > "$flag" 2>/dev/null || true
fi

# reason is static (no quotes/newlines/backslashes) so this printf is safe JSON.
printf '{"decision":"block","reason":"%s"}\n' "$reason"
