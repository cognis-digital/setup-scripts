#!/usr/bin/env bash
#
# docker-compose.sh — install the standalone docker-compose v2 binary into
# /usr/local/bin. Use this when you want the `docker-compose` command without
# the Docker apt plugin (e.g. minimal hosts). Idempotent on matching version.
#
set -euo pipefail

DOCKER_COMPOSE_VERSION="${DOCKER_COMPOSE_VERSION:-v2.29.7}"
INSTALL_PATH="/usr/local/bin/docker-compose"

log() { printf '\033[1;36m[docker-compose]\033[0m %s\n' "$*"; }

if command -v docker-compose >/dev/null 2>&1; then
  CURRENT="$(docker-compose version --short 2>/dev/null || true)"
  if [[ "v${CURRENT#v}" == "$DOCKER_COMPOSE_VERSION" ]]; then
    log "already at desired version: ${DOCKER_COMPOSE_VERSION}"
    exit 0
  fi
  log "found ${CURRENT:-unknown}, updating to ${DOCKER_COMPOSE_VERSION}"
fi

ARCH="$(uname -m)"
OS="$(uname -s)"
URL="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-${OS}-${ARCH}"

log "downloading ${URL}"
TMP="$(mktemp)"
curl -fsSL "$URL" -o "$TMP"
sudo install -m 0755 "$TMP" "$INSTALL_PATH"
rm -f "$TMP"

log "verify: $($INSTALL_PATH --version)"
