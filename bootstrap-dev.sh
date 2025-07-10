#!/usr/bin/env bash
#
# bootstrap-dev.sh — install a sensible default developer stack.
#
# Installs (in order): base build tools, git, Docker, Node (LTS via nvm),
# Python (pyenv), Go, Rust, and the GitHub CLI. Edit STACK below to taste.
#
# Idempotent: delegates to the per-tool scripts in scripts/, each of which
# is itself idempotent. Safe to re-run.
#
set -euo pipefail

log() { printf '\033[1;32m[bootstrap]\033[0m %s\n' "$*"; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$HERE/scripts"

# Default developer stack. Order matters (e.g. base before everything).
STACK=(
  docker
  node
  python
  go
  rust
  gh-cli
)

log "Installing base packages (build-essential, git, curl, ca-certificates)"
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  git \
  gnupg \
  lsb-release \
  pkg-config

for tool in "${STACK[@]}"; do
  script="$SCRIPTS_DIR/$tool.sh"
  if [[ ! -f "$script" ]]; then
    log "WARNING: no script for '$tool' (skipping)"
    continue
  fi
  log "=== $tool ==="
  bash "$script"
done

log "Developer stack ready. Open a new shell or run: source ~/.bashrc"
