# Changelog

All notable changes to the `zk` plugin are documented here. Versions follow the `plugin.json` `version` field.

## 0.3.0

**Completes the zk discipline trio** (ak-flavored HOW layer). Adapted from `obra/superpowers`, only the disciplines the `ak` kit does not already cover.

- **New `zk:verify-ak`** — verification-before-completion: no "done/fixed/passing" claim without running the real check and showing its output. Bundles a light `Stop` hook (`verify-gate.sh`, `verify_mode` = off|nudge|block, default nudge).
- **New `zk:receiving-review-ak`** — respond to code-review feedback with rigor: understand → verify → decide with a reason, instead of blind agreement or blind refusal. Complements `/ak:code-review` (which *gives* reviews).
- `verify-gate` uses its own config key (`verify_mode` / `.tdd-ak.json` `verifyMode`) so it tunes independently of the tdd gate.
- Docs: README documents the trio and the two Stop gates.

## 0.2.1

Fixes from self code-review of the gate:

- **Test detection false-negative fixed**: production files ending in `test.<ext>`/`spec.<ext>` (e.g. `latest.js`, `contest.py`) were mistaken for test files, silencing the gate. Bare-name patterns are now anchored to a path boundary; PascalCase suffixes (`FooTest.java`) matched case-sensitively.
- **Fail-safe mode**: an unknown/typo `mode` value now falls back to `nudge` instead of silently hard-blocking every stop.
- Quieted stderr on a malformed `spike_branches` regex.

## 0.2.0

**tdd-ak level-up.**

- **Smarter gate** (`tdd-gate.sh` v2): multi-language test detection (JS/TS, Python, Go, Rust, Java/Kotlin, Ruby, PHP, C#, Elixir), instead of a generic pattern.
- **Configurable strictness** via `/plugin configure` (`mode` = `off` | `nudge` | `block`) or a repo-root `.tdd-ak.json`. Default `nudge` (blocks once per session).
- **Spike-aware**: skips throwaway branches (`spike/`, `proto/`, `wip/`, …; configurable).
- **Safer parsing**: degrades gracefully without `jq`; `set -u`; `core.quotepath=false`; per-project `ignore_globs`.
- **Skill polish**: `SKILL.md` gains a machine-checkable Definition of Done and gate/exception guidance.
- Eval **starter** under `plugins/zk/evals/` (`prompt.md` + grader) for `claude plugin eval zk` — unverified: the command is in early access, so treat as scaffolding pending GA.

## 0.1.0

- Initial release: `zk:tdd-ak` skill (ak-flavored test-driven-development) + bundled test-first `Stop` hook, distributed via the `zk-marketplace`.
