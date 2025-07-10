#!/usr/bin/env bash
#
# gh-cli.sh — install the GitHub CLI (gh) from GitHub's official apt repo.
# Idempotent: configures the repo/key once and skips install when present.
#
set -euo pipefail

log() { printf '\033[1;30m[gh-cli]\033[0m %s\n' "$*"; }

export DEBIAN_FRONTEND=noninteractive

if command -v gh >/dev/null 2>&1; then
  log "gh already installed: $(gh --version | head -1)"
else
  log "configuring GitHub CLI apt repository"
  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends curl ca-certificates gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/githubcli-archive-keyring.gpg ]]; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
    sudo chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  fi
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update -y
  log "installing gh"
  sudo apt-get install -y gh
fi

log "verify: $(gh --version | head -1)"
log "next: gh auth login"
