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

| Skill | Purpose |
|-------|---------|
| `zk:tdd-ak` | ak-flavored test-driven-development discipline (Iron Law, Red→Green→Refactor, integrates `/ak:test` & `/ak:debug`, review-gate) |

**Bundled hook:** a `Stop` hook (`tdd-gate.sh`) — the test-first guardrail. When a session leaves uncommitted CODE changes but no test file in the diff, it fires. Installed automatically with the plugin. It is:

- **Multi-language** — detects tests for JS/TS, Python, Go, Rust, Java/Kotlin, Ruby, PHP, C#, Elixir.
- **Spike-aware** — skips throwaway branches (`spike/`, `proto/`, `wip/`, …).
- **Safe** — degrades without `jq`; ignores docs/config; never blocks on non-code.

## Configuration

Tune the gate without editing files via `/plugin configure` (values reach the hook as env vars):

| Option | Values | Default |
|--------|--------|---------|
| `mode` | `off` · `nudge` (block once/session) · `block` (block until a test appears) | `nudge` |
| `spike_branches` | pipe-separated regex of skipped branch prefixes | `spike/\|proto/\|prototype/\|experiment/\|wip/\|scratch/\|throwaway/` |
| `ignore_globs` | pipe-separated regex of changed paths to ignore | *(empty)* |

Or per-project, drop a `.tdd-ak.json` in the repo root (overrides the global config):

```json
{ "mode": "block", "spikeBranches": "spike/|throwaway/", "ignoreGlobs": "(^|/)generated/" }
```

## Layout

```
.claude-plugin/marketplace.json     # marketplace catalog
CHANGELOG.md
plugins/zk/
├── .claude-plugin/plugin.json      # plugin manifest (+ userConfig)
├── skills/tdd-ak/                  # the skill
│   ├── SKILL.md
│   └── references/testing-anti-patterns.md
├── hooks/
│   ├── hooks.json                  # registers the Stop hook
│   └── tdd-gate.sh                 # configurable, multi-language gate
└── evals/                          # claude plugin eval zk
```

## Adding a new skill

1. `mkdir -p plugins/zk/skills/<name>/` and write `SKILL.md` (frontmatter `name: <name>`).
2. Commit + push.
3. Users run `/plugin marketplace update` → the new skill appears as `zk:<name>`.

## License

MIT
