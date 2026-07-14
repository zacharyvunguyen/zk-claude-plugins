#!/usr/bin/env bash
# design-verify-gate.sh — Stop hook for the zk:design-verify-ak "visual evidence" discipline.
#
# The frontend sibling of verify-gate. A UI claim without a picture is a guess: a
# component "looks done" in code and still ships broken spacing, an AI-slop palette,
# no focus ring, or motion that ignores reduced-motion. This gate uses a light proxy:
# when a session leaves uncommitted UI/FRONTEND files and is about to stop, it nudges
# you once to show visual evidence (screenshot/preview) and run the frontend-design
# critique before calling the UI done.
#
# Domain-specific by design: it only fires when the diff actually touches UI files, so
# it never bothers a backend-only repo. Because verify-gate ALSO fires on any code, the
# default here is 'off' to avoid double-nudging — opt in per frontend project via
#   repo-root .tdd-ak.json  { "designMode":"nudge" }
# or /plugin configure (design_mode=nudge|block).
#
# Config precedence (highest first):
#   1. repo-root .tdd-ak.json  { "designMode":"" }
#   2. env from /plugin configure: CLAUDE_PLUGIN_OPTION_DESIGN_MODE
#   3. default: off
#
# Exit 0 = allow stop. Print {"decision":"block",...} = block once (nudge) or every
# stop (block). Disable via /plugin configure (design_mode=off), a repo .tdd-ak.json,
# or /hooks.

set -u

input="$(cat 2>/dev/null || true)"

# --- session id (jq if present, else portable sed fallback) ---
sid=""
if command -v jq >/dev/null 2>&1; then
  sid="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)"
fi
[ -z "$sid" ] && sid="$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
[ -z "$sid" ] && sid="nosession"

# --- config: env default (off), then repo-local override ---
mode="${CLAUDE_PLUGIN_OPTION_DESIGN_MODE:-off}"
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
cfg="${repo_root:+$repo_root/.tdd-ak.json}"
if [ -n "$cfg" ] && [ -f "$cfg" ] && command -v jq >/dev/null 2>&1; then
  v="$(jq -r '.designMode // empty' "$cfg" 2>/dev/null)"; [ -n "$v" ] && mode="$v"
fi

# normalize: unknown/typo fails safe to 'off' (this is an opt-in gate)
case "$mode" in off|nudge|block) ;; *) mode="off" ;; esac
[ "$mode" = "off" ] && exit 0

# not a git repo -> nothing to gate
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# session flag: nudge fires once; block keeps firing
flag="${TMPDIR:-/tmp}/claude-design-verify-gate-${sid}"
if [ "$mode" = "nudge" ] && [ -f "$flag" ]; then
  exit 0
fi

# uncommitted files -> keep only UI/frontend surfaces; if any remain, nudge for a picture
changed="$(git -c core.quotepath=false status --porcelain 2>/dev/null | cut -c4-)"
[ -z "$changed" ] && exit 0
# markup, styles, and component files across the common web stacks
ui="$(printf '%s\n' "$changed" \
  | grep -iE '\.(tsx|jsx|vue|svelte|astro|html|htm|css|scss|sass|less|styl)$')"
[ -z "$ui" ] && exit 0

reason='Design-verify gate (zk:design-verify-ak): this session changed UI files. Before calling the design done, SHOW visual evidence — a screenshot or preview of the actual rendered result, not just the code — and run the frontend-design critique: is the palette/type a deliberate choice or an AI-slop default (cream+serif+terracotta / near-black+acid accent / hairline broadsheet)? Does it meet the quality floor (responsive to mobile, visible keyboard focus, reduced-motion respected)? A UI claim without a picture is a guess. Tune with /plugin configure (design_mode=off|nudge|block) or a repo .tdd-ak.json designMode key.'

if [ "$mode" = "nudge" ]; then
  : > "$flag" 2>/dev/null || true
fi

printf '{"decision":"block","reason":"%s"}\n' "$reason"
