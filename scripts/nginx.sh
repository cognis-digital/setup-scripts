#!/usr/bin/env bash
#
# nginx.sh — install nginx from the distro repository and enable the service.
# Idempotent: skips install when present; always ensures the service is up.
#
set -euo pipefail

log() { printf '\033[1;32m[nginx]\033[0m %s\n' "$*"; }

export DEBIAN_FRONTEND=noninteractive

if command -v nginx >/dev/null 2>&1; then
  log "nginx already installed: $(nginx -v 2>&1)"
else
  log "installing nginx"
  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends nginx
fi

if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable --now nginx >/dev/null 2>&1 || true
  log "service status: $(systemctl is-active nginx 2>/dev/null || echo unknown)"
fi

log "verify: $(nginx -v 2>&1)"
