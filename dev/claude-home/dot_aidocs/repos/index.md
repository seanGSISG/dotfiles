# Repository Index

| Repo | Path | Description |
|------|------|-------------|
| linux-dev-autoconfig | `/home/adminuser/dev/github/linux-dev-autoconfig` | Bootstrap installer - installs chezmoi and triggers dotfiles setup |
| dotfiles | `/home/adminuser/.local/share/chezmoi` | Personal dotfiles with age-encrypted secrets (managed by chezmoi) |
| spark-vllm-docker | `/home/adminuser/dev/github/spark-vllm-docker` | vLLM Docker optimization for DGX Spark multi-node inference clusters |
| hayes-macro-monitor | `/home/adminuser/dev/github/hayes-macro-monitor` | Self-hosted dashboard for Arthur Hayes macro trading signals (Oil, Yields, MOVE, ZEC/BTC) |

## Dotfiles Architecture

```
curl install.sh → linux-dev-autoconfig (bootstrap)
                        ↓
               chezmoi init --apply
                        ↓
                  dotfiles repo
                   ├── configs (unencrypted)
                   └── secrets (age-encrypted)
```

**Age key location:** Bitwarden → "Dotfiles Age Key"
