# === Session & Reload ===
alias reload='source ~/.bashrc'
alias cls='clear && printf "\e[3J"'
alias resetbash='exec bash'

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

# === Fuzzy Finder Shortcuts ===
alias f='fzf'
alias fh='history | fzf'
alias ff='find . -type f | fzf'
alias fd='find . -type d | fzf'
alias fr='fzf --preview "bat --style=numbers --color=always {}" --height=40%'
alias vf='nvim $(fzf)'

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

# === System / Info ===
alias ports='sudo lsof -i -P -n | grep LISTEN'
alias ipinfo='curl ifconfig.me && echo'
alias myip='hostname -I'
alias histg='history | grep'
alias timez='timedatectl list-timezones | fzf'

# === Tree & Docs ===
alias tree='exa --tree --icons --git-ignore'
alias treemd='(echo "\`\`\`text"; tree -L 2; echo "\`\`\`") > tree.md && echo "Tree written to tree.md"'
