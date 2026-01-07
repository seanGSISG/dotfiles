#!/usr/bin/env bash
# ============================================================
# Dotfiles - Tool Installation Script (run_once by chezmoi)
# ============================================================
# This script runs once after chezmoi applies configs.
# It installs CLI tools, AI agents, and shell plugins.
# ============================================================

set -euo pipefail

# Detect architecture
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)  DEB_ARCH="amd64"; TARBALL_ARCH="x86_64" ;;
    aarch64) DEB_ARCH="arm64"; TARBALL_ARCH="arm64" ;;
    arm64)   DEB_ARCH="arm64"; TARBALL_ARCH="arm64" ;;
    *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

has_cmd() { command -v "$1" &>/dev/null; }

as_root() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

# ============================================================
# Phase 1: Base Dependencies
# ============================================================

install_base_deps() {
    log_info "Installing base dependencies..."

    as_root apt-get update -y

    local packages=(
        curl git wget ca-certificates unzip tar xz-utils jq
        build-essential gnupg lsb-release zsh software-properties-common
        age  # For chezmoi encryption
    )

    as_root apt-get install -y "${packages[@]}"
    log_success "Base dependencies installed"
}

# ============================================================
# Phase 2: Shell Plugins (Oh My Zsh + Powerlevel10k)
# ============================================================

install_shell_plugins() {
    log_info "Installing shell plugins..."

    # Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Installing Oh My Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Powerlevel10k
    local p10k_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    if [[ ! -d "$p10k_dir" ]]; then
        log_info "Installing Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    fi

    # zsh-autosuggestions
    local autosuggestions_dir="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    if [[ ! -d "$autosuggestions_dir" ]]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$autosuggestions_dir"
    fi

    # zsh-syntax-highlighting
    local syntax_dir="$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    if [[ ! -d "$syntax_dir" ]]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$syntax_dir"
    fi

    # Change default shell to zsh
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        log_info "Changing default shell to zsh..."
        as_root chsh -s "$(which zsh)" "$(whoami)"
    fi

    log_success "Shell plugins installed"
}

# ============================================================
# Phase 3: CLI Tools
# ============================================================

install_cli_tools() {
    log_info "Installing CLI tools..."

    # APT packages
    local apt_packages=(ripgrep tmux fzf direnv git-lfs mosh ncdu tldr)
    as_root apt-get install -y "${apt_packages[@]}" || true

    # duf
    if ! has_cmd duf; then
        as_root apt-get install -y duf 2>/dev/null || {
            local duf_version="0.8.1"
            curl -fsSL "https://github.com/muesli/duf/releases/download/v${duf_version}/duf_${duf_version}_linux_${DEB_ARCH}.deb" -o /tmp/duf.deb
            as_root dpkg -i /tmp/duf.deb && rm /tmp/duf.deb
        } || true
    fi

    # Tailscale
    if ! has_cmd tailscale; then
        log_info "Installing Tailscale..."
        curl -fsSL https://tailscale.com/install.sh | bash || log_warn "Tailscale installation failed"
    fi

    # lsd
    if ! has_cmd lsd; then
        as_root apt-get install -y lsd 2>/dev/null || {
            local lsd_version="1.1.5"
            curl -fsSL "https://github.com/lsd-rs/lsd/releases/download/v${lsd_version}/lsd_${lsd_version}_${DEB_ARCH}.deb" -o /tmp/lsd.deb
            as_root dpkg -i /tmp/lsd.deb && rm /tmp/lsd.deb
        }
    fi

    # bat, fd, btop, neovim, lazygit, gh
    as_root apt-get install -y bat fd-find btop neovim gh 2>/dev/null || true

    # lazygit fallback
    if ! has_cmd lazygit; then
        local lazygit_version="0.44.1"
        curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${lazygit_version}/lazygit_${lazygit_version}_Linux_${TARBALL_ARCH}.tar.gz" | tar xz -C /tmp lazygit
        as_root mv /tmp/lazygit /usr/local/bin/
    fi

    log_success "CLI tools installed"
}

# ============================================================
# Phase 4: AI Agents
# ============================================================

install_ai_agents() {
    log_info "Installing AI agents..."

    # UV (Python package manager)
    if ! has_cmd uv; then
        curl -LsSf https://astral.sh/uv/install.sh | bash
    fi

    # Bun
    if ! has_cmd bun && [[ ! -x "$HOME/.bun/bin/bun" ]]; then
        curl -fsSL https://bun.sh/install | bash
    fi

    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"

    # Claude Code
    if [[ ! -x "$HOME/.local/bin/claude" ]]; then
        log_info "Installing Claude Code..."
        curl -fsSL https://claude.ai/install.sh | bash || log_warn "Claude Code installation failed"
    fi

    # Codex CLI
    if [[ -x "$HOME/.bun/bin/bun" ]]; then
        "$HOME/.bun/bin/bun" install -g --trust @openai/codex@latest || true
    fi

    log_success "AI agents installed"
}

# ============================================================
# Phase 5: Create directories
# ============================================================

setup_directories() {
    log_info "Creating directories..."
    mkdir -p "$HOME/projects"
    mkdir -p "$HOME/dev"
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.config/chezmoi"
    log_success "Directories created"
}

# ============================================================
# Main
# ============================================================

main() {
    echo ""
    echo "=============================================="
    echo "  Dotfiles - Tool Installation"
    echo "=============================================="
    echo ""

    setup_directories
    install_base_deps
    install_shell_plugins
    install_cli_tools
    install_ai_agents

    echo ""
    echo "=============================================="
    log_success "Tool installation complete!"
    echo "=============================================="
    echo ""
    echo "Next steps:"
    echo "  1. Run: exec zsh"
    echo "  2. Run: sudo tailscale up"
    echo "  3. Run: claude login"
    echo ""
}

main "$@"
