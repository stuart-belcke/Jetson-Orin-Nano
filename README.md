# Jetson Orin Nano

Setup notes and scripts for my Jetson Orin Nano 8 GB Developer Kit: JetPack 7.2.1 on a 256 GB NVMe SSD, in a Waveshare aluminum case, running headless with Ollama for local AI.

## Connect

```
ssh stuart@stuart-orin.local
```

Or `ssh orin` once the shortcut in [`ssh/config.example`](ssh/config.example) is added to your SSH config.

## What's here

| Path | What it is |
| --- | --- |
| [`docs/setup-notes.md`](docs/setup-notes.md) | Full notes: hardware, button wiring, install history, access, power modes, AI setup, troubleshooting |
| [`scripts/post-install.sh`](scripts/post-install.sh) | After a fresh install: updates, SSH, hostname, MAXN SUPER, optional headless |
| [`scripts/install-ollama.sh`](scripts/install-ollama.sh) | Installs Ollama, checks the GPU, pulls a model, optional Open WebUI |
| [`ssh/config.example`](ssh/config.example) | The `ssh orin` shortcut for the PC |
| [`CLAUDE.md`](CLAUDE.md) | Context for Claude Code when working in this repo |

## Rebuild from scratch

1. Install JetPack to the SSD with the Jetson ISO. See **Reinstalling from scratch** in the [setup notes](docs/setup-notes.md).
2. On the Jetson, get the scripts and run them:

   ```
   git clone https://github.com/stuart-belcke/jetson-orin-nano.git
   cd jetson-orin-nano
   bash scripts/post-install.sh --headless
   sudo reboot
   ```

3. Reconnect over SSH, then:

   ```
   bash ~/jetson-orin-nano/scripts/install-ollama.sh
   ```

## Quick commands

| Task | Command |
| --- | --- |
| Check power mode | `sudo nvpmodel -q` |
| Chat with the model | `ollama run qwen3:8b` |
| Check GPU use | `ollama ps` |
| Desktop on every boot | `sudo systemctl set-default graphical.target && sudo reboot` |
| Back to headless | `sudo systemctl set-default multi-user.target && sudo reboot` |
| Shut down safely | `sudo shutdown now` |

No passwords, keys or Wi-Fi details belong in this repo.
