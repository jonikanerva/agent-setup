#!/usr/bin/env bash
# Validate the checked-in static Claude and Codex distributions.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

command -v python3 >/dev/null || {
  echo "check failed: Python 3.11 or newer is required" >&2
  exit 1
}

python3 "$SCRIPT_DIR/check-static.py"
git diff --check
echo "Static Claude and Codex setup checks passed."
