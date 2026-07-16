#!/usr/bin/env bash
# ==============================================================================
# tests/ci_run_script.sh — Run a single bootstrap script in CI mode
# ==============================================================================
# Usage: ci_run_script.sh <script_path>
#
# Sources lib/common.sh + the target script, then calls run().
# Sets NONINTERACTIVE=1 and BOOTSTRAP_DIR automatically.
# Exits with the run() return code.
# ==============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

export BOOTSTRAP_DIR="$REPO_DIR"
export NONINTERACTIVE=1

TARGET="$1"

if [[ -z "$TARGET" ]]; then
    echo "  ✖  Usage: ci_run_script.sh <script_path>"
    exit 1
fi

# Resolve relative paths against the repo root
if [[ "$TARGET" != /* ]]; then
    TARGET="$REPO_DIR/$TARGET"
fi

if [[ ! -f "$TARGET" ]]; then
    echo "  ✖  Script not found: $TARGET"
    exit 1
fi

echo "::group::Testing $(basename "$TARGET")"

# Source the shared library
# shellcheck source=lib/common.sh
source "$REPO_DIR/lib/common.sh"

# Source the target script
# shellcheck disable=SC1090
source "$TARGET"

# Verify run() is defined
if ! declare -F run &>/dev/null; then
    echo "  ✖  FAIL: $TARGET does not define run()"
    exit 1
fi

echo "  ℹ  Running run() from $(basename "$TARGET")..."
if run; then
    echo "  ✔  PASS: $(basename "$TARGET")"
    echo "::endgroup::"
    exit 0
else
    rc=$?
    echo "  ✖  FAIL: $(basename "$TARGET") (exit $rc)"
    echo "::endgroup::"
    exit "$rc"
fi