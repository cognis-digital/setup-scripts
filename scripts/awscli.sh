#!/usr/bin/env bash
#
# awscli.sh — install AWS CLI v2 from the official zip bundle into /usr/local.
# Idempotent: skips download when v2 is already installed; supports --update.
#
set -euo pipefail

log() { printf '\033[1;33m[awscli]\033[0m %s\n' "$*"; }

if command -v aws >/dev/null 2>&1 && aws --version 2>&1 | grep -q 'aws-cli/2'; then
  log "aws-cli v2 already installed: $(aws --version 2>&1)"
  exit 0
fi

case "$(uname -m)" in
  x86_64)  AWS_ARCH=x86_64 ;;
  aarch64) AWS_ARCH=aarch64 ;;
  *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac

log "installing prerequisites (curl, unzip)"
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends curl unzip ca-certificates

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

URL="https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip"
log "downloading ${URL}"
curl -fsSL "$URL" -o "$TMP/awscliv2.zip"
unzip -q "$TMP/awscliv2.zip" -d "$TMP"

# The installer is idempotent with --update when already present.
if [[ -d /usr/local/aws-cli ]]; then
  log "updating existing aws-cli v2 install"
  sudo "$TMP/aws/install" --update
else
  log "installing aws-cli v2"
  sudo "$TMP/aws/install"
fi

log "verify: $(aws --version 2>&1)"
