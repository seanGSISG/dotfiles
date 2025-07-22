## ⚡ Quick Setup

```bash
git clone https://github.com/seanGSISG/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x setup.sh install/*.sh
./setup.sh
```

## 📦 Includes

- `.bashrc`, `.bash_aliases`, `.profile` with modern dev shortcuts
- Node.js via NVM + global tools (Prettier, TypeScript)
- Git & GitHub CLI
- Fuzzy search + modern CLI tools (`fzf`, `exa`, `fd`, `bat`)
- Modular setup scripts: `install/cli.sh`, `install/node.sh`, etc.
- Claude Code
- Gemini CLI

## 📁 File Structure

```bash
dotfiles/
├── .bashrc
├── .bash_aliases
├── .profile
├── setup.sh
├── .gitignore
├── README.md
└── install/
    ├── cli.sh
    ├── docker.sh
    ├── git.sh
    └── node.sh
```



