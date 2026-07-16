#!/usr/bin/env bash
# ==============================================================================
# config/ssh.sh — SSH key generation and configuration
# ==============================================================================
# Defines: run()
# ==============================================================================

run() {
    local ssh_dir="$HOME/.ssh"

    log_step "SSH Configuration"

    # Create .ssh directory
    if [[ ! -d "$ssh_dir" ]]; then
        run_step "Creating ~/.ssh directory" \
            mkdir -p "$ssh_dir" && chmod 700 "$ssh_dir"
    else
        log_info "$HOME/.ssh already exists"
    fi

    # Check for existing keys
    local existing_keys=()
    if [[ -d "$ssh_dir" ]]; then
        for key in "$ssh_dir"/id_*; do
            [[ -f "$key" ]] && existing_keys+=("$(basename "$key")")
        done
    fi

    if [[ ${#existing_keys[@]} -gt 0 ]]; then
        log_info "Existing SSH keys found: ${existing_keys[*]}"
        if ! ask_yes_no "Generate a new SSH key?" "n"; then
            return 0
        fi
    else
        if ! ask_yes_no "No SSH keys found. Generate one?" "y"; then
            return 0
        fi
    fi

    # Collect key details
    local key_type key_comment key_path

    printf "  Key type [ed25519/rsa] (default: ed25519): "
    read -r key_type </dev/tty 2>/dev/null || key_type=""
    key_type="${key_type:-ed25519}"

    local default_comment
    default_comment="${USER}@$(hostname 2>/dev/null || echo localhost)"
    printf "  Comment (default: %s): " "$default_comment"
    read -r key_comment </dev/tty 2>/dev/null || key_comment=""
    key_comment="${key_comment:-$default_comment}"

    case "$key_type" in
        rsa)
            key_path="$ssh_dir/id_rsa"
            run_step "Generating RSA 4096-bit SSH key" \
                ssh-keygen -t rsa -b 4096 -C "$key_comment" -f "$key_path" -N "" || {
                log_error "Failed to generate SSH key"
                return 1
            }
            ;;
        ed25519|*)
            key_path="$ssh_dir/id_ed25519"
            run_step "Generating ed25519 SSH key" \
                ssh-keygen -t ed25519 -C "$key_comment" -f "$key_path" -N "" || {
                log_error "Failed to generate SSH key"
                return 1
            }
            ;;
    esac

    # Set permissions
    run_step "Setting key permissions" \
        chmod 600 "$key_path" && chmod 644 "${key_path}.pub"

    # Start ssh-agent and add key
    if ask_yes_no "Add key to ssh-agent?" "y"; then
        run_step "Starting ssh-agent" eval "$(ssh-agent -s)"
        run_step "Adding key to ssh-agent" \
            ssh-add "$key_path" || log_warn "Could not add key to ssh-agent"
    fi

    # Display public key
    echo ""
    log_info "Your public key:"
    echo "  ┌──────────────────────────────────────────────────────"
    while IFS= read -r line; do
        printf "  │ %s\n" "$line"
    done < "${key_path}.pub"
    echo "  └──────────────────────────────────────────────────────"
    log_info "Add this key to GitHub/GitLab: Settings → SSH Keys"

    return 0
}