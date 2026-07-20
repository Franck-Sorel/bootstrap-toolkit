# AGENTS.md — Guide for AI Agents Maintaining This Repository

> **Purpose:** This document provides structured instructions for any AI agent
> (Claude, GPT, Copilot, etc.) that is tasked with maintaining, extending, or
> debugging this bootstrap toolkit repository. Follow these rules precisely.

---

## 1. Repository Architecture

```
bootstrap-toolkit/
├── bootstrap.sh              # Entry point — orchestrates all steps
├── lib/
│   └── common.sh             # Shared library: logging, prompts, OS detection
├── install/                  # Tool installation scripts (each defines run())
│   ├── apt.sh                # System packages (apt/brew/dnf/pacman)
│   ├── docker.sh             # Docker Engine + Compose
│   ├── kubernetes.sh         # kubectl, helm, k9s, kubectx
│   ├── vscode.sh             # Visual Studio Code
│   ├── devtools.sh           # jq, fzf, tmux, ripgrep, bat, neovim, pyenv
│   ├── nodejs.sh             # Node.js + npm, pnpm, global npm packages
│   ├── ollama.sh             # Ollama local LLM runner (archive-based)
│   └── fonts.sh              # Nerd Fonts
├── config/                   # Configuration scripts (each defines run())
│   ├── git.sh                # Git global config
│   ├── shell.sh              # Zsh + Oh My Zsh + plugins
│   └── vscode-settings.sh    # VS Code settings + extensions
├── dotfiles/                 # Static dotfiles copied to $HOME
│   ├── .zshrc
│   ├── .gitconfig
│   └── vscode-settings.json
├── tests/                    # Test scripts and CI helpers
│   ├── test_shellcheck.sh    # Lint all scripts
│   ├── ci_setup.sh           # Prepare container env (sudo, deps)
│   └── ci_run_script.sh      # Run a single script in CI mode
├── .github/workflows/        # GitHub Actions CI
│   ├── lint.yml              # Shellcheck + structure verification
│   ├── test-install.yml      # Matrix test each install script
│   ├── test-config.yml       # Test each config script
│   └── test-bootstrap.yml    # Full end-to-end bootstrap on multiple distros
├── AGENTS.md                 # This file
└── README.md                 # User-facing documentation
```

---

## 2. Core Design Principles

### 2.1 Every Step Is Interactive
- Every installation/configuration step **must** ask the user before proceeding.
- Use `ask_yes_no "Prompt?" "default"` from `lib/common.sh`.
- The `NONINTERACTIVE=1` env var bypasses prompts for CI/automation.

### 2.2 Graceful Error Handling
- **Never** use `set -e` globally. Each step manages its own errors.
- Use `run_step "description" command...` to wrap commands — it logs and returns the exit code.
- A failed step must **not** abort the entire bootstrap. Log the error, record it, and continue.
- Use `||` with fallbacks: `command || log_warn "fallback message"`.

### 2.3 Each Script Defines `run()`
- Every file in `install/` and `config/` **must** define a function called `run`.
- `bootstrap.sh` sources the script and calls `run()`.
- After calling, `bootstrap.sh` unsets `run` so the next script can define its own.
- `run()` must return `0` on success and non-zero on failure.

### 2.4 Cross-Platform
- Support: Ubuntu/Debian, Fedora/RHEL, Arch, macOS.
- Use `detect_os()` and `detect_package_manager()` from `lib/common.sh`.
- Never hardcode `apt-get` — always check the package manager.

---

## 3. How to Add a New Install Step

1. **Create the script** in `install/` or `config/`:
   ```bash
   #!/usr/bin/env bash
   run() {
       # ... your logic ...
       return 0
   }
   ```

2. **Register it** in `bootstrap.sh` in the `STEPS` array:
   ```bash
   STEPS=(
       ...
       "install/mytool.sh|My Tool Name|n"   # path|display_name|default(y/n)
   )
   ```

3. **Use shared helpers** from `lib/common.sh`:
   - `ask_yes_no "prompt" "default"` — interactive yes/no
   - `run_step "desc" command...` — wrapped command with logging
   - `has_command "name"` — check if a command exists
   - `log_info/log_success/log_warn/log_error` — logging
   - `detect_os()` / `detect_package_manager()` — platform detection

4. **Handle already-installed state**:
   ```bash
   if has_command mytool; then
       log_info "mytool already installed"
       if ! ask_yes_no "Reinstall mytool?" "n"; then
           return 0
       fi
   fi
   ```

