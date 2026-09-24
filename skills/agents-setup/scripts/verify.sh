#!/bin/sh
# Verify the installed setup end to end in a throwaway repository.
# Prints PASS/FAIL per check; exits non-zero if any check fails.
set -u

fails=0
check() { # check <description> <expected rc> <command...>
    desc=$1; want=$2; shift 2
    "$@" >/dev/null 2>&1
    got=$?
    if { [ "$want" = 0 ] && [ "$got" = 0 ]; } || { [ "$want" != 0 ] && [ "$got" != 0 ]; }; then
        echo "PASS  $desc"
    else
        echo "FAIL  $desc (exit $got)"
        fails=$((fails + 1))
    fi
}

if [ -f "$HOME/.agents/AGENTS.md" ]; then
    echo "== global context"
    for f in "$HOME/.claude/CLAUDE.md" "${CODEX_HOME:-$HOME/.codex}/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"; do
        [ -d "$(dirname "$f")" ] || continue
        check "$f -> ~/.agents/AGENTS.md" 0 test "$(readlink -f "$f")" = "$(readlink -f "$HOME/.agents/AGENTS.md")"
    done
fi

hooks=$(git config --global --get core.hooksPath || true)
if [ "$hooks" = "$HOME/.agents/git-hooks" ]; then
    echo "== git hooks"
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    git init -q --bare "$tmp/remote.git"
    git init -q -b main "$tmp/repo"
    start=$PWD
    cd "$tmp/repo" || exit 1
    # shellcheck disable=SC2317  # g is only called indirectly, through check "$@"
    g() { git -c user.name=verify -c user.email=verify@example.invalid "$@"; }
    echo hello > a.txt && git add a.txt
    check "clean commit passes" 0 g commit -qm "test: clean"
    # Fake token assembled at runtime so this file itself does not trip secret scanners.
    printf 'token = "%s%s"\n' "ghp_" "$(head -c 300 /dev/urandom | tr -dc A-Za-z0-9 | head -c 36)" > b.py
    git add b.py
    check "commit with a secret is blocked" 1 g commit -qm "test: secret"
    git reset -q HEAD b.py && rm b.py
    git remote add origin "$tmp/remote.git"
    check "push to a feature branch passes" 0 g push -q origin main:feature
    protected=$(git config --get agents.protectedBranches) || protected="main master"
    if [ -n "$protected" ]; then
        branch=${protected%% *}
        check "push to protected branch '$branch' is blocked" 1 g push -q origin "main:$branch"
    else
        echo "SKIP  push to a protected branch (protection disabled: agents.protectedBranches is empty)"
    fi
    cd "$start" || exit 1
fi

rules="${CODEX_HOME:-$HOME/.codex}/rules/guardrails.rules"
if command -v codex >/dev/null 2>&1 && [ -f "$rules" ]; then
    echo "== codex rules"
    decision() { codex execpolicy check -r "$rules" "$@" | python3 -c "import json,sys; print(json.load(sys.stdin).get('decision'))"; }
    check "codex: git push --force is forbidden" 0 test "$(decision git push --force origin x)" = forbidden
    check "codex: git push asks" 0 test "$(decision git push origin x)" = prompt
fi

if [ -f "$HOME/.claude/settings.json" ]; then
    echo "== claude settings"
    check "claude: settings.json is valid JSON with deny rules" 0 python3 -c "
import json, pathlib
d = json.loads((pathlib.Path.home() / '.claude/settings.json').read_text())
assert 'Bash(git push --force *)' in d['permissions']['deny']"
fi

if [ -f "$HOME/.config/opencode/opencode.json" ]; then
    echo "== opencode config"
    check "opencode: opencode.json is valid JSON with deny rules" 0 python3 -c "
import json, pathlib
d = json.loads((pathlib.Path.home() / '.config/opencode/opencode.json').read_text())
assert d['permission']['bash']['git push --force *'] == 'deny'"
fi

echo
[ "$fails" = 0 ] && echo "All checks passed." || echo "$fails check(s) failed."
exit "$fails"
