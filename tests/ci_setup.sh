#!/usr/bin/env bash
# ==============================================================================
# tests/ci_setup.sh — Prepare container environment for CI testing
# ==============================================================================
# Installs sudo, basic dependencies, and configures passwordless sudo
# so that the bootstrap scripts (which use `sudo`) work inside containers.
# ==============================================================================

set -euo pipefail

echo "::group::CI Environment Setup"

# Install sudo if not present (containers often lack it)
if ! command -v sudo &>/dev/null; then
    if command -v apt-get &>/dev/null; then
        apt-get update -qq && apt-get install -y -qq sudo
    elif command -v dnf &>/dev/null; then
        dnf install -y -q sudo
    elif command -v pacman &>/dev/null; then
        pacman -Sy --noconfirm sudo
    fi
fi

# Configure passwordless sudo for the current user
if command -v sudo &>/dev/null; then
    CURRENT_USER="$(whoami)"
    echo "${CURRENT_USER} ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/"${CURRENT_USER}" >/dev/null 2>&1 || true
    chmod 0440 /etc/sudoers.d/"${CURRENT_USER}" 2>/dev/null || true
fi

# Install basic dependencies needed by the bootstrap scripts
if command -v apt-get &>/dev/null; then
    apt-get update -qq
    apt-get install -y -qq curl git bash ca-certificates unzip wget 2>/dev/null || true
elif command -v dnf &>/dev/null; then
    dnf install -y -q curl git bash ca-certificates unzip wget 2>/dev/null || true
elif command -v pacman &>/dev/null; then
    pacman -Sy --noconfirm curl git bash ca-certificates unzip wget 2>/dev/null || true
fi

echo "::endgroup::"
echo "  ✔  CI environment ready"