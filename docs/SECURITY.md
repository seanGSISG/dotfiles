# Security

## How Encryption Works

This dotfiles repo uses **age encryption** to protect sensitive files.

```
┌─────────────────────────────────────────────────────────┐
│                    ENCRYPTION FLOW                       │
├─────────────────────────────────────────────────────────┤
│                                                          │
│   plaintext file ──► age encrypt ──► .age file          │
│        │                  │              │               │
│   (your secrets)    (public key)    (safe to commit)    │
│                                                          │
│   .age file ──► age decrypt ──► plaintext file          │
│        │              │              │                   │
│   (from repo)    (private key)  (on your machine)       │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### What's Encrypted

| File | Contains |
|------|----------|
| `~/.ssh/config` | SSH hosts, IP addresses |
| `~/dev/claude-home/SSH.md` | Homelab documentation, IPs |

### What's NOT Encrypted

General configs that contain no secrets:
- Shell configs (`.zshrc`, `.p10k.zsh`)
- Aliases
- Tool configs (tmux, ghostty)

## Key Storage

### Private Key (Decryption)
- **Location on machine:** `~/.config/chezmoi/key.txt`
- **Backup location:** Bitwarden (Secure Note: "Dotfiles Age Key")
- **Format:** `AGE-SECRET-KEY-1...` (single line)

### Public Key (Encryption)
- **Stored in:** `~/.config/chezmoi/chezmoi.toml`
- **Value:** `age1fhew9x6ct2rppwhy4qhnx0jlg6ae4nx66uyq7flnltnlqzhlh9ms9yaymq`
- **Safe to share:** Yes (used for encryption only)

## Recovery Procedures

### Forgot where the key is?
1. Open Bitwarden
2. Search for "Dotfiles Age Key"
3. Copy the secret key

### Setting up a new machine?
1. Run the install script
2. When prompted for the age key, paste from Bitwarden
3. Chezmoi will decrypt and apply all configs

### Laptop stolen?
1. Your secrets are encrypted - attacker cannot read them without the key
2. Rotate the age key (generate new keypair)
3. Re-encrypt all sensitive files
4. Update Bitwarden with new key

### Accidentally committed plaintext secrets?
1. **Immediately** remove from git history:
   ```bash
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch PATH/TO/FILE" HEAD
   git push --force
   ```
2. Rotate any exposed credentials
3. Re-add with `chezmoi add --encrypt`

## Best Practices

1. **Never commit `key.txt`** - It's in `.gitignore` by default
2. **Use `chezmoi add --encrypt`** for any file with IPs, hostnames, or credentials
3. **Keep Bitwarden backup updated** after key rotation
4. **Review `chezmoi diff`** before applying updates
