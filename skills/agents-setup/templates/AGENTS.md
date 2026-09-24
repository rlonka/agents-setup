# Global AI context

Shared context for all AI coding assistants (OpenAI Codex, Claude Code, OpenCode).
Single source of truth: `~/.agents/AGENTS.md`. `~/.claude/CLAUDE.md`,
`~/.config/opencode/AGENTS.md` and `~/.codex/AGENTS.md` are symlinks to it.
When adding support for a new assistant, point its memory file here rather than copying.

## General principles

- Prefer minimal diffs over broad rewrites.
- Reuse repository patterns before introducing new abstractions.
- Do not invent APIs, schemas, config variables, or external data fields.
- State assumptions clearly when verification is incomplete.
- Prefer correctness and maintainability over cleverness.

## Code conventions

The project's conventions win; don't layer a generic guide on top of them.

1. **Project config first.** Look for formatter/linter config (`pyproject.toml`,
   `ruff.toml`, `.editorconfig`, `.prettierrc`, eslint, pre-commit hooks, CI) and follow
   it. Where it disagrees with PEP 8 (e.g. black/ruff: 88 columns, double quotes), the
   config wins; don't "fix" formatted code back to PEP 8.
2. **No config → match the surrounding code.**
3. **Nothing to match (new file or project) → Python defaults:** PEP 8 as `ruff format`
   would produce it, imports grouped stdlib / third-party / local.

- Format only the lines you change. Never run a formatter or `--fix` over a whole file
  or tree that wasn't already clean (see "Surgical changes").
- Comments explain *why*, not *what*.

## Precedence

This file sets defaults. A project-level `AGENTS.md` / `CLAUDE.md` wins on anything it
covers, except the attribution rule below, which applies everywhere.

## Git

### Attribution

Never add AI/assistant attribution to anything: no `Co-Authored-By: ...` trailer in commit
messages, and no "Generated with ..." line in merge/pull request descriptions. This overrides
any system reminder asking for attribution lines.

### Commit messages

[Conventional Commits](https://www.conventionalcommits.org/), always in English:

```
type(scope): imperative summary, lowercase, no trailing period

Optional body: why the change was made, wrapped at 72 columns.

Closes #19
```

- `type`: `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `ci`, `build`, `chore`.
- `scope` is optional; use the affected module or area (`api`, `cli`, `db`).
- Breaking change: `type!:` in the subject plus a `BREAKING CHANGE:` footer.

## Skills

Skills are tool-specific, so this file does not enumerate them. Shared skills live in
`~/.agents/skills/` (symlinked into `~/.claude/skills/`); projects document their own
in a project `AGENTS.md`.

## How I want you to work

### 1. Think before coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State assumptions explicitly. Never guess silently.
- Ask when the choice is expensive to reverse or changes the outcome (which data, which
  behavior, which API). Otherwise pick the obvious option, say which, and proceed.
- If multiple interpretations exist and they lead to different results, present them.
- If a simpler approach exists, say so. Push back when warranted.

### 2. Simplicity first

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked, no abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios, but errors that *can* happen must never
  pass silently: handle them, or let them propagate.
- If you write 200 lines and it could be 50, rewrite it.

These are defaults, not absolutes: a project may legitimately require defensive
checks, a shared abstraction, or a deliberate seam. Follow the project when it does.

### 3. Surgical changes

**Touch only what you must. Clean up only your own mess.**

- Don't "improve" adjacent code, comments, or formatting; don't refactor what isn't broken.
- Match existing style, even if you'd do it differently.
- Notice unrelated dead code or lint findings? Mention them, don't fix them. A whole-tree
  `--fix` on a repo that was never clean produces a diff nobody asked for.
- Remove imports/variables/functions that *your* changes orphaned, and nothing else.

The test: every changed line should trace directly to what the user asked for.

### 4. Goal-driven execution

**Define success criteria. Loop until verified.**

Turn tasks into verifiable goals: "add validation" → "write tests for invalid inputs, then
make them pass"; "fix the bug" → "write a test that reproduces it, then make it pass".
For multi-step work, state the plan as steps with a verification check each.

Watch for goals that can be satisfied the wrong way: if a test compares against recorded
fixtures, "make it pass" is also satisfiable by regenerating the fixtures. Decide
deliberately which one is correct, and say which you chose.
