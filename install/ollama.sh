#!/usr/bin/env bash
# ==============================================================================
# install/ollama.sh — Ollama (local LLM runner) via pre-built archive
# ==============================================================================
# Defines: run()
# ==============================================================================
# Instead of the usual `curl ... | sh`, this downloads a pre-built tarball
# containing usr/local/bin/ollama and extracts it from /.  Much faster and
# avoids piping an unknown script into a shell.
#
# Set OLLAMA_ARCHIVE_URL to override the download location.
# ==============================================================================

# Default download URL — update this to wherever you host the archive.
OLLAMA_ARCHIVE_URL="${OLLAMA_ARCHIVE_URL:-https://github.com/ollama/ollama/releases/latest/download/ollama-linux-amd64.tgz}"

run() {
    local failed=0

    log_step "Ollama"

    # --------------------------------------------------------------------------
    # Already installed?
    # --------------------------------------------------------------------------
    if has_command ollama; then
        log_info "Ollama already installed ($(ollama --version 2>/dev/null))"
        if ! ask_yes_no "Reinstall Ollama?" "n"; then
            return 0
        fi
    else
        if ! ask_yes_no "Install Ollama (local LLM runner)?"; then
            log_info "Skipping: Ollama"
            return 0
        fi
    fi

    # --------------------------------------------------------------------------
    # Download the archive
    # --------------------------------------------------------------------------
    local tmpdir
    tmpdir="$(mktemp -d)"
    local archive="$tmpdir/ollama.tar.gz"

    run_step "Downloading Ollama archive" \
        curl -fsSL --progress-bar "$OLLAMA_ARCHIVE_URL" -o "$archive" || {
        log_error "Failed to download Ollama archive from $OLLAMA_ARCHIVE_URL"
        rm -rf "$tmpdir"
        return 1
    }

    # --------------------------------------------------------------------------
    # Extract — the archive contains usr/local/bin/ollama, so extract from /
    # --------------------------------------------------------------------------
    run_step "Extracting Ollama to /usr/local/bin" \
        sudo tar -xzf "$archive" -C / || {
        log_error "Failed to extract Ollama archive"
        rm -rf "$tmpdir"
        return 1
    }

    # Ensure the binary is executable
    sudo chmod +x /usr/local/bin/ollama 2>/dev/null || true

    rm -rf "$tmpdir"

    # --------------------------------------------------------------------------
    # Verify
    # --------------------------------------------------------------------------
    if has_command ollama; then
        log_success "Ollama installed ($(ollama --version 2>/dev/null))"
    else
        log_error "Ollama binary not found after extraction"
        ((failed++))
    fi

    # --------------------------------------------------------------------------
    # Optional: systemd service (so Ollama runs as a daemon on boot)
    # --------------------------------------------------------------------------
    if ask_yes_no "Set up Ollama systemd service (auto-start on boot)?" "n"; then
        _setup_systemd_service || ((failed++))
    fi

    [[ $failed -eq 0 ]]
}

# ------------------------------------------------------------------------------
# Helper: create the ollama systemd service (same as the official installer)
# ------------------------------------------------------------------------------
_setup_systemd_service() {
    # Create the ollama system user if it doesn't exist
    if ! id ollama &>/dev/null; then
        run_step "Creating ollama system user" \
            sudo useradd -r -s /bin/false -U -m -d /usr/share/ollama ollama || {
            log_warn "Could not create ollama user — service may not work"
            return 1
        }
    fi

    # Write the systemd unit
    local unit_file="/etc/systemd/system/ollama.service"
    if [[ -f "$unit_file" ]]; then
        log_info "Systemd service already exists at $unit_file"
        return 0
    fi

    run_step "Creating systemd service" \
        sudo tee "$unit_file" > /dev/null <<'UNIT'
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="OLLAMA_HOST=127.0.0.1"

[Install]
WantedBy=default.target
UNIT

    run_step "Enabling ollama service" sudo systemctl daemon-reload || true
    run_step "Starting ollama service" sudo systemctl enable --now ollama || {
        log_warn "Could not start ollama service"
        return 1
    }

    log_success "Ollama systemd service is running"
}