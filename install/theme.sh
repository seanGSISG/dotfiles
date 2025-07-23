#!/bin/bash

echo "🎨 Installing base16-shell..."

if [ ! -d ~/.config/base16-shell ]; then
  git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell
fi

echo "✅ base16-shell installed."
echo "💡 To set a theme, run: base16_ocean"
echo "   Add 'eval \"\$(base16-shell init -)\"' to your .bashrc to apply themes."
