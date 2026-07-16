#!/usr/bin/env bash
# ==============================================================================
# config/shell.sh — Shell configuration (zsh + oh-my-zsh)
# ==============================================================================
# Defines: run()
# ==============================================================================

run() {
    log_step "Shell Configuration"

    # Check if zsh is installed
    if ! has_command zsh; then
        log_warn "zsh is not installed. Installing..."
        local pm
        pm="$(detect_package_manager)"
        case "$pm" in
            apt)    sudo apt-get install -y zsh ;;
            brew)   brew install zsh ;;
            dnf)    sudo dnf install -y zsh ;;
            pacman) sudo pacman -S --noconfirm zsh ;;
            *)      log_error "Cannot install zsh — no package manager"; return 1 ;;
        esac
    fi

    # Check/change default shell
    local current_shell
    current_shell="$(basename "$SHELL")"
    if [[ "$current_shell" != "zsh" ]]; then
        log_info "Current shell: $current_shell"
        if ask_yes_no "Set zsh as default shell?" "y"; then
            local zsh_path
            zsh_path="$(command -v zsh)"
            if [[ -n "$zsh_path" ]]; then
                # Add zsh to /etc/shells if not present
                if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
                    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null 2>&1 || \
                        log_warn "Could not add $zsh_path to /etc/shells"
                fi
                run_step "Changing default shell to zsh" \
                    chsh -s "$zsh_path" || log_warn "Could not change default shell. Run: chsh -s $zsh_path"
            fi
        fi
    else
        log_info "zsh is already your default shell"
    fi

    # Install Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        if ask_yes_no "Install Oh My Zsh?" "y"; then
            run_step "Installing Oh My Zsh" \
                sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || {
                log_error "Failed to install Oh My Zsh"
                # Continue anyway — not critical
            }
        fi
    else
        log_info "Oh My Zsh already installed"
    fi

    # Install useful zsh plugins
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    local plugins_installed=0

    # zsh-autosuggestions
    if [[ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]]; then
        if ask_yes_no "Install zsh-autosuggestions plugin?" "y"; then
            run_step "Installing zsh-autosuggestions" \
                git clone https://github.com/zsh-users/zsh-autosuggestions \
                    "$zsh_custom/plugins/zsh-autosuggestions" 2>/dev/null || \
                log_warn "Could not install zsh-autosuggestions"
            ((plugins_installed++))
        fi
    fi

    # zsh-syntax-highlighting
    if [[ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]]; then
        if ask_yes_no "Install zsh-syntax-highlighting plugin?" "y"; then
            run_step "Installing zsh-syntax-highlighting" \
                git clone https://github.com/zsh-users/zsh-syntax-highlighting \
                    "$zsh_custom/plugins/zsh-syntax-highlighting" 2>/dev/null || \
                log_warn "Could not install zsh-syntax-highlighting"
            ((plugins_installed++))
        fi
    fi

    # Copy .zshrc dotfile
    local dotfile="$BOOTSTRAP_DIR/dotfiles/.zshrc"
    if [[ -f "$dotfile" ]]; then
        if [[ -f "$HOME/.zshrc" ]]; then
            if ask_yes_no "Backup existing .zshrc and replace with provided one?" "y"; then
                run_step "Backing up .zshrc" cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%s)"
                run_step "Copying .zshrc" cp "$dotfile" "$HOME/.zshrc"
            fi
        else
            if ask_yes_no "Copy provided .zshrc to home directory?" "y"; then
                run_step "Copying .zshrc" cp "$dotfile" "$HOME/.zshrc"
            fi
        fi
    fi

    return 0
}