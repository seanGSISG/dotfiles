# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/) and encrypted with [age](https://github.com/FiloSottile/age).

## Quick Start

```bash
# One-liner install (from fresh Ubuntu/Debian)
curl -fsSL https://raw.githubusercontent.com/seanGSISG/linux-dev-autoconfig/main/install.sh | bash
```

When prompted, paste your age decryption key from Bitwarden.

## What's Included

### Configs (Unencrypted)
- `~/.zshrc` - Zsh configuration with Oh My Zsh
- `~/.p10k.zsh` - Powerlevel10k theme
- `~/.dgxspark/zsh/aliases.zsh` - Shell aliases
- `~/.config/ghostty/config` - Ghostty terminal config
- `~/dev/claude-home/CLAUDE.md` - Claude Code knowledge base

### Encrypted Files
These files contain sensitive information (IPs, hostnames, SSH keys):
- `~/.ssh/config` - SSH host configurations
- `~/dev/claude-home/SSH.md` - Homelab SSH documentation

## Manual Setup

If you didn't use the one-liner:

```bash
# 1. Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# 2. Save your age key (from Bitwarden)
mkdir -p ~/.config/chezmoi
echo "AGE-SECRET-KEY-1..." > ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt

# 3. Initialize and apply
chezmoi init --apply seanGSISG/dotfiles
```

## Updating Configs

```bash
# Pull latest and apply
chezmoi update

# See what would change
chezmoi diff

# Edit a file
chezmoi edit ~/.zshrc
```

## Adding New Files

```bash
# Add unencrypted file
chezmoi add ~/.some-config

# Add encrypted file (sensitive)
chezmoi add --encrypt ~/.secret-file
```

## Security

See [SECURITY.md](docs/SECURITY.md) for details on:
- How encryption works
- Where keys are stored
- Recovery procedures

## Age Key

Your age key is stored in Bitwarden as a Secure Note called "Dotfiles Age Key".

**Format:** `AGE-SECRET-KEY-1...` (one line)

**Public key:** `age1fhew9x6ct2rppwhy4qhnx0jlg6ae4nx66uyq7flnltnlqzhlh9ms9yaymq`
