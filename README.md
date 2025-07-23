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
- **Automated dotfile backups** to `~/dotfiles-backup`
- **SSH key generation** and setup guidance
- **Terminal theming** with `base16-shell`
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
    ├── node.sh
    ├── backup.sh
    ├── ssh.sh
    └── theme.sh
```

## 🧩 Custom Alias Reference

Use `dothelp` to list all Alias References

### 🔁 Reload & Session
* `reload` → `source ~/.bashrc`
* `resetbash` → `restart current shell session`
* `cls` → `clear full screen`

---

### 📦 System / Package Management
* `updateall` → `apt update & upgrade`
* `fixbroken` → `apt fix broken`
* `cleanup` → `apt autoremove & clean`

---

### 📁 Navigation
* `..`, `...`, `....` → `cd up levels`
* `proj` → `cd to ~/projects`
* `cdd` → `fuzzy cd to directory`

---

### 📂 File / Directory Utilities
* `mkdirp` → `mkdir -p`
* `ll`, `la`, `l` → `various ls shortcuts`
* `untar` → `extract tar`
* `zipdir` → `zip directory`

---

### 🔍 Fuzzy Finder Shortcuts
* `f` → `fzf`
* `fh` → `search command history`
* `ff`, `fd` → `find files or dirs`
* `vf` → `open file in nvim from fzf`
* `ffind` → `find files with fzf`
* `grep`, `egrep` → `colored grep`

---

### 🛠️ Dev Tools
* `tsrun` → `run TypeScript directly`
* `serveit` → `launch http-server`
* `ncu` → `check npm updates`
* `fmt / lint` → `prettier / eslint`
* `xmlfmt` → `pretty print XML`
* `xml2json` → `convert XML to JSON`
* `json2xml` → `convert JSON to XML`
* `oagen` → `OpenAPI codegen`
* `serve` → `static server (port 3000)`

---

### 🐙 Git Aliases
* `gs` → `git status`
* `gc`, `gcm` → `git commit -m`
* `gp`, `gl` → `git push/pull`
* `gpull` → `git pull`
* `gco`, `gb` → `checkout/branch`
* `glog` → `pretty git log`
* `gamend` → `git commit --amend`
* `gstash`, `gpop` → `git stash/pop`

---

### 🔧 System Info
* `ipinfo` → `show public IP`
* `myip` → `show LAN IP`
* `ports` → `list open ports`
* `histg` → `grep history`

---

### 📦 NVM + Node
* `nvmlist` → `list node versions`
* `nvmuse` → `switch version`
* `nvmdefault` → `set default version`

---

### 🗂️ Misc
* `tree` → `exa tree view`
* `treemd` → `export tree to Markdown`

