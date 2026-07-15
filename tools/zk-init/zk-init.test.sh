#!/usr/bin/env bash
# Test harness for zk-init (zk:tdd-ak — tests updated BEFORE the simplification, RED first).
# Runs the command under test in throwaway git repos and asserts behavior + exit codes.
# Point ZK_INIT_BIN at the script under test; defaults to the dev source.
set -u

# Default to the zk-init sitting next to this test file (location-independent).
ZK_INIT_BIN="${ZK_INIT_BIN:-$(cd "$(dirname "$0")" && pwd)/zk-init}"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  PASS %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }

# run the bin inside $1 (a dir); capture stdout+stderr in $OUT, exit in $RC
run() { local d="$1"; shift; OUT="$( cd "$d" && "$ZK_INIT_BIN" "$@" 2>&1 )"; RC=$?; }
newrepo() { local d; d="$(mktemp -d /tmp/zk-init-test.XXXXXX)"; ( cd "$d" && git init -q && git config user.email t@t && git config user.name t ); printf '%s' "$d"; }
isfull() { [ "$(jq -r .mode "$1")" = block ] && [ "$(jq -r .verifyMode "$1")" = block ] && [ "$(jq -r .designMode "$1")" = nudge ]; }

echo "== zk-init tests (bin=$ZK_INIT_BIN) =="

# 1. not a git repo -> exit 1
D="$(mktemp -d /tmp/zk-init-nogit.XXXXXX)"
run "$D" full
{ [ "$RC" -eq 1 ] && printf '%s' "$OUT" | grep -qi "not a git repo"; } && ok "non-git exits 1 with message" || bad "non-git (rc=$RC out=$OUT)"
rm -rf "$D"

# 2. NO ARGS -> applies the full-stack preset (the simplified default)
D="$(newrepo)"
run "$D"
{ [ "$RC" -eq 0 ] && [ -f "$D/.tdd-ak.json" ] && isfull "$D/.tdd-ak.json"; } && ok "no-arg -> full (block/block/nudge)" || bad "no-arg default (rc=$RC out=$OUT)"
jq -e . "$D/.tdd-ak.json" >/dev/null 2>&1 && ok "default output is valid JSON" || bad "default invalid JSON"
rm -rf "$D"

# 3. explicit 'full' preset
D="$(newrepo)"; run "$D" full
{ [ "$RC" -eq 0 ] && isfull "$D/.tdd-ak.json"; } && ok "full -> block/block/nudge" || bad "full (rc=$RC out=$OUT)"
# idempotent
run "$D" full
{ [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -qi "no change"; } && ok "idempotent re-run says no change" || bad "idempotent (rc=$RC out=$OUT)"
rm -rf "$D"

# 4. 'off' preset -> everything off
D="$(newrepo)"; run "$D" off
{ [ "$RC" -eq 0 ] && [ "$(jq -r .mode "$D/.tdd-ak.json")" = off ] && [ "$(jq -r .verifyMode "$D/.tdd-ak.json")" = off ]; } && ok "off -> all off" || bad "off (rc=$RC out=$OUT)"
rm -rf "$D"

# 5. aliases still work: strict + frontend
D="$(newrepo)"; run "$D" strict
{ [ "$RC" -eq 0 ] && [ "$(jq -r .mode "$D/.tdd-ak.json")" = block ] && [ "$(jq -r .verifyMode "$D/.tdd-ak.json")" = block ]; } && ok "alias strict works" || bad "strict (rc=$RC out=$OUT)"
rm -rf "$D"
D="$(newrepo)"; run "$D" frontend
{ [ "$RC" -eq 0 ] && isfull "$D/.tdd-ak.json"; } && ok "alias frontend == full" || bad "frontend (rc=$RC out=$OUT)"
rm -rf "$D"

# 6. overwrite different WITHOUT --force -> refuse (exit 3), unchanged
D="$(newrepo)"; run "$D" off; before="$(cat "$D/.tdd-ak.json")"
run "$D" full
{ [ "$RC" -eq 3 ] && [ "$(cat "$D/.tdd-ak.json")" = "$before" ]; } && ok "refuses overwrite w/o --force (exit 3)" || bad "no-force overwrite (rc=$RC out=$OUT)"
# 7. --force overwrites + backs up
run "$D" full --force
nbak="$(ls "$D"/.tdd-ak.json.bak-* 2>/dev/null | wc -l | tr -d ' ')"
{ [ "$RC" -eq 0 ] && isfull "$D/.tdd-ak.json" && [ "$nbak" -ge 1 ]; } && ok "--force overwrites + backs up" || bad "force (rc=$RC baks=$nbak out=$OUT)"
rm -rf "$D"

# 8. bare --force (no preset) -> full + force overwrite
D="$(newrepo)"; run "$D" off
run "$D" --force
{ [ "$RC" -eq 0 ] && isfull "$D/.tdd-ak.json"; } && ok "bare --force -> full + overwrite" || bad "bare --force (rc=$RC out=$OUT)"
rm -rf "$D"

# 9. writes to repo ROOT from a subdir
D="$(newrepo)"; mkdir -p "$D/sub/deep"; run "$D/sub/deep"
{ [ -f "$D/.tdd-ak.json" ] && [ ! -f "$D/sub/deep/.tdd-ak.json" ]; } && ok "writes to repo root from subdir" || bad "subdir root (rc=$RC out=$OUT)"
# 10. show
run "$D" show
{ [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -qi '"mode"'; } && ok "show prints config" || bad "show (rc=$RC out=$OUT)"
rm -rf "$D"

# 11. unknown preset -> exit 2
D="$(newrepo)"; run "$D" bogus
[ "$RC" -eq 2 ] && ok "unknown preset exits 2" || bad "unknown (rc=$RC out=$OUT)"
rm -rf "$D"

# 12. --help -> usage, exit 0, no git needed
D="$(mktemp -d /tmp/zk-init-help.XXXXXX)"; run "$D" --help
{ [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -qi "Usage:"; } && ok "--help -> usage/exit 0" || bad "help (rc=$RC out=$OUT)"
rm -rf "$D"

echo "== $pass passed, $fail failed =="
[ "$fail" -eq 0 ]
