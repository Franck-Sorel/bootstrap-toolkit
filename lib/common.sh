#!/usr/bin/env bash
# ==============================================================================
# lib/common.sh — Shared functions for the bootstrap toolkit
# ==============================================================================
# This file is sourced by bootstrap.sh and every install/config script.
# It provides: logging, prompt helpers, OS detection, and error guards.
# ==============================================================================

# ------------------------------------------------------------------------------
# Strict mode (but don't exit on error — we handle errors gracefully)
# ------------------------------------------------------------------------------
set -u
# NOTE: We intentionally do NOT use `set -e` here. Each step manages its own
# errors so the user can choose to continue or skip on failure.

# ------------------------------------------------------------------------------
# Color codes (disabled if not a TTY)
# ------------------------------------------------------------------------------
if [[ -t 1 ]]; then
    readonly CLR_RED='\033[0;31m'
    readonly CLR_GREEN='\033[0;32m'
    readonly CLR_YELLOW='\033[1;33m'
    readonly CLR_BLUE='\033[0;34m'
    readonly CLR_BOLD='\033[1m'
    readonly CLR_RESET='\033[0m'
else
    readonly CLR_RED=''
    readonly CLR_GREEN=''
    readonly CLR_YELLOW=''
    readonly CLR_BLUE=''
    readonly CLR_BOLD=''
    readonly CLR_RESET=''
fi

# ------------------------------------------------------------------------------
# Logging helpers
# ------------------------------------------------------------------------------
log_info()    { printf "${CLR_BLUE}  ℹ${CLR_RESET}  %s\n" "$*"; }
log_success() { printf "${CLR_GREEN}  ✔${CLR_RESET}  %s\n" "$*"; }
log_warn()    { printf "${CLR_YELLOW}  ⚠${CLR_RESET}  %s\n" "$*"; }
log_error()   { printf "${CLR_RED}  ✖${CLR_RESET}  %s\n" "$*" >&2; }
log_step()    { printf "\n${CLR_BOLD}${CLR_BLUE}━━━ %s ━━━${CLR_RESET}\n" "$*"; }

# ------------------------------------------------------------------------------
# Prompt helpers — the heart of the interactive experience
# ------------------------------------------------------------------------------
# ask_yes_no "Prompt message" [default: n]
# Returns 0 for yes, 1 for no. Honors $NONINTERACTIVE env var for CI.
ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local default_hint

    if [[ "$default" == "y" ]]; then
        default_hint="Y/n"
    else
        default_hint="y/N"
    fi

    # Non-interactive mode (CI, automation): use default
    if [[ "${NONINTERACTIVE:-}" == "1" ]]; then
        if [[ "$default" == "y" ]]; then
            log_info "$prompt [auto: yes]"
            return 0
        else
            log_info "$prompt [auto: no]"
            return 1
        fi
    fi

    local answer
    while true; do
        printf "${CLR_BOLD}  ?${CLR_RESET}  %s [%s] " "$prompt" "$default_hint"
        read -r answer </dev/tty 2>/dev/null || answer="$default"
        answer="${answer:-$default}"

        case "$(echo "$answer" | tr '[:upper:]' '[:lower:]')" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *)     log_warn "Please answer 'y' or 'n'." ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# Error handling — run a command, report, and let the caller decide
# ------------------------------------------------------------------------------
# run_step "description" command...
# Returns the exit code of the command. Logs success/failure.
run_step() {
    local desc="$1"; shift
    log_info "$desc..."
    if "$@"; then
        log_success "$desc — done"
        return 0
    else
        local rc=$?
        log_error "$desc — failed (exit $rc)"
        return $rc
    fi
}

# ------------------------------------------------------------------------------
# OS detection
# ------------------------------------------------------------------------------
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

detect_package_manager() {
    local os
    os="$(detect_os)"
    case "$os" in
        macos)     echo "brew" ;;
        ubuntu|debian|linuxmint|pop)
            if command -v apt-get &>/dev/null; then echo "apt"; else echo "none"; fi ;;
        fedora|rhel|centos|rocky|alma)
            if command -v dnf &>/dev/null; then echo "dnf"; else echo "none"; fi ;;
        arch|manjaro)
            if command -v pacman &>/dev/null; then echo "pacman"; else echo "none"; fi ;;
        *) echo "none" ;;
    esac
}

# ------------------------------------------------------------------------------
# Dependency check — is a command available?
# ------------------------------------------------------------------------------
has_command() {
    command -v "$1" &>/dev/null
}

require_command() {
    if ! has_command "$1"; then
        log_error "Required command not found: $1"
        return 1
    fi
    return 0
}

# ------------------------------------------------------------------------------
# Safe source — source a file only if it exists
# ------------------------------------------------------------------------------
source_if_exists() {
    if [[ -f "$1" ]]; then
        # shellcheck disable=SC1090
        source "$1"
        return 0
    else
        log_warn "File not found, skipping: $1"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Summary tracker — collect results across all steps
# ------------------------------------------------------------------------------
declare -a _RESULTS=()
declare -a _STEP_NAMES=()

record_result() {
    local name="$1"
    local status="$2"  # "ok" | "skipped" | "failed"
    _STEP_NAMES+=("$name")
    _RESULTS+=("$status")
}

print_summary() {
    log_step "Summary"
    local ok=0 skipped=0 failed=0
    for i in "${!_STEP_NAMES[@]}"; do
        local name="${_STEP_NAMES[$i]}"
        local status="${_RESULTS[$i]}"
        case "$status" in
            ok)     log_success "$name"; ((ok++)) ;;
            skipped) log_info "$name (skipped)"; ((skipped++)) ;;
            failed) log_error "$name"; ((failed++)) ;;
        esac
    done
    printf "\n${CLR_BOLD}  %d succeeded, %d skipped, %d failed${CLR_RESET}\n\n" \
        "$ok" "$skipped" "$failed"
}