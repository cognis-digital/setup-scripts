#!/usr/bin/env bash
#
# tailscale.sh — install the Tailscale daemon and CLI from the official apt
# repository. Idempotent: configures the repo once; does NOT auto-authenticate.
# Run `sudo tailscale up` afterward (optionally with TS_AUTHKEY) to join a net.
#
set -euo pipefail

log() { printf '\033[1;35m[tailscale]\033[0m %s\n' "$*"; }

export DEBIAN_FRONTEND=noninteractive
. /etc/os-release
DISTRO_ID="${ID}"
CODENAME="${VERSION_CODENAME:-$(lsb_release -cs)}"

if command -v tailscale >/dev/null 2>&1; then
  log "tailscale already installed: $(tailscale version | head -1)"
else
  log "configuring Tailscale apt repository"
  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends curl ca-certificates gnupg
  sudo install -m 0755 -d /usr/share/keyrings
  if [[ ! -f /usr/share/keyrings/tailscale-archive-keyring.gpg ]]; then
    curl -fsSL "https://pkgs.tailscale.com/stable/${DISTRO_ID}/${CODENAME}.noarmor.gpg" \
      | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
  fi
  curl -fsSL "https://pkgs.tailscale.com/stable/${DISTRO_ID}/${CODENAME}.tailscale-keyring.list" \
    | sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null
  sudo apt-get update -y
  log "installing tailscale"
  sudo apt-get install -y tailscale
fi

if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable --now tailscaled >/dev/null 2>&1 || true
fi

# Optionally bring the node up if an auth key was provided.
if [[ -n "${TS_AUTHKEY:-}" ]]; then
  log "bringing tailscale up with provided auth key"
  sudo tailscale up --authkey "$TS_AUTHKEY" ${TS_UP_ARGS:-}
else
  log "installed. To connect: sudo tailscale up"
fi

log "verify: $(tailscale version | head -1)"
