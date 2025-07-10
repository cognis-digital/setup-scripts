#!/usr/bin/env bash
#
# go.sh — install the official Go toolchain into /usr/local/go and put it on
# PATH. Idempotent: skips download when the requested version is already
# installed; replaces /usr/local/go when upgrading.
#
# Override: GO_VERSION=1.22.4 ./go.sh
#
set -euo pipefail

GO_VERSION="${GO_VERSION:-1.22.4}"
INSTALL_ROOT="/usr/local"
GO_DIR="$INSTALL_ROOT/go"

log() { printf '\033[1;34m[go]\033[0m %s\n' "$*"; }

if [[ -x "$GO_DIR/bin/go" ]]; then
  CURRENT="$("$GO_DIR/bin/go" version | awk '{print $3}' | sed 's/^go//')"
  if [[ "$CURRENT" == "$GO_VERSION" ]]; then
    log "Go $GO_VERSION already installed"
    log "verify: $("$GO_DIR/bin/go" version)"
    exit 0
  fi
  log "found Go $CURRENT, upgrading to $GO_VERSION"
fi

case "$(uname -m)" in
  x86_64)  ARCH=amd64 ;;
  aarch64) ARCH=arm64 ;;
  armv6l)  ARCH=armv6l ;;
  *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac

TARBALL="go${GO_VERSION}.linux-${ARCH}.tar.gz"
URL="https://go.dev/dl/${TARBALL}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

log "downloading ${URL}"
curl -fsSL "$URL" -o "$TMP/$TARBALL"

log "installing into $GO_DIR"
sudo rm -rf "$GO_DIR"
sudo tar -C "$INSTALL_ROOT" -xzf "$TMP/$TARBALL"

# Idempotently add Go to PATH for login shells.
PROFILE="/etc/profile.d/go.sh"
if [[ ! -f "$PROFILE" ]]; then
  log "writing $PROFILE"
  echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee "$PROFILE" >/dev/null
  sudo chmod 0644 "$PROFILE"
fi
export PATH="$PATH:$GO_DIR/bin"

log "verify: $(go version)"
