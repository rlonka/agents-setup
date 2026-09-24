#!/bin/sh
# Install (or update) the agent-workflow skills: clone the repository into
# ~/.agents/src/agent-workflow, link each skill into ~/.agents/skills (and ~/.claude/skills
# when Claude Code is present), and copy the OpenCode commands when OpenCode is present.
# A skill name that already exists and doesn't point into that clone (installed another
# way, or linked to a working copy) is skipped and reported.
set -eu

repo="https://github.com/rlonka/agent-workflow.git"
src="$HOME/.agents/src/agent-workflow"

if [ -d "$src/.git" ]; then
    git -C "$src" pull -q --ff-only
else
    mkdir -p "$(dirname "$src")"
    git clone -q "$repo" "$src"
fi

mkdir -p "$HOME/.agents/skills"
for dir in "$src"/skills/*/; do
    name=$(basename "$dir")
    target="$HOME/.agents/skills/$name"
    if [ -e "$target" ] || [ -L "$target" ]; then
        case "$(readlink "$target" || true)" in
        "$src"/*) ;;
        *)
            echo "skipped $name: $target exists and is not a link into $src" >&2
            continue
            ;;
        esac
    fi
    ln -sfn "$src/skills/$name" "$target"
    if [ -d "$HOME/.claude" ]; then
        mkdir -p "$HOME/.claude/skills"
        link="$HOME/.claude/skills/$name"
        if [ -e "$link" ] && [ ! -L "$link" ]; then
            echo "skipped Claude Code link for $name: $link exists and is not a symlink" >&2
        else
            ln -sfn "../../.agents/skills/$name" "$link"
        fi
    fi
done

if [ -d "$HOME/.config/opencode" ]; then
    mkdir -p "$HOME/.config/opencode/commands"
    cp "$src"/opencode/commands/*.md "$HOME/.config/opencode/commands/"
fi

echo "agent-workflow $(git -C "$src" rev-parse --short HEAD) installed from $src"
