#!/bin/bash

echo "🧰 Running full dotfiles setup..."

# Update system
sudo apt update && sudo apt upgrade -y

# Run backup script
./install/backup.sh

# Link dotfiles
echo "🔗 Linking dotfiles..."
ln -sf "$PWD/.bashrc" ~/.bashrc
ln -sf "$PWD/.bash_aliases" ~/.bash_aliases
ln -sf "$PWD/.profile" ~/.profile

# Run install modules
./install/cli.sh
./install/git.sh
./install/node.sh
./install/ssh.sh
./install/theme.sh

echo "✅ Done! Restart terminal or run: source ~/.bashrc"
