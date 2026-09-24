#!/bin/sh
# Install gitleaks: Homebrew on macOS, otherwise the official GitHub release binary
# (checksum-verified) into ~/.local/bin.
set -eu

if command -v gitleaks >/dev/null 2>&1; then
    echo "gitleaks already installed: $(gitleaks version)"
    exit 0
fi

case "$(uname -s)" in
Darwin)
    command -v brew >/dev/null 2>&1 || { echo "Homebrew not found; install gitleaks manually." >&2; exit 1; }
    brew install gitleaks
    exit 0
    ;;
Linux) os=linux ;;
*) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

case "$(uname -m)" in
x86_64) arch=x64 ;;
aarch64 | arm64) arch=arm64 ;;
*) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

version=$(curl -fsSL https://api.github.com/repos/gitleaks/gitleaks/releases/latest |
    python3 -c "import json, sys; print(json.load(sys.stdin)['tag_name'].lstrip('v'))")
asset="gitleaks_${version}_${os}_${arch}.tar.gz"
base="https://github.com/gitleaks/gitleaks/releases/download/v${version}"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
curl -fsSLO "$base/$asset"
curl -fsSLO "$base/gitleaks_${version}_checksums.txt"
grep " $asset\$" "gitleaks_${version}_checksums.txt" | sha256sum -c -
tar xzf "$asset" gitleaks
mkdir -p "$HOME/.local/bin"
install -m 755 gitleaks "$HOME/.local/bin/gitleaks"
echo "Installed gitleaks $version to ~/.local/bin/gitleaks"
case ":$PATH:" in
*":$HOME/.local/bin:"*) ;;
*) echo "WARNING: ~/.local/bin is not on PATH; the pre-commit hook will not find gitleaks." >&2 ;;
esac
