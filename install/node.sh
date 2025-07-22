#!/bin/bash

echo "📦 Installing NVM + Node.js..."

# NVM
if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"

nvm install --lts
nvm alias default node

# Global npm packages (no sudo)
echo "🌐 Installing global npm tools..."
npm install -g \
  npm-check-updates \
  typescript \
  ts-node \
  prettier \
  eslint \
  serve \
  http-server \
  nodemon \
  zx \
  xml-js \
  xml-formatter \
  @openapitools/openapi-generator-cli \
  @devcontainers/cli \
  yo \
  @anthropic-ai/claude-code \
  @google/gemini-cli
