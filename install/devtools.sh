#!/usr/bin/env bash
# ==============================================================================
# install/devtools.sh — Developer CLI tools (jq, fzf, tmux, ripgrep, etc.)
# ==============================================================================
# Defines: run()
# ==============================================================================

run() {
    local pm os
    pm="$(detect_package_manager)"
    os="$(detect_os)"

    local failed=0

    # Tools to install — each is optional and individually guarded
    install_tool() {
        local name="$1"
        local apt_name="${2:-$1}"
        local brew_name="${3:-$1}"
        local dnf_name="${4:-$1}"
        local pacman_name="${5:-$1}"

        if has_command "$name"; then
            log_info "$name already installed"
            return 0
        fi

        if ! ask_yes_no "Install $name?" "n"; then
            return 0
        fi

        case "$pm" in
            apt)    run_step "Installing $name" sudo apt-get install -y "$apt_name" || ((failed++)) ;;
            brew)   run_step "Installing $name" brew install "$brew_name" || ((failed++)) ;;
            dnf)    run_step "Installing $name" sudo dnf install -y "$dnf_name" || ((failed++)) ;;
            pacman) run_step "Installing $name" sudo pacman -S --noconfirm "$pacman_name" || ((failed++)) ;;
            *)      log_error "Cannot install $name — no package manager"; ((failed++)) ;;
        esac
    }

    log_step "Developer Tools"

    install_tool jq
    install_tool fzf
    install_tool tmux
    install_tool ripgrep rg ripgrep ripgrep ripgrep
    install_tool fd fdfind fd fd-find fd
    install_tool bat bat bat bat bat
    install_tool neovim nvim neovim neovim neovim
    install_tool lazygit
    install_tool delta git-delta git-delta git-delta git-delta

    # Node.js via nvm (special handling)
    if has_command node; then
        log_info "Node.js already installed ($(node --version))"
    else
        if ask_yes_no "Install Node.js via nvm?" "n"; then
            run_step "Installing nvm" \
                curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash || {
                log_error "Failed to install nvm"
                ((failed++))
            }
            # Source nvm and install LTS
            if [[ -f "$HOME/.nvm/nvm.sh" ]]; then
                # shellcheck disable=SC1091
                source "$HOME/.nvm/nvm.sh"
                run_step "Installing Node.js LTS" nvm install --lts || ((failed++))
            fi
        fi
    fi

    # Python via pyenv (special handling)
    if has_command python3; then
        log_info "Python3 already installed ($(python3 --version))"
    else
        if ask_yes_no "Install Python via pyenv?" "n"; then
            run_step "Installing pyenv" \
                curl -fsSL https://pyenv.run | bash || {
                log_error "Failed to install pyenv"
                ((failed++))
            }
        fi
    fi

    [[ $failed -eq 0 ]]
}