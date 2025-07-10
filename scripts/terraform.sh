#!/usr/bin/env bash
#
# terraform.sh — install Terraform from the official HashiCorp apt repository.
# Idempotent: configures the repo/key only once and installs a pinned version
# when TERRAFORM_VERSION is set, otherwise the latest available.
#
# Override: TERRAFORM_VERSION=1.8.5 ./terraform.sh   (empty = latest)
#
set -euo pipefail

TERRAFORM_VERSION="${TERRAFORM_VERSION:-}"

log() { printf '\033[1;35m[terraform]\033[0m %s\n' "$*"; }

export DEBIAN_FRONTEND=noninteractive
. /etc/os-release
CODENAME="${VERSION_CODENAME:-$(lsb_release -cs)}"

log "ensuring HashiCorp apt repository"
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends gnupg software-properties-common curl ca-certificates
sudo install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/hashicorp.gpg ]]; then
  curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg
  sudo chmod a+r /etc/apt/keyrings/hashicorp.gpg
fi
echo "deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com ${CODENAME} main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
sudo apt-get update -y

if command -v terraform >/dev/null 2>&1 && [[ -z "$TERRAFORM_VERSION" ]]; then
  log "terraform already installed: $(terraform version | head -1)"
else
  if [[ -n "$TERRAFORM_VERSION" ]]; then
    log "installing terraform=${TERRAFORM_VERSION}"
    sudo apt-get install -y "terraform=${TERRAFORM_VERSION}-1"
  else
    log "installing latest terraform"
    sudo apt-get install -y terraform
  fi
fi

log "verify: $(terraform version | head -1)"
