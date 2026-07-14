#!/usr/bin/env bash
# verify-gate.sh — Stop hook for the zk:verify-ak "evidence before claims" discipline.
#
# It cannot detect "you claimed done" deterministically, so it uses a light proxy:
# when a session leaves uncommitted CODE and is about to stop, it nudges you once to
# show the verification evidence (real command output) before calling anything done.
#
# Independent from tdd-gate: reads its OWN config key so the two can be tuned separately.
#   verify_mode: off | nudge (default, once/session) | block
# Config precedence (highest first):
#   1. repo-root .tdd-ak.json  { "verifyMode":"" }
#   2. env from /plugin configure: CLAUDE_PLUGIN_OPTION_VERIFY_MODE
#   3. default: nudge
#
# Exit 0 = allow stop. Print {"decision":"block",...} = block once. Disable via
# /plugin configure (verify_mode=off), a repo .tdd-ak.json, or /hooks.

set -u

input="$(cat 2>/dev/null || true)"

# --- session id (jq if present, else portable sed fallback) ---
sid=""
if command -v jq >/dev/null 2>&1; then
  sid="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)"
fi
[ -z "$sid" ] && sid="$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
[ -z "$sid" ] && sid="nosession"

# --- config: env default, then repo-local override ---
mode="${CLAUDE_PLUGIN_OPTION_VERIFY_MODE:-nudge}"
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
cfg="${repo_root:+$repo_root/.tdd-ak.json}"
if [ -n "$cfg" ] && [ -f "$cfg" ] && command -v jq >/dev/null 2>&1; then
  v="$(jq -r '.verifyMode // empty' "$cfg" 2>/dev/null)"; [ -n "$v" ] && mode="$v"
fi

# normalize: unknown/typo fails safe to the least-disruptive 'nudge'
case "$mode" in off|nudge|block) ;; *) mode="nudge" ;; esac
[ "$mode" = "off" ] && exit 0

# not a git repo -> nothing to gate
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# session flag: nudge fires once; block keeps firing
flag="${TMPDIR:-/tmp}/claude-verify-gate-${sid}"
if [ "$mode" = "nudge" ] && [ -f "$flag" ]; then
  exit 0
fi

# uncommitted files -> drop docs/config; if real code remains, nudge for evidence
changed="$(git -c core.quotepath=false status --porcelain 2>/dev/null | cut -c4-)"
[ -z "$changed" ] && exit 0
code="$(printf '%s\n' "$changed" \
  | grep -viE '\.(md|mdx|markdown|txt|rst|adoc|json|jsonc|ya?ml|toml|ini|cfg|conf|lock|env|properties)$' \
  | grep -viE '(^|/)(docs?/|CHANGELOG|LICENSE|README|\.gitignore|\.editorconfig)')"
[ -z "$code" ] && exit 0

reason='Verify gate (zk:verify-ak): before calling this done, RUN the decisive check (test/build/typecheck/repro) in the current state and show its real output — exit code / pass count / the original symptom gone. A claim without fresh command output is a guess. Evidence before assertions. Tune with /plugin configure (verify_mode=off|nudge|block) or a repo .tdd-ak.json.'

if [ "$mode" = "nudge" ]; then
  : > "$flag" 2>/dev/null || true
fi

printf '{"decision":"block","reason":"%s"}\n' "$reason"
