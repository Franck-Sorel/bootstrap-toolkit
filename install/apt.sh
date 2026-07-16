#!/usr/bin/env bash
# ==============================================================================
# install/apt.sh — System packages via apt (Linux) or brew (macOS)
# ==============================================================================
# Defines: run()
# ==============================================================================

run() {
    local pm
    pm="$(detect_package_manager)"

    # Essential packages common across platforms
    local apt_packages=(
        curl
        git
        build-essential
        unzip
        ca-certificates
        gnupg
        lsb-release
        software-properties-common
        wget
        htop
        tree
        zsh
    )

    local brew_packages=(
        curl
        git
        unzip
        wget
        htop
        tree
        zsh
    )

    case "$pm" in
        apt)
            run_step "Updating package index" sudo apt-get update -y
            for pkg in "${apt_packages[@]}"; do
                if dpkg -s "$pkg" &>/dev/null; then
                    log_info "$pkg already installed"
                else
                    run_step "Installing $pkg" sudo apt-get install -y "$pkg" || \
                        log_warn "Could not install $pkg — continuing"
                fi
            done
            ;;
        brew)
            if ! has_command brew; then
                log_warn "Homebrew not found. Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
                    log_error "Failed to install Homebrew"
                    return 1
                }
            fi
            run_step "Updating Homebrew" brew update
            for pkg in "${brew_packages[@]}"; do
                run_step "Installing $pkg" brew install "$pkg" || \
                    log_warn "Could not install $pkg — continuing"
            done
            ;;
        dnf)
            run_step "Updating packages" sudo dnf update -y
            for pkg in curl git unzip wget htop tree zsh gcc make; do
                run_step "Installing $pkg" sudo dnf install -y "$pkg" || \
                    log_warn "Could not install $pkg — continuing"
            done
            ;;
        pacman)
            run_step "Updating packages" sudo pacman -Syu --noconfirm
            for pkg in curl git unzip wget htop tree zsh base-devel; do
                run_step "Installing $pkg" sudo pacman -S --noconfirm "$pkg" || \
                    log_warn "Could not install $pkg — continuing"
            done
            ;;
        none)
            log_error "No supported package manager found."
            return 1
            ;;
    esac

    return 0
}