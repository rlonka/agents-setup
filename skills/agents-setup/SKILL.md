---
name: agents-setup
description: Set up (or audit) a shared AI coding agent environment for Claude Code, Codex and OpenCode on this machine. It installs one global AGENTS.md, a shared skills directory, global git hooks for secret scanning and protected branches, and command guardrails generated from one policy file. Use only when the user explicitly asks to set up, reproduce or audit this agent setup.
disable-model-invocation: true
---

# Agents setup

Reproduce a tool-agnostic agent setup on the user's machine. It changes global
configuration in the user's home directory, so: **detect first, ask, back up, then
change, then verify.** Never overwrite a file without a backup, never print a secret,
never push anything.

Paths below are relative to this skill's directory (`templates/`, `scripts/`).

## What gets set up (four independent modules)

| Module | Result |
|---|---|
| **A. Global context** | `~/.agents/AGENTS.md` is the single source; `~/.claude/CLAUDE.md`, `$CODEX_HOME/AGENTS.md` (default `~/.codex`) and `~/.config/opencode/AGENTS.md` become symlinks to it |
| **B. Shared skills** | `~/.agents/skills/` holds skills; Claude Code sees them through symlinks in `~/.claude/skills/` |
| **C. Git hooks** | `core.hooksPath = ~/.agents/git-hooks`: gitleaks secret scan on commit, optional block of pushes to protected branches; repositories' own hooks still run |
| **D. Guardrails** | `~/.agents/guardrails.yaml` → `sync-guardrails.py` → deny/ask rules in Claude Code, Codex and OpenCode configs |

Git hooks are the hard layer (they apply to every tool and to the human). Guardrails are
the soft layer: prefix-matched, bypassable via `bash -c`, but they deny agents
`--no-verify`, the only easy way around the hooks.

## Step 1: Detect (read-only)

Collect and show the user a short summary:

- OS and architecture (`uname -s -m`).
- Which tools are installed: `command -v claude codex opencode`, and which config dirs
  exist: `~/.claude`, `${CODEX_HOME:-~/.codex}`, `~/.config/opencode`.
- Existing global context files. For each of `~/.claude/CLAUDE.md`,
  `$CODEX_HOME/AGENTS.md`, `~/.config/opencode/AGENTS.md`, `~/.agents/AGENTS.md`: missing,
  regular file (read it), or symlink (to where).
- `git config --global --get core.hooksPath`: if set to anything other than
  `~/.agents/git-hooks` (e.g. husky, pre-commit), module C needs a decision.
- `command -v gitleaks`; `python3 -c "import yaml"` (needed by module D).
- `~/.config/opencode/opencode.jsonc`: if it exists, module D cannot write OpenCode config.
- Whether this setup is already (partly) installed; then treat the run as an update:
  show diffs against the templates instead of recreating files.

## Step 2: Ask

