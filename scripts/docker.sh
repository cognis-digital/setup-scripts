#!/usr/bin/env bash
#
# docker.sh — install Docker Engine (CE) with the buildx and compose plugins
# from Docker's official apt repository. Adds the invoking user to the docker
# group. Idempotent: skips repo/key setup and package install when present.
#
set -euo pipefail

log() { printf '\033[1;36m[docker]\033[0m %s\n' "$*"; }

if command -v docker >/dev/null 2>&1; then
  log "already installed: $(docker --version)"
else
  export DEBIAN_FRONTEND=noninteractive
  . /etc/os-release
  DISTRO_ID="${ID}"            # ubuntu | debian
  CODENAME="${VERSION_CODENAME:-$(lsb_release -cs)}"

  log "installing prerequisites"
  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends ca-certificates curl gnupg

  log "adding Docker GPG key"
  sudo install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL "https://download.docker.com/linux/${DISTRO_ID}/gpg" \
      | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  log "adding Docker apt repository"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRO_ID} ${CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  log "installing Docker Engine + plugins"
  sudo apt-get update -y
  sudo apt-get install -y \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# Ensure the service is enabled and running.
if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable --now docker >/dev/null 2>&1 || true
fi

# Add the current (non-root) user to the docker group, idempotently.
TARGET_USER="${SUDO_USER:-$USER}"
if [[ "$TARGET_USER" != "root" ]]; then
  if ! id -nG "$TARGET_USER" | tr ' ' '\n' | grep -qx docker; then
    log "adding $TARGET_USER to the docker group (re-login required)"
    sudo usermod -aG docker "$TARGET_USER"
  fi
fi

log "verify: $(docker --version)"
