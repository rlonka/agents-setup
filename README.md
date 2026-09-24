# agents-setup

Skill, který na tvém stroji nastaví sdílené prostředí pro AI coding agenty
**Claude Code, Codex a OpenCode** — tak, aby se všechny tři řídily stejnými pravidly:

| Modul | Co udělá |
|---|---|
| **A. Globální context** | Jeden `~/.agents/AGENTS.md`, na který ukazují symlinky `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.config/opencode/AGENTS.md` |
| **B. Sdílené skilly** | `~/.agents/skills/`, pro Claude Code zpřístupněné symlinky |
| **C. Git hooky** | Globální `core.hooksPath`: gitleaks kontrola tajemství při commitu, volitelně zákaz push na `main`/`master`; hooky jednotlivých repozitářů fungují dál |
| **D. Guardrails** | Jeden `~/.agents/guardrails.yaml` → deny/ask pravidla vygenerovaná do konfigurace všech tří nástrojů |

Skill nejdřív zjistí stav, zeptá se na volby (moduly, commit konvence, chráněné větve),
**všechno zazálohuje** do `~/.agents/backup/<čas>/`, existující context soubory **sloučí**
(nepřepíše), nastaví vybrané moduly, projde tvoje stávající konfigurace (např. tokeny
uložené v pravidlech po „always allow“) a nakonec vše **ověří** v dočasném repu.

## Instalace

```bash
DISABLE_TELEMETRY=1 npx skills add git@code.it4i.cz:radekl/agents-setup.git -g
```

- SSH, protože repo je interní a klon přes HTTPS vyžaduje přihlášení. HTTPS
  (`https://code.it4i.cz/radekl/agents-setup.git`) funguje jen s nastaveným git credential
  helperem.
- `DISABLE_TELEMETRY=1`: Skills CLI u zdrojů mimo veřejný GitHub může v telemetrii
  odeslat URL repozitáře.

## Spuštění

Skill se spouští **jen na výslovné vyžádání** — v kterémkoli ze tří nástrojů napiš např.
*„spusť skill agents-setup“* (v Claude Code `/agents-setup`).

## Požadavky

- git, Python 3 s PyYAML (nebo `uv`), `curl`
- Linux (x64/arm64) nebo macOS s Homebrew — kvůli instalaci gitleaks

## Vrácení

```bash
git config --global --unset core.hooksPath      # git hooky off
# guardrails: vyprázdni seznamy v ~/.agents/guardrails.yaml a spusť znovu
python3 ~/.agents/sync-guardrails.py
# context soubory: obnov ze zálohy v ~/.agents/backup/<čas>/
```

## Obsah repa

```
skills/agents-setup/
├── SKILL.md                    postup pro agenta
├── templates/
│   ├── AGENTS.md               šablona globálního contextu
│   └── guardrails.yaml         výchozí pravidla
└── scripts/
    ├── run-hook                dispatcher git hooků
    ├── install-git-hooks.sh
    ├── install-gitleaks.sh
    ├── sync-guardrails.py      guardrails.yaml → Claude / Codex / OpenCode
    └── verify.sh               end-to-end ověření
```
