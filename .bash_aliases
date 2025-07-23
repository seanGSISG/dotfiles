# === Session & Reload ===
alias reload='source ~/.bashrc'
alias cls='clear && printf "\e[3J"'
alias resetbash='exec bash'

# === System / Package Management ===
alias updateall='sudo apt update && sudo apt upgrade -y'
alias fixbroken='sudo apt --fix-broken install'
alias cleanup='sudo apt autoremove -y && sudo apt autoclean'

# === Node.js / Dev Utilities ===
alias tsrun='ts-node'
alias ncu='npm-check-updates'
alias serveit='http-server -o'
alias nodemon='nodemon'
alias tscbuild='tsc --build'
alias fmt='prettier --write .'
alias lint='eslint .'
alias xmlfmt='xml-formatter'
alias xml2json='npx xml-js xml2json'
alias json2xml='npx xml-js json2xml'
alias oagen='openapi-generator-cli generate'
alias devc='devcontainer'
alias serve='serve -l 3000'
alias npmupdate='npm install -g npm@latest && ncu -g -u && npm install -g'
alias nvmlist='nvm ls'
alias nvmuse='nvm use'
alias nvmdefault='nvm alias default'

# === Navigation Shortcuts ===
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias proj='cd ~/projects && ls'
alias cdd='cd $(fd -t d | fzf)'  # jump to fuzzy-found directory

# === File / Directory Utilities ===
alias mkdirp='mkdir -p'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias untar='tar -xvf'
alias zipdir='zip -r'

# === Fuzzy Finder Shortcuts ===
alias f='fzf'
alias fh='history | fzf'
alias ff='find . -type f | fzf'
alias fd='find . -type d | fzf'
alias fr='fzf --preview "bat --style=numbers --color=always {}" --height=40%'
alias vf='nvim $(fzf)'
alias ffind='find . -name "*" | fzf'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'

# === Git Aliases ===
alias gs='git status -sb'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gb='git branch'
alias gco='git checkout'
alias gd='git diff'
alias gundo='git reset --soft HEAD~1'
alias glog='git log --oneline --graph --decorate --all'
alias gcm='git commit -m'
alias gpull='git pull'
alias gamend='git commit --amend'
alias gstash='git stash'
alias gpop='git stash pop'

# === System / Info ===
alias ports='sudo lsof -i -P -n | grep LISTEN'
alias ipinfo='curl ifconfig.me && echo'
alias myip='hostname -I'
alias histg='history | grep'
alias timez='timedatectl list-timezones | fzf'

# === Tree & Docs ===
alias tree='exa --tree --icons --git-ignore'
alias treemd='(echo "\`\`\`text"; tree -L 2; echo "\`\`\`") > tree.md && echo "Tree written to tree.md"'

alias dothelp='_show_aliases'

_show_aliases() {
  echo "🧩 Custom Alias Reference"
  echo "========================="
  echo ""
  echo "🔁 Reload & Session"
  echo "  reload        → source ~/.bashrc"
  echo "  resetbash     → restart current shell session"
  echo "  cls           → clear full screen"
  echo ""
  echo "📦 System / Package Management"
  echo "  updateall     → apt update & upgrade"
  echo "  fixbroken     → apt fix broken"
  echo "  cleanup       → apt autoremove & clean"
  echo ""
  echo "📁 Navigation"
  echo "  .., ..., .... → cd up levels"
  echo "  proj          → cd to ~/projects"
  echo "  cdd           → fuzzy cd to directory"
  echo ""
  echo "📂 File / Directory Utilities"
  echo "  mkdirp        → mkdir -p"
  echo "  ll, la, l     → various ls shortcuts"
  echo "  untar         → extract tar"
  echo "  zipdir        → zip directory"
  echo ""
  echo "🔍 Fuzzy Finder Shortcuts"
  echo "  f             → fzf"
  echo "  fh            → search command history"
  echo "  ff, fd        → find files or dirs"
  echo "  vf            → open file in nvim from fzf"
  echo "  ffind         → find files with fzf"
  echo "  grep, egrep   → colored grep"
  echo ""
  echo "🛠️  Dev Tools"
  echo "  tsrun         → run TypeScript directly"
  echo "  serveit       → launch http-server"
  echo "  ncu           → check npm updates"
  echo "  fmt / lint    → prettier / eslint"
  echo "  xmlfmt        → pretty print XML"
  echo "  xml2json      → convert XML to JSON"
  echo "  json2xml      → convert JSON to XML"
  echo "  oagen         → OpenAPI codegen"
  echo "  serve         → static server (port 3000)"
  echo ""
  echo "🐙 Git Aliases"
  echo "  gs            → git status"
  echo "  gc, gcm       → git commit -m"
  echo "  gp, gl        → git push/pull"
  echo "  gpull         → git pull"
  echo "  gco, gb       → checkout/branch"
  echo "  glog          → pretty git log"
  echo "  gamend        → git commit --amend"
  echo "  gstash, gpop  → git stash/pop"
  echo ""
  echo "🔧 System Info"
  echo "  ipinfo        → show public IP"
  echo "  myip          → show LAN IP"
  echo "  ports         → list open ports"
  echo "  histg         → grep history"
  echo ""
  echo "📦 NVM + Node"
  echo "  nvmlist       → list node versions"
  echo "  nvmuse        → switch version"
  echo "  nvmdefault    → set default version"
  echo ""
  echo "🗂️  Misc"
  echo "  tree          → exa tree view"
  echo "  treemd        → export tree to Markdown"
}
