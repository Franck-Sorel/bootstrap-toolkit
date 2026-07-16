#!/usr/bin/env bash
# ==============================================================================
# config/git.sh — Git global configuration
# ==============================================================================
# Defines: run()
# ==============================================================================

run() {
    if ! has_command git; then
        log_error "git is not installed. Run the system packages step first."
        return 1
    fi

    log_step "Git Configuration"

    # Collect user info
    local current_name current_email
    current_name="$(git config --global user.name 2>/dev/null || echo '')"
    current_email="$(git config --global user.email 2>/dev/null || echo '')"

    local git_name git_email

    if [[ -n "$current_name" ]]; then
        log_info "Current git name: $current_name"
        if ask_yes_no "Change git name?" "n"; then
            printf "  Enter your name: "
            read -r git_name </dev/tty 2>/dev/null || git_name=""
        else
            git_name="$current_name"
        fi
    else
        printf "  Enter your git name: "
        read -r git_name </dev/tty 2>/dev/null || git_name=""
    fi

    if [[ -n "$current_email" ]]; then
        log_info "Current git email: $current_email"
        if ask_yes_no "Change git email?" "n"; then
            printf "  Enter your email: "
            read -r git_email </dev/tty 2>/dev/null || git_email=""
        else
            git_email="$current_email"
        fi
    else
        printf "  Enter your git email: "
        read -r git_email </dev/tty 2>/dev/null || git_email=""
    fi

    # Apply config
    if [[ -n "$git_name" ]]; then
        run_step "Setting git user.name" git config --global user.name "$git_name"
    fi
    if [[ -n "$git_email" ]]; then
        run_step "Setting git user.email" git config --global user.email "$git_email"
    fi

    # Sensible defaults
    run_step "Setting default branch to main" \
        git config --global init.defaultBranch main
    run_step "Setting pull strategy to rebase" \
        git config --global pull.rebase true
    run_step "Enabling colored output" \
        git config --global color.ui auto
    run_step "Setting default editor to nano" \
        git config --global core.editor nano

    # Copy .gitconfig dotfile if available
    local dotfile="$BOOTSTRAP_DIR/dotfiles/.gitconfig"
    if [[ -f "$dotfile" ]]; then
        if ask_yes_no "Copy provided .gitconfig to home directory?" "y"; then
            run_step "Copying .gitconfig" cp "$dotfile" "$HOME/.gitconfig"
        fi
    fi

    return 0
}