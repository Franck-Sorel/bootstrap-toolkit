#!/usr/bin/env bash
# ==============================================================================
# bootstrap.sh — Entry point for the bootstrap toolkit
# ==============================================================================
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<org>/<repo>/main/bootstrap.sh | bash
#
# Or clone and run locally:
#   ./bootstrap.sh
#
# Environment variables:
#   NONINTERACTIVE=1   Run with defaults (for CI/automation)
#   BOOTSTRAP_DIR      Override the working directory (default: script dir)
# ==============================================================================

set -u

# ------------------------------------------------------------------------------
# Determine script directory (works for both piped and local execution)
# ------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]:-$0}" == "bootstrap.sh" ]] && [[ ! -f "lib/common.sh" ]]; then
    # Likely piped from curl — clone the repo first
    BOOTSTRAP_REPO="${BOOTSTRAP_REPO:-https://github.com/your-org/bootstrap-toolkit.git}"
    BOOTSTRAP_TMPDIR="$(mktemp -d)"
    trap 'rm -rf "$BOOTSTRAP_TMPDIR"' EXIT

    log_info "Bootstrapping from remote repository..."
    if ! git clone --depth 1 "$BOOTSTRAP_REPO" "$BOOTSTRAP_TMPDIR" 2>/dev/null; then
        echo "  ✖  Failed to clone repository. Please run manually:" >&2
        echo "     git clone $BOOTSTRAP_REPO && cd bootstrap-toolkit && ./bootstrap.sh" >&2
        exit 1
    fi
    cd "$BOOTSTRAP_TMPDIR" || exit 1
    BOOTSTRAP_DIR="$BOOTSTRAP_TMPDIR"
else
    BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)}"
    cd "$BOOTSTRAP_DIR" || exit 1
fi

export BOOTSTRAP_DIR

# ------------------------------------------------------------------------------
# Source shared library
# ------------------------------------------------------------------------------
# shellcheck source=lib/common.sh
source "$BOOTSTRAP_DIR/lib/common.sh"

# ------------------------------------------------------------------------------
# Banner
# ------------------------------------------------------------------------------
print_banner() {
    cat <<'BANNER'

  ╔═══════════════════════════════════════════════════╗
  ║          🛠  Bootstrap Toolkit  🛠                ║
  ║                                                   ║
  ║  Interactive developer environment setup.        ║
  ║  Each step will ask before installing.           ║
  ║  Press Enter for the default, or type y/n.       ║
  ╚═══════════════════════════════════════════════════╝

BANNER
}

# ------------------------------------------------------------------------------
# Define the pipeline of steps
# Each entry: "script_path|step_name|default_yes_no"
# ------------------------------------------------------------------------------
STEPS=(
    "install/apt.sh|System packages (apt/brew)|y"
    "install/docker.sh|Docker|y"
    "install/kubernetes.sh|Kubernetes tools (kubectl, helm)|n"
    "install/vscode.sh|Visual Studio Code|y"
    "install/devtools.sh|Developer tools (jq, fzf, tmux, etc.)|n"
    "install/nodejs.sh|Node.js, npm, pnpm & global packages|n"
    "install/ollama.sh|Ollama (local LLM runner)|n"
    "install/fonts.sh|Nerd Fonts|n"
    "config/git.sh|Git configuration|y"
    "config/ssh.sh|SSH key generation|n"
    "config/shell.sh|Shell configuration (zsh)|y"
    "config/vscode-settings.sh|VS Code settings & extensions|n"
)

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
    print_banner

    local os pm
    os="$(detect_os)"
    pm="$(detect_package_manager)"
    log_info "Detected OS: $os"
    log_info "Detected package manager: $pm"
    echo ""

    if ! ask_yes_no "Proceed with bootstrap on this system?"; then
        log_warn "Bootstrap cancelled by user."
        exit 0
    fi

    for step in "${STEPS[@]}"; do
        IFS='|' read -r script name default <<< "$step"
        local script_path="$BOOTSTRAP_DIR/$script"

        log_step "$name"

        if ask_yes_no "Install: $name?" "$default"; then
            if source_if_exists "$script_path"; then
                # Each script defines a run() function — call it
                if declare -F run &>/dev/null; then
                    if run; then
                        record_result "$name" "ok"
                    else
                        record_result "$name" "failed"
                        log_warn "Step '$name' failed. Continuing to next step."
                    fi
                    # Unset run so the next script can define its own
                    unset -f run 2>/dev/null || true
                else
                    log_error "Script $script did not define a run() function."
                    record_result "$name" "failed"
                fi
            else
                record_result "$name" "failed"
            fi
        else
            log_info "Skipping: $name"
            record_result "$name" "skipped"
        fi
    done

    print_summary

    log_success "Bootstrap complete! You may need to restart your shell."
}

main "$@"