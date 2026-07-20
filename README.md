# Bootstrap Toolkit

An interactive, cross-platform developer environment bootstrap script.

Run it with a single command — each step asks before installing:

```bash
curl -fsSL https://raw.githubusercontent.com/your-org/bootstrap-toolkit/main/bootstrap.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/your-org/bootstrap-toolkit.git
cd bootstrap-toolkit
./bootstrap.sh
```

---

## What It Does

The bootstrap walks you through installing and configuring a complete
developer environment. **Every step asks** — press `y` to install, `n` to skip.

### Install Steps
| Step | Description | Default |
|---|---|---|
| System packages | curl, git, build tools, zsh, htop, tree, etc. | Yes |
| Docker | Docker Engine + docker group | Yes |
| Kubernetes | kubectl, helm, k9s, kubectx/kubens | No |
| VS Code | Visual Studio Code | Yes |
| Dev tools | jq, fzf, tmux, ripgrep, bat, neovim, pyenv | No |
| Node.js | Node.js LTS + npm, pnpm, global npm packages | No |
| Ollama | Local LLM runner (archive-based install) | No |
| Nerd Fonts | JetBrainsMono, FiraCode, Hack, Meslo, SourceCodePro | No |

### Config Steps
| Step | Description | Default |
|---|---|---|
| Git | user.name, user.email, sensible defaults, .gitconfig | Yes |
| SSH | SSH key generation (ed25519/rsa), ssh-agent | No |
| Shell | zsh as default, Oh My Zsh, plugins, .zshrc | Yes |
| VS Code | settings.json + recommended extensions | No |

---

## How It Works

```
bootstrap.sh (entry point)
  ├── lib/common.sh        (logging, prompts, OS detection, error guards)
  ├── install/*.sh         (each defines run() — called by bootstrap.sh)
  ├── config/*.sh          (each defines run() — called by bootstrap.sh)
  └── dotfiles/            (static files copied to $HOME)
```

1. `bootstrap.sh` detects your OS and package manager.
2. It iterates through a list of steps.
3. For each step, it asks yes/no.
4. If yes, it sources the script and calls `run()`.
5. Errors are caught and logged — the bootstrap continues to the next step.
6. A summary is printed at the end.

---

## Non-Interactive Mode (CI/Automation)

Set `NONINTERACTIVE=1` to run with defaults (no prompts):

```bash
NONINTERACTIVE=1 bash bootstrap.sh
```

---

## Supported Platforms

| Platform | Package Manager |
|---|---|
| Ubuntu / Debian / Pop!_OS / Mint | apt |
| Fedora / RHEL / CentOS / Rocky / Alma | dnf |
| Arch / Manjaro | pacman |
| macOS | Homebrew (brew) |

---

## Project Structure

```
bootstrap-toolkit/
├── bootstrap.sh              # Entry point
├── lib/
│   └── common.sh             # Shared helpers
├── install/                  # Tool installers
│   ├── apt.sh
│   ├── docker.sh
│   ├── kubernetes.sh
│   ├── vscode.sh
│   ├── devtools.sh
│   ├── nodejs.sh
│   ├── ollama.sh
│   └── fonts.sh
├── config/                   # Configuration scripts
│   ├── git.sh
│   ├── ssh.sh
│   ├── shell.sh
│   └── vscode-settings.sh
├── dotfiles/                 # Static dotfiles
│   ├── .zshrc
│   ├── .gitconfig
│   └── vscode-settings.json
├── tests/                    # CI test helpers
│   ├── test_shellcheck.sh
│   ├── ci_setup.sh
│   └── ci_run_script.sh
├── .github/workflows/        # CI pipelines
│   ├── lint.yml
│   ├── test-install.yml
│   ├── test-config.yml
│   └── test-bootstrap.yml
├── AGENTS.md                 # AI agent maintenance guide
└── README.md                 # This file
```

---

## CI / Testing

Every script is tested in GitHub Actions across multiple Linux distributions
and macOS. The CI ensures that end users won't encounter broken scripts.

| Workflow | What it tests |
|---|---|
| **Lint** | Shellcheck + syntax check + structure verification on every push/PR |
| **Test Install Scripts** | Each `install/*.sh` run on Ubuntu, Debian, Fedora containers |
| **Test Config Scripts** | Each `config/*.sh` tested with mocked dependencies |
| **Test Full Bootstrap** | End-to-end `NONINTERACTIVE=1 bash bootstrap.sh` on 6 distros + macOS, weekly |

### Running Tests Locally

```bash
# Lint all scripts
shellcheck bootstrap.sh lib/*.sh install/*.sh config/*.sh tests/*.sh

# Test a single script in non-interactive mode
bash tests/ci_setup.sh
bash tests/ci_run_script.sh install/apt.sh

# Full dry-run
NONINTERACTIVE=1 bash bootstrap.sh
```

---

## Adding a New Step

1. Create `install/mytool.sh` or `config/myconfig.sh` with a `run()` function.
2. Add it to the `STEPS` array in `bootstrap.sh`.
3. Use helpers from `lib/common.sh` (`ask_yes_no`, `run_step`, `has_command`, etc.).
4. Run `shellcheck` on your script.
5. Test with `bash bootstrap.sh`.
6. Add a test job to the corresponding CI workflow (`.github/workflows/`).

See [`AGENTS.md`](./AGENTS.md) for detailed instructions for AI agents.

---

## License

MIT