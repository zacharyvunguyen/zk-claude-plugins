# zk-claude-plugins

Zachary's personal [Claude Code](https://claude.com/claude-code) plugin marketplace. Skills here are invoked with the `zk:` prefix (e.g. `zk:tdd-ak`).

## Install

```bash
# 1. add this marketplace
/plugin marketplace add zacharyvunguyen/zk-claude-plugins

# 2. install the zk plugin
/plugin install zk@zk-marketplace

# 3. restart Claude Code, then invoke
/zk:tdd-ak
```

Update later with `/plugin marketplace update` then `/plugin install zk@zk-marketplace`.

## What's inside

### Plugin: `zk`

The `zk` plugin is a personal **engineering-discipline (HOW) layer** — the pieces the `ak` kit doesn't cover as first-class disciplines. `ak` = WHAT to do; `zk` = HOW to do it well.

| Skill | Purpose |
|-------|---------|
| `zk:tdd-ak` | Test-driven-development discipline (Iron Law, Red→Green→Refactor, integrates `/ak:test` & `/ak:debug`) |
| `zk:verify-ak` | Verification-before-completion — no "done/fixed/passing" claim without running the check and showing real output |
| `zk:receiving-review-ak` | Respond to code-review feedback with rigor (understand → verify → decide with a reason), not blind agreement |

**Bundled gates (two `Stop` hooks, installed automatically):**

- `tdd-gate.sh` — fires when a session leaves uncommitted CODE but **no test file** in the diff. Multi-language (JS/TS, Python, Go, Rust, Java/Kotlin, Ruby, PHP, C#, Elixir), spike-aware, degrades without `jq`.
- `verify-gate.sh` — fires when a session leaves uncommitted CODE, nudging you to **show verification evidence** before claiming done.

The two are complementary: tdd asks *"is there a test?"*, verify asks *"did you run it and show the output?"*, and the `ak` review-gate asks *"was it reviewed?"*.

## Configuration

Tune each gate via `/plugin configure` (values reach the hooks as env vars):

| Option | Gate | Values | Default |
|--------|------|--------|---------|
| `mode` | tdd | `off` · `nudge` (once/session) · `block` | `nudge` |
| `spike_branches` | tdd | pipe-separated regex of skipped branch prefixes | `spike/\|proto/\|…\|throwaway/` |
| `ignore_globs` | tdd | pipe-separated regex of changed paths to ignore | *(empty)* |
| `verify_mode` | verify | `off` · `nudge` (once/session) · `block` | `nudge` |

Or per-project, drop a `.tdd-ak.json` in the repo root (overrides global config):

```json
{ "mode": "block", "verifyMode": "nudge", "spikeBranches": "spike/|throwaway/", "ignoreGlobs": "(^|/)generated/" }
```

## Layout

```
.claude-plugin/marketplace.json     # marketplace catalog
CHANGELOG.md
plugins/zk/
├── .claude-plugin/plugin.json      # plugin manifest (+ userConfig)
├── skills/
│   ├── tdd-ak/SKILL.md             # (+ references/testing-anti-patterns.md)
│   ├── verify-ak/SKILL.md
│   └── receiving-review-ak/SKILL.md
├── hooks/
│   ├── hooks.json                  # registers both Stop gates
│   ├── tdd-gate.sh                 # configurable, multi-language
│   └── verify-gate.sh              # evidence-before-claims
└── evals/                          # claude plugin eval zk
```

## Adding a new skill

1. `mkdir -p plugins/zk/skills/<name>/` and write `SKILL.md` (frontmatter `name: <name>`).
2. Commit + push.
3. Users run `/plugin marketplace update` → the new skill appears as `zk:<name>`.

## License

MIT