Ask in one round (use the tool's question UI if it has one):

1. **Which modules** (A to D)? Default: all.
2. **Commit message convention** for the global context: Conventional Commits in English
   (as in the template), or "follow each repository's style" (remove the
   *Commit messages* section).
3. **Protected branches** (module C): block pushes to `main master` (default), a custom
   list, or no blocking.
4. **No-AI-attribution rule** (template's *Attribution* section): keep (default) or drop.

If `core.hooksPath` already points elsewhere, ask whether to replace it; replacing it
disables that tool's hooks unless they are re-installed into the repositories.

## Step 3: Back up

Copy every file that will be modified or replaced into
`~/.agents/backup/<YYYYMMDD-HHMMSS>/`, keeping the path relative to `$HOME`:
the three per-tool context files, `~/.agents/AGENTS.md`, `~/.claude/settings.json`,
`~/.config/opencode/opencode.json`, `~/.gitconfig`. Copy file contents (`cp -L`), not symlinks.

## Step 4: Global context (module A)

1. Start from `templates/AGENTS.md`, applying the answers from step 2.
2. If the user already has global context files with their own rules, **merge** them into
   the new file: keep every rule of theirs that the template doesn't cover; where one
   contradicts the template, ask which wins. Don't silently drop anything.
3. Show the result and get approval, then write `~/.agents/AGENTS.md`.
4. Replace each per-tool file with a symlink, only for tools whose config dir exists:
   `ln -sfn ~/.agents/AGENTS.md <file>`.

Note: Claude Code skips a symlinked `~/.claude/CLAUDE.md` in desktop Cowork sessions and
with third-party providers (Bedrock etc.); mention it if relevant.

## Step 5: Shared skills (module B)

1. `mkdir -p ~/.agents/skills`.
2. For each skill directory in `~/.agents/skills/` without an entry in `~/.claude/skills/`,
   create a relative symlink: `ln -s ../../.agents/skills/<name> ~/.claude/skills/<name>`.
   OpenCode reads `~/.agents/skills` natively.
3. Tell the user that installing further skills with the Skills CLI
   (`npx skills add <source> -g`) keeps this layout by itself.

## Step 6: Git hooks (module C)

1. `sh scripts/install-gitleaks.sh` (Homebrew on macOS, checksum-verified release binary
   into `~/.local/bin` on Linux). Stop if it fails: the pre-commit hook refuses to commit
   without gitleaks.
2. `sh scripts/install-git-hooks.sh`. Exit code 2 means `core.hooksPath` points elsewhere;
   only continue if the user agreed to replace it in step 2 (then unset it and rerun).
3. Protected branches from step 2:
   - default `main master` → nothing to do (the hook's default),
   - custom list → `git config --global agents.protectedBranches "<list>"`,
   - no blocking → `git config --global agents.protectedBranches ""`.

Limitations to tell the user: repositories with their own local `core.hooksPath`
(husky) bypass the global hooks; `--no-verify` skips them.

## Step 7: Guardrails (module D)

1. If `~/.agents/guardrails.yaml` doesn't exist, copy `templates/guardrails.yaml` there;
   if it does, show the diff and ask. Copy `scripts/sync-guardrails.py` to `~/.agents/`.
2. Run `python3 ~/.agents/sync-guardrails.py` (without PyYAML:
   `uv run --with pyyaml python3 ~/.agents/sync-guardrails.py`).
3. Explain the consequence for existing allowlists: in Claude Code deny > ask > allow and
   in Codex forbidden > prompt > allow, so an existing "always allow" for `git push` now
   asks. A project-level `allow` cannot relax a global `deny`/`ask`; change the YAML instead.

## Step 8: Audit existing agent config (read-only, report only)

- Secrets written into tool configs by "always allow" approvals:
  `gitleaks dir --redact --no-banner <path>` for `$CODEX_HOME/rules`,
  `~/.claude/settings.json`, `~/.claude/settings.local.json`, `~/.config/opencode`.
  Report the file and line only, never the secret. Tell the user to **revoke** a found
  token first, then delete the rule.
- Allow rules that make other rules pointless: `python -c *`, `python3 -c *`, `bash -c *`,
  `sh -c *`, bare `python3`, `git push *`, `curl *`.
- Codex `config.toml`: `[projects."/"] trust_level = "trusted"` (trusts the whole disk).

Don't fix these; list them with a recommendation.

## Step 9: Verify

Run `sh scripts/verify.sh` and show its output. It checks the symlinks, makes a clean
commit and a commit with a fake token in a throwaway repo, pushes to a feature branch and
to `main`, and checks the generated Codex/Claude/OpenCode rules. Any `FAIL` means the
setup is not done: fix it or report it.

## Step 10: Report

Summarize: what was installed, which answers were used, where the backup is, audit
findings, and how to undo:

```bash
git config --global --unset core.hooksPath          # module C off
# module D: empty the lists in ~/.agents/guardrails.yaml, rerun sync-guardrails.py
# module A: restore the per-tool files from ~/.agents/backup/<timestamp>/
```

Remind the user that changes to Claude Code and Codex settings reliably apply only to
new sessions, and that a direct push to a protected branch now needs
`git push --no-verify`.
