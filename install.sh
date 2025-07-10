#!/usr/bin/env bash
#
# install.sh — one-liner dispatcher for cognis-setup-scripts.
#
# Usage:
#   ./install.sh <tool> [<tool> ...]
#   curl -fsSL https://raw.githubusercontent.com/cognis-digital/cognis-setup-scripts/main/install.sh | bash -s -- docker node
#
# Each <tool> maps to scripts/<tool>.sh. When run via curl|bash, the script
# clones the repo to a temp dir if the scripts/ directory is not local.
#
set -euo pipefail

REPO_URL="${COGNIS_REPO_URL:-https://github.com/cognis-digital/cognis-setup-scripts.git}"
REPO_BRANCH="${COGNIS_REPO_BRANCH:-main}"

log()  { printf '\033[1;34m[install]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[install]\033[0m %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

# Resolve the directory containing this script if we are running from a clone.
SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
SCRIPTS_DIR=""
if [[ -n "$SCRIPT_SOURCE" && -f "$SCRIPT_SOURCE" ]]; then
  THIS_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
  if [[ -d "$THIS_DIR/scripts" ]]; then
    SCRIPTS_DIR="$THIS_DIR/scripts"
  fi
fi

# If we could not find a local scripts/ dir (piped from curl), clone the repo.
CLEANUP_DIR=""
if [[ -z "$SCRIPTS_DIR" ]]; then
  command -v git >/dev/null 2>&1 || die "git is required to bootstrap from a remote install"
  CLEANUP_DIR="$(mktemp -d)"
  log "Cloning $REPO_URL ($REPO_BRANCH) into $CLEANUP_DIR"
  git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$CLEANUP_DIR" >/dev/null
  SCRIPTS_DIR="$CLEANUP_DIR/scripts"
fi

cleanup() { [[ -n "$CLEANUP_DIR" && -d "$CLEANUP_DIR" ]] && rm -rf "$CLEANUP_DIR"; }
trap cleanup EXIT

usage() {
  cat <<EOF
Usage: install.sh <tool> [<tool> ...]

Available tools:
EOF
  for f in "$SCRIPTS_DIR"/*.sh; do
    [[ -e "$f" ]] || continue
    printf '  - %s\n' "$(basename "$f" .sh)"
  done
}

[[ $# -ge 1 ]] || { usage; die "no tool specified"; }

if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" || "$1" == "list" ]]; then
  usage
  exit 0
fi

# Validate everything up front so we fail fast before installing anything.
for tool in "$@"; do
  script="$SCRIPTS_DIR/$tool.sh"
  [[ -f "$script" ]] || { err "unknown tool: $tool"; usage; exit 1; }
done

for tool in "$@"; do
  script="$SCRIPTS_DIR/$tool.sh"
  log "Running $tool ..."
  bash "$script"
  log "Done: $tool"
done

log "All requested tools installed."
