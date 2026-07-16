#!/usr/bin/env bash
# ==============================================================================
# install/kubernetes.sh — kubectl, helm, kubectx, k9s
# ==============================================================================
# Defines: run()
# ==============================================================================

run() {
    local os arch
    os="$(detect_os)"
    arch="$(uname -m)"

    # Normalize architecture
    case "$arch" in
        x86_64)  arch="amd64" ;;
        aarch64) arch="arm64" ;;
        armv7l)  arch="arm" ;;
    esac

    local failed=0

    # --- kubectl ---
    if has_command kubectl; then
        log_info "kubectl already installed ($(kubectl version --client 2>/dev/null | head -1))"
    else
        if ask_yes_no "Install kubectl?"; then
            local kubectl_url
            case "$os" in
                macos)
                    kubectl_url="https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/darwin/${arch}/kubectl"
                    ;;
                *)
                    kubectl_url="https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/${arch}/kubectl"
                    ;;
            esac
            run_step "Downloading kubectl" \
                curl -fsSL "$kubectl_url" -o /tmp/kubectl || { log_error "Failed to download kubectl"; ((failed++)); }
            if [[ -f /tmp/kubectl ]]; then
                run_step "Installing kubectl" \
                    sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl || { ((failed++)); }
                rm -f /tmp/kubectl
            fi
        fi
    fi

    # --- helm ---
    if has_command helm; then
        log_info "helm already installed ($(helm version 2>/dev/null | head -1))"
    else
        if ask_yes_no "Install Helm?"; then
            run_step "Installing Helm via official script" \
                curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash || {
                log_error "Failed to install Helm"
                ((failed++))
            }
        fi
    fi

    # --- k9s ---
    if has_command k9s; then
        log_info "k9s already installed"
    else
        if ask_yes_no "Install k9s (terminal Kubernetes UI)?"; then
            if has_command brew; then
                run_step "Installing k9s via Homebrew" brew install k9s || { ((failed++)); }
            else
                local k9s_version
                k9s_version="$(curl -sL https://api.github.com/repos/derailed/k9s/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+')"
                local k9s_url="https://github.com/derailed/k9s/releases/download/${k9s_version}/k9s_Linux_${arch}.tar.gz"
                run_step "Downloading k9s ${k9s_version}" \
                    curl -fsSL "$k9s_url" -o /tmp/k9s.tar.gz || { ((failed++)); }
                if [[ -f /tmp/k9s.tar.gz ]]; then
                    run_step "Extracting k9s" tar xzf /tmp/k9s.tar.gz -C /tmp k9s || { ((failed++)); }
                    run_step "Installing k9s" \
                        sudo install -m 0755 /tmp/k9s /usr/local/bin/k9s || { ((failed++)); }
                    rm -f /tmp/k9s /tmp/k9s.tar.gz
                fi
            fi
        fi
    fi

    # --- kubectx / kubens ---
    if ! has_command kubectx; then
        if ask_yes_no "Install kubectx/kubens?"; then
            if has_command brew; then
                run_step "Installing kubectx via Homebrew" brew install kubectx || { ((failed++)); }
            else
                run_step "Cloning kubectx" \
                    git clone https://github.com/ahmetb/kubectx /tmp/kubectx 2>/dev/null || { ((failed++)); }
                if [[ -d /tmp/kubectx ]]; then
                    if sudo ln -sf /tmp/kubectx/kubectx /usr/local/bin/kubectx && \
                       sudo ln -sf /tmp/kubectx/kubens /usr/local/bin/kubens; then
                        log_success "Installing kubectx — done"
                    else
                        log_error "Installing kubectx — failed"
                        ((failed++))
                    fi
                fi
            fi
        fi
    fi

    [[ $failed -eq 0 ]]
}