5. **Test**:
   ```bash
   shellcheck install/mytool.sh
   bash bootstrap.sh  # dry-run through the prompts
   ```

---

## 4. Coding Standards

### 4.1 Shell Style
- Use `#!/usr/bin/env bash` as the shebang.
- Use `[[ ]]` for tests, not `[ ]`.
- Use `$(...)` for command substitution, not backticks.
- Quote all variable expansions: `"$var"`, not `$var`.
- Use `local` for function-scoped variables.
- Use `printf` instead of `echo` for formatted output.

### 4.2 File Header
Every script must begin with:
```bash
#!/usr/bin/env bash
# ==============================================================================
# <path> — <short description>
# ==============================================================================
# Defines: run()
# ==============================================================================
```

### 4.3 Error Patterns
```bash
# GOOD: graceful, continues on failure
run_step "Installing foo" sudo apt-get install -y foo || log_warn "Could not install foo"

# BAD: aborts on failure
sudo apt-get install -y foo
```

### 4.4 Linting
- All scripts must pass `shellcheck` with no errors.
- Run: `shellcheck bootstrap.sh lib/*.sh install/*.sh config/*.sh`

---

## 5. Testing

### 5.1 Shellcheck
```bash
shellcheck bootstrap.sh lib/*.sh install/*.sh config/*.sh
```

### 5.2 Dry Run (Non-interactive)
```bash
NONINTERACTIVE=1 bash bootstrap.sh
```

### 5.3 Test a Single Script
```bash
source lib/common.sh
source install/docker.sh
run
```

### 5.4 CI Test Helpers
```bash
# Prepare a container for testing (installs sudo, curl, git, etc.)
bash tests/ci_setup.sh

# Run a single script in non-interactive mode
bash tests/ci_run_script.sh install/apt.sh
```

### 5.5 GitHub Actions CI Workflows

The repo includes four GitHub Actions workflows under `.github/workflows/`:

| Workflow | File | Purpose |
|---|---|---|
| Lint | `lint.yml` | Shellcheck + syntax check + structure verification |
| Test Install Scripts | `test-install.yml` | Matrix test each `install/*.sh` on multiple distros |
| Test Config Scripts | `test-config.yml` | Test each `config/*.sh` with mocked dependencies |
| Test Full Bootstrap | `test-bootstrap.yml` | End-to-end `NONINTERACTIVE=1 bash bootstrap.sh` on 6 distros + macOS |

**CI design rules:**
- Use `NONINTERACTIVE=1` for all CI runs.
- Use `tests/ci_setup.sh` to prepare containers (installs sudo, curl, git).
- Use `tests/ci_run_script.sh <script>` to test individual scripts.
- Scripts that can't fully run in CI (docker.sh, vscode.sh) are tested for **graceful failure** — the script must not crash, it must log and continue.
- The full bootstrap test uses `|| true` because some steps are expected to fail in CI (no Docker-in-Docker, no GUI). The test verifies the bootstrap **completes** and core tools are installed.
- Matrix containers: `ubuntu:24.04`, `ubuntu:22.04`, `debian:12`, `debian:11`, `fedora:40`, `archlinux:latest`.
- macOS is tested on a native runner (`macos-latest`).
- When adding a new install/config script, add a test job to the corresponding workflow.

---

## 6. Common Pitfalls to Avoid

| Pitfall | Solution |
|---|---|
| Using `set -e` | Don't. Handle errors per-step with `run_step` and `\|\|` |
| Hardcoding `apt-get` | Use `detect_package_manager()` |
| Not checking if already installed | Use `has_command` before installing |
| Not defining `run()` | Every install/config script MUST define `run()` |
| Forgetting to unset `run` | `bootstrap.sh` handles this, but be aware |
| Not quoting variables | Always quote: `"$var"` |
| Using `echo` for formatted output | Use `printf` |
| Not handling `/dev/tty` for `read` | Use `read -r ... </dev/tty` |

---

## 7. When Modifying This Repo

1. **Read** `lib/common.sh` first — understand the shared helpers.
2. **Read** `bootstrap.sh` — understand the step pipeline.
3. **Run** `shellcheck` on any modified files.
4. **Test** with `NONINTERACTIVE=1 bash bootstrap.sh`.
5. **Update** this `AGENTS.md` if you change the architecture or add new patterns.
6. **Update** `README.md` if user-facing behavior changes.
7. **Commit** with a clear message: `feat: add rust install step` or `fix: handle brew not found on macOS`.