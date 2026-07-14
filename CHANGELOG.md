# Changelog

All notable changes to the `zk` plugin are documented here. Versions follow the `plugin.json` `version` field.

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
