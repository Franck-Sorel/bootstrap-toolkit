#!/usr/bin/env bash
# ==============================================================================
# install/fonts.sh — Nerd Fonts for terminal use
# ==============================================================================
# Defines: run()
# ==============================================================================

run() {
    local os
    os="$(detect_os)"

    # Available Nerd Fonts to choose from
    local fonts=(
        "JetBrainsMono"
        "FiraCode"
        "Hack"
        "Meslo"
        "SourceCodePro"
    )

    local font_dir
    case "$os" in
        macos)
            font_dir="$HOME/Library/Fonts"
            ;;
        *)
            font_dir="$HOME/.local/share/fonts"
            ;;
    esac

    mkdir -p "$font_dir"

    local installed_any=0

    for font in "${fonts[@]}"; do
        if ask_yes_no "Install ${font} Nerd Font?" "n"; then
            local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
            local tmpfile="/tmp/${font}.zip"

            run_step "Downloading ${font} Nerd Font" \
                curl -fsSL "$url" -o "$tmpfile" || {
                log_error "Failed to download ${font}"
                continue
            }

            local extract_dir="/tmp/${font}-fonts"
            mkdir -p "$extract_dir"
            run_step "Extracting ${font}" \
                unzip -o "$tmpfile" -d "$extract_dir" || {
                log_error "Failed to extract ${font}"
                continue
            }

            run_step "Installing ${font} to $font_dir" \
                cp "$extract_dir"/*.ttf "$font_dir/" 2>/dev/null || {
                log_error "Failed to copy ${font} fonts"
                continue
            }

            rm -rf "$extract_dir" "$tmpfile"
            ((installed_any++))
        fi
    done

    if [[ $installed_any -gt 0 ]]; then
        if [[ "$os" != "macos" ]]; then
            run_step "Refreshing font cache" fc-cache -fv "$font_dir" || \
                log_warn "Could not refresh font cache. Run 'fc-cache -fv' manually."
        fi
        log_success "Fonts installed to: $font_dir"
    fi

    return 0
}