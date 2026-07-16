#!/usr/bin/env bash
# ==============================================================================
# install/docker.sh — Docker Engine and Docker Compose
# ==============================================================================
# Defines: run()
# ==============================================================================

run() {
    # Check if already installed
    if has_command docker; then
        log_info "Docker is already installed ($(docker --version))"
        if ask_yes_no "Reinstall/Update Docker?"; then
            : # continue with install
        else
            return 0
        fi
    fi

    local os
    os="$(detect_os)"

    case "$os" in
        macos)
            if has_command brew; then
                run_step "Installing Docker Desktop via Homebrew" \
                    brew install --cask docker || {
                    log_error "Failed to install Docker Desktop"
                    return 1
                }
                log_warn "Docker Desktop installed. Launch it from Applications."
            else
                log_error "Homebrew required to install Docker on macOS."
                return 1
            fi
            ;;
        ubuntu|debian|linuxmint|pop)
            # Official Docker install script
            run_step "Installing Docker via official script" \
                curl -fsSL https://get.docker.com | sudo sh || {
                log_error "Failed to install Docker"
                return 1
            }
            # Add user to docker group
            run_step "Adding user to docker group" \
                sudo usermod -aG docker "$USER" || \
                log_warn "Could not add user to docker group"
            log_warn "You must log out and back in for docker group changes to take effect."
            ;;
        fedora|rhel|centos|rocky|alma)
            run_step "Installing Docker via official script" \
                curl -fsSL https://get.docker.com | sudo sh || {
                log_error "Failed to install Docker"
                return 1
            }
            run_step "Adding user to docker group" \
                sudo usermod -aG docker "$USER" || \
                log_warn "Could not add user to docker group"
            ;;
        *)
            log_error "Unsupported OS for Docker install: $os"
            return 1
            ;;
    esac

    # Verify
    if has_command docker; then
        log_success "Docker installed: $(docker --version)"
    fi

    return 0
}