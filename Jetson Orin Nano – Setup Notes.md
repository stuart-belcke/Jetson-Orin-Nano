# Jetson Orin Nano – Setup Notes

Oct 11, 2026 · @Belcke

## Quick reference

The Jetson runs headless (no desktop) and is reached over SSH from the Windows PC as `stuart@stuart-orin.local`.

| What | Value |
| --- | --- |
| Hostname | `stuart-orin` (on the network as `stuart-orin.local`) |
| Username | `stuart` (password not stored here) |
| Connect from PC (PowerShell) | `ssh stuart@stuart-orin.local` — or `ssh orin` if the SSH config shortcut is set up |
| Find its IP (on the Jetson) | `hostname -I` |
| Boots from | 256 GB NVMe SSD |
| Software | JetPack 7.2.1 (Jetson Linux r39.2.1) |
| Power mode | MAXN SUPER |
| Boot target | Headless (text only) |
| AI runtime | Ollama, API at `127.0.0.1:11434` |
| Web chat | Open WebUI at `http://stuart-orin.local:8080` |
| Swap | 8 GB `/swapfile`, swappiness 10 |

Most-used commands:

- `sudo nvpmodel -q` — show current power mode
- `ollama list` / `ollama run qwen3:8b` / `ollama ps` — list models, chat, check GPU use
- `lsblk` — confirm `/` is on `nvme0n1`
- `sudo apt update && sudo apt upgrade -y` — install updates
- `sudo shutdown now` — power off cleanly before unplugging

## Hardware

Jetson Orin Nano 8 GB Developer Kit in a Waveshare JETSON-ORIN-CASE-A aluminum case (sold by SpotPear), with a 256 GB M.2 NVMe SSD on the underside of the carrier board.

