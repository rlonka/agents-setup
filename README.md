# agents-setup

A skill that sets up a shared environment for the AI coding agents
**Claude Code, Codex and OpenCode** on your machine, so that all three follow the same rules:

| Module | What it does |
|---|---|
| **A. Global context** | One `~/.agents/AGENTS.md`, with `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` and `~/.config/opencode/AGENTS.md` as symlinks to it |
| **B. Shared skills** | `~/.agents/skills/`, exposed to Claude Code through symlinks |
| **C. Git hooks** | Global `core.hooksPath`: gitleaks secret scan on commit, optional block of pushes to `main`/`master`; repositories' own hooks keep working |
| **D. Guardrails** | One `~/.agents/guardrails.yaml` → deny/ask rules generated into the config of all three tools |

The skill first inspects the current state, asks about the options (modules, commit
convention, protected branches), **backs everything up** to `~/.agents/backup/<timestamp>/`,
**merges** existing context files (never overwrites them), sets up the selected modules,
audits your existing agent config (e.g. tokens saved in rules by "always allow") and
finally **verifies** everything in a throwaway repository.

## Installation

```bash
npx skills add rlonka/agents-setup -g
```

This uses the [Skills CLI](https://github.com/vercel-labs/skills); `npx skills update`
picks up new versions later. Add `DISABLE_TELEMETRY=1` in front to opt out of its telemetry.

## Usage

The skill runs **only when explicitly requested**. In any of the three tools, ask e.g.
*"run the agents-setup skill"* (in Claude Code: `/agents-setup`).

## Requirements

- git, Python 3 with PyYAML (or `uv`), `curl`
- Linux (x64/arm64) or macOS with Homebrew, for installing gitleaks

## Undo

```bash
git config --global --unset core.hooksPath      # git hooks off
# guardrails: empty the lists in ~/.agents/guardrails.yaml and rerun
python3 ~/.agents/sync-guardrails.py
# context files: restore from the backup in ~/.agents/backup/<timestamp>/
```

## Repository layout

```
skills/agents-setup/
├── SKILL.md                    procedure for the agent
├── templates/
│   ├── AGENTS.md               global context template
│   └── guardrails.yaml         default rules
└── scripts/
    ├── run-hook                git hook dispatcher
    ├── install-git-hooks.sh
    ├── install-gitleaks.sh
    ├── sync-guardrails.py      guardrails.yaml → Claude / Codex / OpenCode
    └── verify.sh               end-to-end verification
```

## License

[MIT](LICENSE)
