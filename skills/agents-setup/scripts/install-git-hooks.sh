#!/bin/sh
# Install the global git hook dispatcher into ~/.agents/git-hooks and enable it
# with core.hooksPath. Refuses to replace a core.hooksPath that points elsewhere.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
dest="$HOME/.agents/git-hooks"
hooks="applypatch-msg pre-applypatch post-applypatch pre-commit pre-merge-commit
prepare-commit-msg commit-msg post-commit pre-rebase post-checkout post-merge pre-push
post-rewrite pre-auto-gc push-to-checkout sendemail-validate post-index-change"

current=$(git config --global --get core.hooksPath || true)
if [ -n "$current" ] && [ "$current" != "$dest" ]; then
    echo "core.hooksPath is already set to '$current'; not overriding it." >&2
    exit 2
fi

mkdir -p "$dest"
install -m 755 "$here/run-hook" "$dest/run-hook"
for h in $hooks; do
    ln -sf run-hook "$dest/$h"
done
git config --global core.hooksPath "$dest"
echo "Installed git hooks in $dest (core.hooksPath set)."