- **Case assembly:** [Waveshare wiki + video](https://www.waveshare.com/wiki/JETSON-ORIN-CASE-A). The SSD sits under the board, so the board must come out of the case to swap it.
- **Display:** DisplayPort only. Uses an active DP-to-HDMI adapter (a passive one can cap at 1080p).
- **Camera:** none yet. CSI cameras use the 22-pin connectors; IMX219-based cameras work out of the box. A USB webcam is the simple option.

Button header (J14, 12 pins, two rows of six):

| Pin(s) | Signal | What's connected |
| --- | --- | --- |
| 1 | PC\_LED− | Black LED wire |
| 2 | PC\_LED+ | Red LED wire |
| 3, 4 | Debug UART | Nothing — leave free |
| 5 + 6 | Auto power-on disable | Jumper cap: power button is needed to turn on |
| 11 + 12 | GND + SLEEP/WAKE | Yellow and blue button wires (either order) |

The red and black wires were swapped once and the LED stayed dark; LEDs only work one way round. Remove the jumper on 5+6 if the Jetson should start as soon as it's plugged in.

## Install history

On Oct 11, 2026, JetPack 7.2.1 was installed straight onto the NVMe SSD using NVIDIA's Jetson ISO installer from a USB stick.

1. Checked firmware in the UEFI menu (tap Esc at the NVIDIA logo): it was 36.4.3, new enough, so the microSD firmware-bridge path was skipped.
2. Wrote the Jetson ISO (r39.2.1) to a SanDisk USB stick with Balena Etcher on the PC.
3. Booted the USB via Esc → Boot Manager. Pressed **Y** at the firmware update prompt (30-second countdown); it updated in two passes.
4. Chose "Install Jetson ISO r39.2.1" with the NVMe SSD as the target.
5. First boot: license, language, Wi-Fi, user `stuart`.
6. Set power mode to MAXN SUPER, renamed the host to `stuart-orin`, enabled SSH, switched to headless.

A 64 GB SanDisk microSD card was bought for the firmware path but wasn't needed. Keep it as a spare.

## Access

Always include the username: plain `ssh stuart-orin.local` tries the Windows username `sbelc` and fails with "Permission denied."

- **From the PC:** `ssh stuart@stuart-orin.local`. If the name doesn't resolve, use the IP from `hostname -I`.
- **Shortcut:** the file `C:\Users\<you>\.ssh\config` (no `.txt` extension) holds:

```
Host orin
    HostName stuart-orin.local
    User stuart
```

- **Passwordless login (SSH key):** set up Oct 11, 2026, so `ssh orin` (and Claude Code) connects without a password. To redo it on a new PC, run in PowerShell:

```
ssh-keygen -t ed25519
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh stuart@stuart-orin.local "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

- **Over USB-C:** the Jetson is also at `192.168.55.1` when plugged into the PC by USB-C.
- **Renaming:** hostnames can't contain underscores. Change with `sudo hostnamectl set-hostname <name>`, update the `127.0.1.1` line in `/etc/hosts`, then reboot.
- **SSH server:** `sudo apt install -y openssh-server && sudo systemctl enable --now ssh`.

## Boot and power modes

The Jetson boots headless to free about 1 GB of memory for AI models; the desktop can be turned back on anytime.

| Want | Command |
| --- | --- |
| Desktop every boot | `sudo systemctl set-default graphical.target && sudo reboot` |
| Desktop just this once | `sudo systemctl start graphical.target` |
| Back to headless | `sudo systemctl set-default multi-user.target && sudo reboot` |
| List power modes | `grep POWER_MODEL /etc/nvpmodel.conf` |
| Set MAXN SUPER | `sudo nvpmodel -m <ID of MAXN_SUPER>` (usually 2) |
| Check power mode | `sudo nvpmodel -q` |

The Balanced / Power Saver menu in the Ubuntu top bar is Ubuntu's setting, not the Jetson performance mode.

## AI setup

Ollama is installed natively and uses the GPU through its CUDA 13 library, even though the installer warned "Unsupported JetPack version."

- **Install:** `curl -fsSL https://ollama.com/install.sh | sh` (runs as a system service).
- **GPU check:** `journalctl -u ollama --no-pager | grep -i "inference compute"` should show `library=CUDA ... description=Orin`. The "skipping CUDA device" line about cuda\_v12 is harmless.
- **Memory:** 7.3 GB total for CPU + GPU; about 5.2 GB was free with the desktop on.
- **Models:** `qwen3:8b` (about 5 GB) is the strongest that should fit. If `ollama ps` doesn't show 100% GPU, use `qwen3:4b` or `gemma3:4b`. Type `/set nothink` in a chat for shorter answers.
### Open WebUI (browser chat)

Installed Oct 11, 2026. Browse to **`http://stuart-orin.local:8080`** from any device on the home network. The first account created becomes the admin.

- **Runs as:** Docker container `open-webui`, restarts automatically on boot. `stuart` is in the `docker` group, so no `sudo` is needed.
- **Install command:** `docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main`
- **Ollama stays private:** with `--network=host`, Open WebUI reaches Ollama on `127.0.0.1`, so Ollama does not need to be opened to the network (`OLLAMA_HOST=0.0.0.0` is only needed for tools on the PC that call Ollama directly).
- **Update:** `docker pull ghcr.io/open-webui/open-webui:main && docker rm -f open-webui`, then rerun the install command. Chats and accounts live in the `open-webui` volume and are kept.
- **Status / logs:** `docker ps` / `docker logs --tail 50 open-webui`. First start takes a couple of minutes while it downloads a small embedding model.
- **Memory:** the container uses about 0.9 GB, which leaves less room for models. Stop it with `docker stop open-webui` when running `qwen3:8b`.
- **Required settings for small models** (Admin Panel → Settings → Models → pick the model; do this for each model):
  - **Builtin Tools: all off.** Open WebUI 0.12 attaches about 6,900 tokens of tool descriptions to *every* message by default, even "hello". That overflows the 4,096-token context (Ollama silently truncates), makes each reply slow, and grew `qwen3.5:4b` until the Jetson ran out of memory.
  - **Advanced Params → Think: Off.** Thinking can add thousands of hidden tokens (minutes at 15 tokens/s). Turn it on per chat for hard questions.
  - Optional: Admin Panel → Settings → Interface → turn off Title, Tags, Follow-up and Autocomplete generation (each is an extra model request after every message).
- **Result:** a short chat went from ~6,900 truncated prompt tokens to ~1,000, with no truncation.
- **"No models found" on Workspace → Models** is normal: that page lists only custom presets. The chat model menu is what matters.

* [x] Confirm `qwen3:8b` runs at 100% GPU and note the speed here

**Benchmark (Oct 11, 2026, headless, MAXN SUPER):** `qwen3:8b` loads as 5.6 GB at **100% GPU** (4096 context). With thinking off it generates about **12 tokens/s** and reads prompts at about 30 tokens/s. Run `ollama run qwen3:8b --verbose --think=false "<prompt>"` to re-measure.

| Model | Ollama size | System RAM used when loaded | Speed (thinking off) | GPU |
| --- | --- | --- | --- | --- |
| `qwen3:8b` | 5.6 GB | ~5.9 GB (only ~0.7 GB left) | ~12 tokens/s | 100% |
| `qwen3.5:4b` | 3.1 GB | ~5.0 GB (~1.6 GB left) | ~15.5 tokens/s | 100% |

`qwen3.5:4b` is about 30% faster and leaves more headroom, but uses more RAM than its size suggests. The first load takes about 40 seconds; after that it starts instantly while it stays in memory (5 minutes by default).

## Swap

An 8 GB swap file was added on Oct 11, 2026 after an out-of-memory crash. It's a safety net, not a speed-up: GPU memory can't be swapped, but moving idle CPU-side data (Open WebUI, Docker, services) to the SSD frees shared RAM for the model.

- **File:** `/swapfile` (8 GB, root-only), enabled at boot by the line `/swapfile none swap sw 0 0` in `/etc/fstab`.
- **Swappiness:** 10 (set in `/etc/sysctl.d/99-swappiness.conf`), so swap is only used when memory is really tight.
- **Check:** `free -h` or `swapon --show`. Heavy, constant swap use means the model or context is too big.
- **Setup commands:**

```
sudo fallocate -l 8G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf && sudo sysctl -p /etc/sysctl.d/99-swappiness.conf
```

- **Remove:** `sudo swapoff /swapfile && sudo rm /swapfile`, delete the `/swapfile` line from `/etc/fstab`, and delete `/etc/sysctl.d/99-swappiness.conf`.

## Reinstalling from scratch

A reinstall erases the SSD, so copy anything you want to keep off it first.

1. Download the latest Jetson ISO from the [JetPack downloads page](https://developer.nvidia.com/embedded/jetpack/downloads) and write it to a USB stick with [Balena Etcher](https://etcher.balena.io/).
2. Connect monitor, wired USB keyboard, and the USB stick. Power on with the case button.
3. Tap Esc at the NVIDIA logo → Boot Manager → the USB stick.
4. Watch for the firmware update prompt and press **Y** within 30 seconds.
5. Install to the NVMe SSD, remove the USB stick, reboot, and redo the setup steps in Install history.

## Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Won't turn on when plugged in | Jumper on pins 5+6 disables auto power-on | Press the case button |
| Power button LED dark | Red/black LED wires reversed | Unplug, swap the wires on pins 1 and 2 |
| `ssh` says "Permission denied" | Username missing, so Windows name was used | `ssh stuart@stuart-orin.local` |
| `ssh orin` "could not resolve" | SSH config file missing or saved as `.txt` | Recreate `~\.ssh\config` without an extension |
| `stuart-orin.local` not found | Jetson still booting, or name lookup blocked | Wait a minute, or use the IP from `hostname -I` |
| Black screen or `Shell>` at boot | Firmware too old for the JetPack being booted | Power off; do NVIDIA's JetPack 6.x update path |
| Model slow, `ollama ps` shows CPU | Not enough free memory for the GPU | Go headless, or use a 4B model |
| Open WebUI: "Ollama: Server disconnected" | Out of memory: kernel killed `llama-server` (check `journalctl -k \| grep -i "killed process"`) | Builtin Tools + Think off for the model, start a new chat, add swap |
| Replies take minutes / model forgets chat | Prompt too big for context (`journalctl -u ollama \| grep truncating`) | Builtin Tools off; Think off |
| No display at all | Wrong port or passive adapter limits | Use the DisplayPort with an active adapter |

## Sources

- [NVIDIA – Orin Nano Developer Kit Quick Start Guide](https://docs.nvidia.com/jetson/orin-nano-devkit/user-guide/latest/quick_start.html)
- [NVIDIA – JetPack 6.x Update Path](https://docs.nvidia.com/jetson/orin-nano-devkit/user-guide/latest/update_firmware.html)
- [NVIDIA – Hardware Layout](https://docs.nvidia.com/jetson/orin-nano-devkit/user-guide/latest/hardware_layout.html)
- [NVIDIA – Orin Nano Carrier Board Specification (button header J14)](https://uelectronics.com/wp-content/uploads/2023/05/Jetson-Orin-Nano-DevKit-Carrier-Board-Specification.pdf)
- [Waveshare – JETSON-ORIN-CASE-A wiki](https://www.waveshare.com/wiki/JETSON-ORIN-CASE-A)
- [Jetson AI Lab – Getting Started (SSH)](https://www.jetson-ai-lab.com/tutorials/getting-started-with-jetson/)
- [Jetson AI Lab – Ollama on Jetson](https://www.jetson-ai-lab.com/tutorials/ollama)
- [Jetson AI Lab – RAM Optimization](https://www.jetson-ai-lab.com/tutorials/ram-optimization)
