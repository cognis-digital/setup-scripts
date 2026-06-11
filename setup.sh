#!/usr/bin/env sh
# setup.sh — launch the Cognis guided setup wizard.
#
#   ./setup.sh           # interactive guided wizard (type a number)
#   ./setup.sh --dry-run # preview every command, never run it
#
# Pure stdlib Python — nothing to install first. Any python3 (3.8+) works.
# All extra arguments are passed straight through to cognis_setup.py.
set -eu

# Resolve the directory this script lives in (so it works from anywhere).
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
WIZARD="$SCRIPT_DIR/cognis_setup.py"

if [ ! -f "$WIZARD" ]; then
  echo "error: cannot find cognis_setup.py next to setup.sh ($WIZARD)" >&2
  exit 1
fi

# Find a Python interpreter that actually runs. We probe with --version rather
# than just command -v, because on Windows the Microsoft Store "python3" shim
# sits on PATH but only prints an install prompt and exits non-zero.
PY=""
for cand in python3 python py; do
  if command -v "$cand" >/dev/null 2>&1 && "$cand" --version >/dev/null 2>&1; then
    PY="$cand"
    break
  fi
done

if [ -z "$PY" ]; then
  echo "error: no Python interpreter found (need python3 3.8+)." >&2
  echo "       Install Python, then re-run: ./setup.sh" >&2
  exit 1
fi

exec "$PY" "$WIZARD" "$@"
