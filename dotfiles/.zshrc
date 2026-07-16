# ==============================================================================
# .zshrc — Zsh configuration for the bootstrap toolkit
# ==============================================================================

# --- Oh My Zsh ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Plugins (managed by oh-my-zsh + custom)
plugins=(
    git
    z
    sudo
    history
    command-not-found
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Load Oh My Zsh
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
fi

# --- Aliases ---
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias df='df -h'
alias free='free -h'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gco='git checkout'

# Docker aliases
alias dk='docker'
alias dkps='docker ps'
alias dki='docker images'
alias dkx='docker exec -it'

# Kubernetes aliases
alias k='kubectl'
alias kx='kubectx'
alias kn='kubens'

# --- History ---
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY

# --- Path additions ---
# Add local bin to PATH
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
# Add Cargo bin (Rust)
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"
# Add Go bin
[[ -d "$HOME/go/bin" ]] && export PATH="$HOME/go/bin:$PATH"

# --- Editor ---
export EDITOR='nano'
export VISUAL='nano'

# --- fzf integration ---
if command -v fzf &>/dev/null; then
    eval "$(fzf --zsh 2>/dev/null || true)"
fi

# --- Starship prompt (if installed) ---
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi