#!/usr/bin/env bash
#
# python.sh — install pyenv plus the CPython build dependencies, then build a
# pinned Python version and set it as the global default.
# Idempotent: reuses pyenv and skips building a version that already exists.
#
# Override: PYTHON_VERSION=3.12.4 ./python.sh
#
set -euo pipefail

PYTHON_VERSION="${PYTHON_VERSION:-3.12.4}"
PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"

log() { printf '\033[1;33m[python]\033[0m %s\n' "$*"; }

log "installing CPython build dependencies"
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
  libsqlite3-dev curl git libncursesw5-dev xz-utils tk-dev libxml2-dev \
  libxmlsec1-dev libffi-dev liblzma-dev

if [[ ! -d "$PYENV_ROOT" ]]; then
  log "installing pyenv into $PYENV_ROOT"
  git clone --depth 1 https://github.com/pyenv/pyenv.git "$PYENV_ROOT"
else
  log "pyenv already present at $PYENV_ROOT"
fi

export PYENV_ROOT
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

if pyenv versions --bare | grep -qx "$PYTHON_VERSION"; then
  log "Python $PYTHON_VERSION already built"
else
  log "building Python $PYTHON_VERSION (this can take a few minutes)"
  pyenv install "$PYTHON_VERSION"
fi

pyenv global "$PYTHON_VERSION"

# Idempotently add pyenv init to ~/.bashrc.
MARKER="# >>> cognis-setup pyenv >>>"
if ! grep -qF "$MARKER" "$HOME/.bashrc" 2>/dev/null; then
  log "adding pyenv init block to ~/.bashrc"
  {
    echo "$MARKER"
    echo 'export PYENV_ROOT="$HOME/.pyenv"'
    echo '[ -d "$PYENV_ROOT/bin" ] && export PATH="$PYENV_ROOT/bin:$PATH"'
    echo 'eval "$(pyenv init -)"'
    echo "# <<< cognis-setup pyenv <<<"
  } >> "$HOME/.bashrc"
fi

log "verify: $(python --version)"
