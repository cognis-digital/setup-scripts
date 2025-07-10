#!/usr/bin/env bash
#
# rust.sh — install the Rust toolchain via rustup (stable channel) for the
# current user. Idempotent: if rustup is present it just runs `rustup update`.
#
set -euo pipefail

RUST_CHANNEL="${RUST_CHANNEL:-stable}"
CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"

log() { printf '\033[1;31m[rust]\033[0m %s\n' "$*"; }

export CARGO_HOME RUSTUP_HOME

if command -v rustup >/dev/null 2>&1 || [[ -x "$CARGO_HOME/bin/rustup" ]]; then
  log "rustup already installed; updating $RUST_CHANNEL"
  "$CARGO_HOME/bin/rustup" default "$RUST_CHANNEL" >/dev/null 2>&1 || true
  "$CARGO_HOME/bin/rustup" update "$RUST_CHANNEL"
else
  log "installing rustup ($RUST_CHANNEL)"
  curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path --default-toolchain "$RUST_CHANNEL"
fi

# Load cargo env for this shell.
# shellcheck disable=SC1091
[[ -s "$CARGO_HOME/env" ]] && . "$CARGO_HOME/env"

# Idempotently source cargo env in ~/.bashrc.
MARKER="# >>> cognis-setup rust >>>"
if ! grep -qF "$MARKER" "$HOME/.bashrc" 2>/dev/null; then
  log "adding cargo env to ~/.bashrc"
  {
    echo "$MARKER"
    echo '[ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"'
    echo "# <<< cognis-setup rust <<<"
  } >> "$HOME/.bashrc"
fi

log "verify: $("$CARGO_HOME/bin/rustc" --version)"
