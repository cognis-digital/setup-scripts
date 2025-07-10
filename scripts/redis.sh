#!/usr/bin/env bash
#
# redis.sh — install redis-server and redis-cli from the official Redis apt
# repository. Idempotent: configures the repo once and enables the service.
#
set -euo pipefail

log() { printf '\033[1;31m[redis]\033[0m %s\n' "$*"; }

export DEBIAN_FRONTEND=noninteractive
. /etc/os-release
CODENAME="${VERSION_CODENAME:-$(lsb_release -cs)}"

if command -v redis-server >/dev/null 2>&1; then
  log "redis already installed: $(redis-server --version | awk '{print $1, $3}')"
else
  log "configuring Redis apt repository"
  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends curl ca-certificates gnupg lsb-release
  sudo install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/redis.gpg ]]; then
    curl -fsSL https://packages.redis.io/gpg \
      | sudo gpg --dearmor -o /etc/apt/keyrings/redis.gpg
    sudo chmod a+r /etc/apt/keyrings/redis.gpg
  fi
  echo "deb [signed-by=/etc/apt/keyrings/redis.gpg] https://packages.redis.io/deb ${CODENAME} main" \
    | sudo tee /etc/apt/sources.list.d/redis.list >/dev/null
  sudo apt-get update -y
  log "installing redis"
  sudo apt-get install -y redis
fi

if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable --now redis-server >/dev/null 2>&1 || true
fi

log "verify: $(redis-cli --version)"
