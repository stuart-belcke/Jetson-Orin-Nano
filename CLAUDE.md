# CLAUDE.md

Context for Claude Code when working in this repo.

## The device

- NVIDIA Jetson Orin Nano 8 GB Developer Kit (Super), Waveshare JETSON-ORIN-CASE-A case.
- JetPack 7.2.1 / Jetson Linux r39.2.1 (Ubuntu 24.04-based), booting from a 256 GB NVMe SSD.
- Hostname `stuart-orin`, user `stuart`. Reachable from the Windows PC as `ssh stuart@stuart-orin.local` (or `ssh orin`).
- Runs headless (`multi-user.target`) to save memory. Power mode MAXN SUPER.
- 7.3 GB unified memory shared by CPU and GPU; roughly 5–6 GB is usable for models.
- Ollama is installed natively as a systemd service, API at `127.0.0.1:11434`, using the GPU via its CUDA 13 library. The installer's "Unsupported JetPack version" warning is expected.

## Working on the Jetson

- Run commands on the device over SSH: `ssh orin "<command>"`. Ask before anything that reboots, changes power or boot settings, deletes files, or flashes firmware.
- Never interrupt a firmware update or unplug during one.
- Prefer models that fit in about 5 GB (8B parameters at 4-bit or smaller). Check `ollama ps` shows 100% GPU.
- Many Jetson guides target JetPack 5/6; check that instructions apply to JetPack 7 before following them.

## Repo conventions

- `docs/setup-notes.md` is the main record. Update it when the setup changes (new software, settings, fixes that worked).
- Scripts in `scripts/` run on the Jetson, are bash with `set -euo pipefail`, and must be safe to re-run.
- Never commit passwords, SSH private keys, tokens, Wi-Fi details, or IP addresses.
