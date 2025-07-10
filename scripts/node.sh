#!/usr/bin/env bash
#
# node.sh — install nvm (Node Version Manager) and a Node.js version, then
# enable corepack (yarn/pnpm shims). Default installs the latest LTS.
# Idempotent: reuses an existing nvm install and skips Node if already present.
#
# Override: NODE_VERSION=20 ./node.sh   (number = major LTS, or 'lts/*', or full)
#
set -euo pipefail

NVM_VERSION="${NVM_VERSION:-v0.40.1}"
NODE_VERSION="${NODE_VERSION:-lts/*}"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

log() { printf '\033[1;32m[node]\033[0m %s\n' "$*"; }

if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  log "installing nvm ${NVM_VERSION}"
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
else
  log "nvm already present at $NVM_DIR"
fi

# Load nvm into this shell.
export NVM_DIR
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"

if nvm which "$NODE_VERSION" >/dev/null 2>&1; then
  log "Node $NODE_VERSION already installed"
else
  log "installing Node ($NODE_VERSION)"
  nvm install "$NODE_VERSION"
fi

nvm alias default "$NODE_VERSION" >/dev/null 2>&1 || true
nvm use default >/dev/null 2>&1 || true

if command -v corepack >/dev/null 2>&1; then
  corepack enable >/dev/null 2>&1 || true
fi

# Idempotently ensure nvm is sourced in ~/.bashrc.
MARKER="# >>> cognis-setup nvm >>>"
if ! grep -qF "$MARKER" "$HOME/.bashrc" 2>/dev/null; then
  log "adding nvm init block to ~/.bashrc"
  {
    echo "$MARKER"
    echo 'export NVM_DIR="$HOME/.nvm"'
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'
    echo '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"'
    echo "# <<< cognis-setup nvm <<<"
  } >> "$HOME/.bashrc"
fi

log "verify: node $(node --version), npm $(npm --version)"
