#!/usr/bin/env bash
# Install Ollama on the Jetson, confirm it sees the GPU, and pull a model.
# Run ON THE JETSON (over SSH is fine):
#
#   bash install-ollama.sh                  # installs Ollama + pulls qwen3:8b
#   bash install-ollama.sh --model qwen3:4b # smaller, faster model
#   bash install-ollama.sh --webui          # also start Open WebUI (needs Docker)
#
# On JetPack 7 the installer warns "Unsupported JetPack version". That is
# expected: Ollama still finds the GPU through its CUDA 13 library.

set -euo pipefail

MODEL="qwen3:8b"
WEBUI=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model) MODEL="$2"; shift 2 ;;
    --webui) WEBUI=1; shift ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

step() { printf '\n==> %s\n' "$*"; }

if command -v ollama >/dev/null 2>&1; then
  step "Ollama already installed ($(ollama --version 2>/dev/null | head -n1))"
else
  step "Installing Ollama"
  curl -fsSL https://ollama.com/install.sh | sh
fi

step "Waiting for the Ollama service"
for _ in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:11434/api/version >/dev/null 2>&1; then break; fi
  sleep 1
done
curl -fsS http://127.0.0.1:11434/api/version && echo

step "Checking GPU detection"
GPU_LINE=$(journalctl -u ollama --no-pager 2>/dev/null | grep -i 'inference compute' | tail -n1 || true)
echo "${GPU_LINE:-No 'inference compute' line found yet}"
if [[ "$GPU_LINE" == *"library=CUDA"* ]]; then
  echo "OK: Ollama is using the GPU."
else
  echo "WARNING: GPU not confirmed. Models may run on the CPU only." >&2
fi

step "Free memory"
free -h

step "Pulling ${MODEL}"
ollama pull "$MODEL"

step "Quick test"
ollama run "$MODEL" "Reply with one short sentence confirming you are running." || true
ollama ps
echo "PROCESSOR should read 100% GPU. If it shows CPU, try a 4B model or go headless."

if [[ "$WEBUI" -eq 1 ]]; then
  step "Starting Open WebUI"
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker isn't installed. Install it first, then rerun with --webui." >&2
    exit 1
  fi
  if sudo docker ps -a --format '{{.Names}}' | grep -qx open-webui; then
    echo "Open WebUI container already exists. Starting it."
    sudo docker start open-webui
  else
    sudo docker run -d --network=host \
      -v open-webui:/app/backend/data \
      -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
      --name open-webui --restart always \
      ghcr.io/open-webui/open-webui:main
  fi
  echo "Open WebUI: http://$(hostname).local:8080"
fi

step "Done"
echo "Chat:  ollama run ${MODEL}     (type /bye to exit)"
