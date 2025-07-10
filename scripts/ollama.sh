#!/usr/bin/env bash
#
# ollama.sh — install the Ollama local LLM runtime via the official installer,
# which also sets up a systemd service on systemd hosts.
# Idempotent: skips the installer when the `ollama` binary already exists.
#
# Optional: OLLAMA_PULL="llama3.1 qwen2.5" ./ollama.sh  (pull models after install)
#
set -euo pipefail

log() { printf '\033[1;36m[ollama]\033[0m %s\n' "$*"; }

if command -v ollama >/dev/null 2>&1; then
  log "ollama already installed: $(ollama --version 2>/dev/null | head -1)"
else
  log "installing ollama"
  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends curl ca-certificates
  curl -fsSL https://ollama.com/install.sh | sh
fi

if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable --now ollama >/dev/null 2>&1 || true
fi

# Optionally pre-pull models (idempotent — ollama skips already-present models).
if [[ -n "${OLLAMA_PULL:-}" ]]; then
  for model in $OLLAMA_PULL; do
    log "pulling model: $model"
    ollama pull "$model"
  done
fi

log "verify: $(ollama --version 2>/dev/null | head -1)"
