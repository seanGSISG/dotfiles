#!/bin/bash

echo "🔑 Checking for existing SSH keys..."

if [ -f ~/.ssh/id_rsa ]; then
  echo "SSH key already exists. Skipping generation."
else
  echo "Generating a new SSH key..."
  ssh-keygen -t rsa -b 4096 -C "$(git config --global user.email)" -f ~/.ssh/id_rsa -N ""
  echo "✅ New SSH key generated."
fi

echo "📋 Public key:"
cat ~/.ssh/id_rsa.pub

echo "🔗 Add this key to your GitHub account: https://github.com/settings/keys"
