#!/bin/bash

echo "💡 Installing CLI utilities..."

sudo apt install -y \
  curl \
  unzip \
  wget \
  build-essential \
  python3 \
  python3-pip \
  python3-venv \
  zsh \
  fzf \
  bat \
  exa \
  fd-find \
  graphviz

# Add to install/cli.sh
echo "🐍 Installing Python tools..."
pip install --upgrade pip
pip install black isort ruff

# Link fd
if ! command -v fd &> /dev/null; then
  mkdir -p ~/.local/bin
  ln -s $(which fdfind) ~/.local/bin/fd
fi

# GitHub CLI
type gh &>/dev/null || {
  echo "🌐 Installing GitHub CLI..."
  type -p curl >/dev/null || sudo apt install curl -y
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update
  sudo apt install gh -y
}
