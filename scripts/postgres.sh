#!/usr/bin/env bash
#
# postgres.sh — install PostgreSQL server + client from the PGDG apt repo.
# Idempotent: configures the PGDG repo once and skips install when the
# requested major version is already present. Enables the service.
#
# Override: PG_VERSION=16 ./postgres.sh
#
set -euo pipefail

PG_VERSION="${PG_VERSION:-16}"

log() { printf '\033[1;34m[postgres]\033[0m %s\n' "$*"; }

export DEBIAN_FRONTEND=noninteractive
. /etc/os-release
CODENAME="${VERSION_CODENAME:-$(lsb_release -cs)}"

if command -v psql >/dev/null 2>&1 && dpkg -l "postgresql-${PG_VERSION}" >/dev/null 2>&1; then
  log "postgresql-${PG_VERSION} already installed: $(psql --version)"
else
  log "configuring PGDG apt repository"
  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends curl ca-certificates gnupg lsb-release
  sudo install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/pgdg.gpg ]]; then
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
      | sudo gpg --dearmor -o /etc/apt/keyrings/pgdg.gpg
    sudo chmod a+r /etc/apt/keyrings/pgdg.gpg
  fi
  echo "deb [signed-by=/etc/apt/keyrings/pgdg.gpg] https://apt.postgresql.org/pub/repos/apt ${CODENAME}-pgdg main" \
    | sudo tee /etc/apt/sources.list.d/pgdg.list >/dev/null
  sudo apt-get update -y
  log "installing postgresql-${PG_VERSION}"
  sudo apt-get install -y "postgresql-${PG_VERSION}" "postgresql-client-${PG_VERSION}"
fi

if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable --now postgresql >/dev/null 2>&1 || true
fi

log "verify: $(psql --version)"
