#!/usr/bin/env bash
# Validate the checked-in static Claude and Codex distributions.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

roles=(architect devils-advocate lead-dev qa-enforcer ux-guardian)
codex_roles=(architect devils-advocate lead-dev qa-enforcer ux-guardian)
skills=(project-manager implement codereview)

fail() {
  echo "check failed: $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "missing file: $1"
}

require_dir() {
  [ -d "$1" ] || fail "missing directory: $1"
}

bash -n bin/link-global.sh

require_file template/CLAUDE.md
require_file template/AGENTS.md
require_file template/VISION.md
require_file template/.claude/settings.json

for role in "${roles[@]}"; do
  require_file "template/.claude/agents/$role.md"
done

for role in "${codex_roles[@]}"; do
  file="template/.codex/agents/$role.toml"
  expected_name="${role//-/_}"
  require_file "$file"
  grep -q "^name = \"$expected_name\"$" "$file" || fail "Codex agent name mismatch: $file"
  grep -q '^description = ' "$file" || fail "missing description in $file"
  grep -q '^developer_instructions = ' "$file" || fail "missing developer_instructions in $file"
done

for skill in "${skills[@]}"; do
  claude="template/.claude/skills/$skill"
  codex="template/.agents/skills/$skill"
  require_dir "$claude"
  require_dir "$codex"
  require_file "$claude/SKILL.md"
  require_file "$codex/SKILL.md"
  grep -q "^name: $skill$" "$codex/SKILL.md" || fail "Codex skill name mismatch: $skill"
  grep -q '^description: ' "$codex/SKILL.md" || fail "Codex skill description missing: $skill"
done

git diff --check
echo "Static Claude and Codex setup checks passed."
