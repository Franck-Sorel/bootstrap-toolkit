#!/usr/bin/env bash
# ==============================================================================
# tests/test_shellcheck.sh — Run shellcheck on all scripts
# ==============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "Running shellcheck on all scripts..."
echo ""

files=(
    "$REPO_DIR/bootstrap.sh"
    "$REPO_DIR/lib/common.sh"
    "$REPO_DIR/install/apt.sh"
    "$REPO_DIR/install/docker.sh"
    "$REPO_DIR/install/kubernetes.sh"
    "$REPO_DIR/install/vscode.sh"
    "$REPO_DIR/install/devtools.sh"
    "$REPO_DIR/install/fonts.sh"
    "$REPO_DIR/config/git.sh"
    "$REPO_DIR/config/ssh.sh"
    "$REPO_DIR/config/shell.sh"
    "$REPO_DIR/config/vscode-settings.sh"
)

if ! command -v shellcheck &>/dev/null; then
    echo "  ✖  shellcheck is not installed. Install it first:"
    echo "     sudo apt-get install shellcheck   # Debian/Ubuntu"
    echo "     brew install shellcheck            # macOS"
    exit 1
fi

failed=0
for f in "${files[@]}"; do
    if [[ ! -f "$f" ]]; then
        echo "  ⚠  File not found: $f"
        continue
    fi
    if shellcheck -x "$f"; then
        echo "  ✔  $f"
    else
        echo "  ✖  $f"
        ((failed++))
    fi
done

echo ""
if [[ $failed -eq 0 ]]; then
    echo "  ✔  All scripts passed shellcheck."
    exit 0
else
    echo "  ✖  $failed file(s) failed shellcheck."
    exit 1
fi