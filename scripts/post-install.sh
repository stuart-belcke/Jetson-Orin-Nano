#!/usr/bin/env bash
# Post-install setup for a fresh JetPack install on the Jetson Orin Nano.
# Run ON THE JETSON after the first-boot Ubuntu setup:
#
#   bash post-install.sh                 # hostname stuart-orin, keep the desktop
#   bash post-install.sh --headless      # also boot to text mode (frees ~1 GB RAM)
#   bash post-install.sh --hostname my-orin --headless
#
# What it does: installs updates, enables SSH, sets the hostname,
# switches to MAXN SUPER power mode, and optionally goes headless.
# Safe to run more than once.

set -euo pipefail

HOSTNAME_NEW="stuart-orin"
HEADLESS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hostname) HOSTNAME_NEW="$2"; shift 2 ;;
    --headless) HEADLESS=1; shift ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ "$HOSTNAME_NEW" == *_* ]]; then
  echo "Hostnames can't contain underscores. Use a hyphen, e.g. stuart-orin." >&2
  exit 1
fi

step() { printf '\n==> %s\n' "$*"; }

step "Installing updates"
sudo apt update
sudo apt upgrade -y

step "Enabling the SSH server"
sudo apt install -y openssh-server
sudo systemctl enable --now ssh

step "Setting hostname to ${HOSTNAME_NEW}"
sudo hostnamectl set-hostname "$HOSTNAME_NEW"
if grep -q '^127\.0\.1\.1' /etc/hosts; then
  sudo sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t${HOSTNAME_NEW}/" /etc/hosts
else
  printf '127.0.1.1\t%s\n' "$HOSTNAME_NEW" | sudo tee -a /etc/hosts >/dev/null
fi

step "Switching to MAXN SUPER power mode"
MAXN_ID=$(grep -E 'POWER_MODEL.*NAME=MAXN_SUPER' /etc/nvpmodel.conf | sed -E 's/.*ID=([0-9]+).*/\1/' | head -n1 || true)
if [[ -n "$MAXN_ID" ]]; then
  # nvpmodel may ask whether to reboot; answer no, since this script ends with a reboot prompt anyway.
  echo "NO" | sudo nvpmodel -m "$MAXN_ID" || true
  sudo nvpmodel -q
else
  echo "MAXN_SUPER not found in /etc/nvpmodel.conf. Available modes:"
  grep POWER_MODEL /etc/nvpmodel.conf || true
fi

if [[ "$HEADLESS" -eq 1 ]]; then
  step "Setting boot target to headless (text mode)"
  sudo systemctl set-default multi-user.target
  echo "Desktop later: sudo systemctl set-default graphical.target && sudo reboot"
fi

step "Checking boot drive"
lsblk -o NAME,SIZE,MOUNTPOINT | grep -E 'nvme|NAME' || true

step "Done"
echo "Reboot to apply everything:  sudo reboot"
echo "Then from your PC:            ssh $(whoami)@${HOSTNAME_NEW}.local"
