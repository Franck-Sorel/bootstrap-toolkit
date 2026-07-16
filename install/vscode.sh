#!/usr/bin/env bash
# ==============================================================================
# install/vscode.sh — Visual Studio Code
# ==============================================================================
# Defines: run()
# ==============================================================================

run() {
    if has_command code; then
        log_info "VS Code is already installed ($(code --version 2>/dev/null | head -1))"
        if ! ask_yes_no "Reinstall VS Code?"; then
            return 0
        fi
    fi

    local os
    os="$(detect_os)"

    case "$os" in
        macos)
            if has_command brew; then
                run_step "Installing VS Code via Homebrew Cask" \
                    brew install --cask visual-studio-code || {
                    log_error "Failed to install VS Code"
                    return 1
                }
            else
                log_error "Homebrew required to install VS Code on macOS."
                return 1
            fi
            ;;
        ubuntu|debian|linuxmint|pop)
            run_step "Installing VS Code .deb from Microsoft" \
                curl -fsSL "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -o /tmp/vscode.deb || {
                log_error "Failed to download VS Code"
                return 1
            }
            run_step "Installing VS Code package" \
                sudo apt-get install -y /tmp/vscode.deb || {
                log_error "Failed to install VS Code package"
                return 1
            }
            rm -f /tmp/vscode.deb
            ;;
        fedora|rhel|centos|rocky|alma)
            run_step "Installing VS Code .rpm from Microsoft" \
                curl -fsSL "https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64" -o /tmp/vscode.rpm || {
                log_error "Failed to download VS Code"
                return 1
            }
            run_step "Installing VS Code package" \
                sudo dnf install -y /tmp/vscode.rpm || {
                log_error "Failed to install VS Code package"
                return 1
            }
            rm -f /tmp/vscode.rpm
            ;;
        *)
            log_error "Unsupported OS for VS Code: $os"
            return 1
            ;;
    esac

    if has_command code; then
        log_success "VS Code installed: $(code --version 2>/dev/null | head -1)"
    fi

    return 0
}