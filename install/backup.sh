#!/bin/bash

echo "📦 Backing up existing dotfiles..."

BACKUP_DIR=~/dotfiles-backup/$(date +%Y-%m-%d_%H-%M-%S)
mkdir -p $BACKUP_DIR

# List of files to back up
files_to_backup=(.bashrc .bash_aliases .profile)

for file in "${files_to_backup[@]}"; do
  if [ -f ~/$file ]; then
    echo "  -> Backing up ~/$file to $BACKUP_DIR"
    mv ~/$file $BACKUP_DIR/
  fi
done

echo "✅ Backup complete."
