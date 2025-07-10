#!/usr/bin/env bash
#
# kubectl-helm.sh — install kubectl (from the official Kubernetes apt repo)
# and Helm 3 (from the official get-helm-3 script).
# Idempotent: skips each tool if already present; re-running refreshes apt.
#
# Override: K8S_MINOR=v1.30 ./kubectl-helm.sh
#
set -euo pipefail

K8S_MINOR="${K8S_MINOR:-v1.30}"

log() { printf '\033[1;36m[kubectl-helm]\033[0m %s\n' "$*"; }

export DEBIAN_FRONTEND=noninteractive

if command -v kubectl >/dev/null 2>&1; then
  log "kubectl already installed: $(kubectl version --client --output=yaml 2>/dev/null | grep gitVersion | head -1 | awk '{print $2}')"
else
  log "installing kubectl (channel $K8S_MINOR)"
  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ]]; then
    curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/Release.key" \
      | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    sudo chmod a+r /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  fi
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/ /" \
    | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y kubectl
fi

if command -v helm >/dev/null 2>&1; then
  log "helm already installed: $(helm version --short 2>/dev/null)"
else
  log "installing Helm 3"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

log "verify: $(kubectl version --client 2>/dev/null | head -1) | $(helm version --short 2>/dev/null)"
