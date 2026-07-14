# zk-claude-plugins

Zachary's personal [Claude Code](https://claude.com/claude-code) plugin marketplace. Skills here are invoked with the `zk:` prefix (e.g. `zk:tdd-ak`).

## Install

```bash
# 1. add this marketplace (private repo — gh auth required)
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

**Bundled hook:** a `Stop` hook (`tdd-gate.sh`) that nudges once per session when a session left uncommitted CODE changes but no test file in the diff — the test-first guardrail. Installed automatically with the plugin.

## Layout

```
.claude-plugin/marketplace.json     # marketplace catalog
plugins/zk/
├── .claude-plugin/plugin.json      # plugin manifest
├── skills/tdd-ak/                  # the skill
│   ├── SKILL.md
│   └── references/testing-anti-patterns.md
└── hooks/
    ├── hooks.json                  # registers the Stop hook
    └── tdd-gate.sh
```

## Adding a new skill

1. `mkdir -p plugins/zk/skills/<name>/` and write `SKILL.md` (frontmatter `name: <name>`).
2. Commit + push.
3. Users run `/plugin marketplace update` → the new skill appears as `zk:<name>`.

## License

MIT
