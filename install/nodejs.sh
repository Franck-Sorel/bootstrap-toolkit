#!/usr/bin/env bash
# ==============================================================================
# install/nodejs.sh — Node.js ecosystem: Node.js + npm, pnpm, global packages
# ==============================================================================
# Defines: run()
# ==============================================================================
# Installs:
#   - Node.js LTS + npm (NodeSource on Debian/Ubuntu, native packages elsewhere)
#   - pnpm (via corepack, with npm fallback)
#   - A curated set of global npm packages (each offered interactively)
# ==============================================================================

run() {
    local pm
    pm="$(detect_package_manager)"

    local failed=0
    local install_node=0

    log_step "Node.js ecosystem"

    # --------------------------------------------------------------------------
    # Node.js + npm
    # --------------------------------------------------------------------------
    if has_command node; then
        log_info "Node.js already installed ($(node --version 2>/dev/null))"
        if ask_yes_no "Reinstall Node.js?" "n"; then
            install_node=1
        fi
    else
        if ask_yes_no "Install Node.js (LTS) + npm?" "y"; then
            install_node=1
        fi
    fi

    if [[ $install_node -eq 1 ]]; then
        case "$pm" in
            apt)
                run_step "Adding NodeSource LTS repository" \
                    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - || {
                    log_error "Failed to add NodeSource repository"
                    ((failed++))
                }
                if [[ $failed -eq 0 ]]; then
                    run_step "Installing Node.js + npm" \
                        sudo apt-get install -y nodejs || {
                        log_error "Failed to install Node.js"
                        ((failed++))
                    }
                fi
                ;;
            dnf)
                run_step "Installing Node.js + npm" \
                    sudo dnf install -y nodejs npm || {
                    log_error "Failed to install Node.js"
                    ((failed++))
                }
                ;;
            pacman)
                run_step "Installing Node.js + npm" \
                    sudo pacman -S --noconfirm nodejs npm || {
                    log_error "Failed to install Node.js"
                    ((failed++))
                }
                ;;
            brew)
                run_step "Installing Node.js via Homebrew" \
                    brew install node || {
                    log_error "Failed to install Node.js"
                    ((failed++))
                }
                ;;
            *)
                log_error "Cannot install Node.js — no supported package manager"
                ((failed++))
                ;;
        esac
    fi

    # Nothing else to do if Node.js is not available
    if ! has_command node; then
        log_warn "Node.js not available — skipping pnpm and global packages"
        [[ $failed -eq 0 ]]
        return $?
    fi

    if ! has_command npm; then
        log_warn "npm not available — skipping pnpm and global packages"
        [[ $failed -eq 0 ]]
        return $?
    fi

    log_info "Node.js: $(node --version 2>/dev/null) | npm: $(npm --version 2>/dev/null)"

    # npm installs globally to a system prefix on Linux (needs sudo) but to a
    # user-owned prefix with Homebrew on macOS (no sudo).
    local sudo_prefix=""
    if [[ "$pm" != "brew" ]]; then
        sudo_prefix="sudo"
    fi

    # --------------------------------------------------------------------------
    # pnpm
    # --------------------------------------------------------------------------
    if has_command pnpm; then
        log_info "pnpm already installed ($(pnpm --version 2>/dev/null))"
        if ! ask_yes_no "Reinstall pnpm?" "n"; then
            : # skip
        else
            _install_pnpm
        fi
    else
        if ask_yes_no "Install pnpm?" "y"; then
            _install_pnpm
        fi
    fi

    # --------------------------------------------------------------------------
    # Global npm packages (curated list — edit to suit your needs)
    # --------------------------------------------------------------------------
    # Each package is offered individually so the user can pick what they want.
    local -a global_packages=(
        "typescript"
        "tsx"
        "prettier"
        "eslint"
        "serve"
        "http-server"
        "neovim"   # required by Neovim's node provider
    )

    if ask_yes_no "Install curated global npm packages? (typescript, prettier, eslint, ...)" "n"; then
        local pkg
        for pkg in "${global_packages[@]}"; do
            if ask_yes_no "Install global package '$pkg'?" "n"; then
                # shellcheck disable=SC2086
                run_step "Installing $pkg" $sudo_prefix npm install -g "$pkg" || {
                    log_warn "Could not install $pkg"
                    ((failed++))
                }
            fi
        done
    fi

    [[ $failed -eq 0 ]]
}

# ------------------------------------------------------------------------------
# Helper: install/activate pnpm via corepack, with npm fallback
# ------------------------------------------------------------------------------
_install_pnpm() {
    local failed=0

    # corepack ships with Node.js >= 16.9 and is the official way to manage
    # pnpm/yarn versions. Prefer it; fall back to `npm install -g pnpm`.
    if has_command corepack; then
        run_step "Enabling corepack" sudo corepack enable || {
            log_warn "corepack enable failed — will try npm fallback"
            ((failed++))
        }
        if [[ $failed -eq 0 ]]; then
            run_step "Activating pnpm via corepack" \
                sudo corepack prepare pnpm@latest --activate || {
                log_warn "corepack prepare failed — will try npm fallback"
                ((failed++))
            }
        fi
    else
        ((failed++))
    fi

    if [[ $failed -ne 0 ]]; then
        log_info "Falling back to npm to install pnpm"
        local sudo_prefix=""
        if [[ "$(detect_package_manager)" != "brew" ]]; then
            sudo_prefix="sudo"
        fi
        # shellcheck disable=SC2086
        run_step "Installing pnpm via npm" $sudo_prefix npm install -g pnpm || {
            log_error "Failed to install pnpm"
            return 1
        }
    fi

    if has_command pnpm; then
        log_success "pnpm installed ($(pnpm --version 2>/dev/null))"
    else
        log_error "pnpm was not installed"
        return 1
    fi
}