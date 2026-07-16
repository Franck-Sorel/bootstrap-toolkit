#!/usr/bin/env bash
# ==============================================================================
# config/vscode-settings.sh — VS Code settings, keybindings, and extensions
# ==============================================================================
# Defines: run()
# ==============================================================================

run() {
    if ! has_command code; then
        log_error "VS Code is not installed. Run the VS Code install step first."
        return 1
    fi

    log_step "VS Code Configuration"

    # Determine settings directory
    local os settings_dir
    os="$(detect_os)"
    case "$os" in
        macos) settings_dir="$HOME/Library/Application Support/Code/User" ;;
        *)     settings_dir="$HOME/.config/Code/User" ;;
    esac
    mkdir -p "$settings_dir"

    # --- Settings ---
    local settings_src="$BOOTSTRAP_DIR/dotfiles/vscode-settings.json"
    if [[ -f "$settings_src" ]]; then
        if ask_yes_no "Copy VS Code settings.json?" "y"; then
            if [[ -f "$settings_dir/settings.json" ]]; then
                run_step "Backing up existing settings.json" \
                    cp "$settings_dir/settings.json" "$settings_dir/settings.json.bak.$(date +%s)"
            fi
            run_step "Copying settings.json" \
                cp "$settings_src" "$settings_dir/settings.json" || {
                log_error "Failed to copy settings.json"
                # Non-fatal
            }
        fi
    fi

    # --- Extensions ---
    # List of recommended extensions
    local extensions=(
        "ms-python.python"
        "ms-azuretools.vscode-docker"
        "ms-kubernetes-tools.vscode-kubernetes-tools"
        "redhat.vscode-yaml"
        "hashicorp.terraform"
        "esbenp.prettier-vscode"
        "dbaeumer.vscode-eslint"
        "golang.go"
        "rust-lang.rust-analyzer"
        "eamodio.gitlens"
        "ms-vscode-remote.remote-containers"
        "GitHub.copilot"
    )

    if ask_yes_no "Install recommended VS Code extensions?" "y"; then
        local installed=0 failed=0
        for ext in "${extensions[@]}"; do
            # Check if already installed
            if code --list-extensions 2>/dev/null | grep -qi "$ext"; then
                log_info "Extension already installed: $ext"
                continue
            fi
            if code --install-extension "$ext" 2>/dev/null; then
                log_success "Installing extension: $ext — done"
                ((installed++))
            else
                log_warn "Could not install: $ext"
                ((failed++))
            fi
        done
        log_info "Extensions: $installed installed, $failed failed"
    fi

    return 0
}