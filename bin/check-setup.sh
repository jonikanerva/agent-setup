#!/usr/bin/env bash
# Validate the checked-in static Claude and Codex distributions.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

roles=(architect devils-advocate implementer product-guardian reviewer)
skills=(lead implement codereview)
commands=(FORMAT_CMD LINT_CMD BUILD_CMD TEST_CMD VERIFY_CMD MUTATION_CMD)

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
require_file template/docs/adr/TEMPLATE.md
require_file template/.github/pull_request_template.md
require_file template/.claude/settings.json
jq -e . template/.claude/settings.json >/dev/null \
  || fail "template/.claude/settings.json is not valid JSON"

# Both hosts ship exactly the same role and skill sets.
[ "$(ls template/.claude/agents | sed 's/\.md$//' | sort)" = "$(printf '%s\n' "${roles[@]}" | sort)" ] \
  || fail "Claude roles differ from: ${roles[*]}"
[ "$(ls template/.codex/agents | sed 's/\.toml$//' | sort)" = "$(printf '%s\n' "${roles[@]}" | sort)" ] \
  || fail "Codex roles differ from: ${roles[*]}"
[ "$(ls template/.claude/skills | sort)" = "$(printf '%s\n' "${skills[@]}" | sort)" ] \
  || fail "Claude skills differ from: ${skills[*]}"
[ "$(ls template/.agents/skills | sort)" = "$(printf '%s\n' "${skills[@]}" | sort)" ] \
  || fail "Codex skills differ from: ${skills[*]}"

for role in "${roles[@]}"; do
  file="template/.claude/agents/$role.md"
  grep -q "^name: $role$" "$file" || fail "Claude agent name mismatch: $file"
  grep -q '^description: ' "$file" || fail "missing description in $file"

  file="template/.codex/agents/$role.toml"
  expected_name="${role//-/_}"
  grep -q "^name = \"$expected_name\"$" "$file" || fail "Codex agent name mismatch: $file"
  grep -q '^description = ' "$file" || fail "missing description in $file"
  grep -q '^developer_instructions = ' "$file" || fail "missing developer_instructions in $file"
  grep -q 'read VISION.md, AGENTS.md, and STACK.md' "$file" \
    || fail "Codex agent does not read the contract first: $file"
done

for skill in "${skills[@]}"; do
  for host in .claude .agents; do
    file="template/$host/skills/$skill/SKILL.md"
    require_file "$file"
    grep -q "^name: $skill$" "$file" || fail "skill name mismatch: $file"
    grep -q '^description: ' "$file" || fail "skill description missing: $file"
  done
done

# Host trees use host-native names only.
if grep -rnE 'CLAUDE\.md|subagent_type|AskUserQuestion|(^|[^$[:alnum:]_])/(lead|implement|codereview)\b' \
  template/AGENTS.md template/.codex template/.agents; then
  fail "Codex tree references Claude-only names"
fi
if grep -rnE 'AGENTS\.md|\$(lead|implement|codereview)\b' template/CLAUDE.md template/.claude; then
  fail "Claude tree references Codex-only names"
fi

# Removed concepts must not come back.
if grep -rnE 'Intentional Divergence|project-manager|lead-dev|qa-enforcer|ux-guardian|lead_dev|qa_enforcer|ux_guardian' \
  template stacks; then
  fail "template or stacks reference a removed concept"
fi

# Every stack profile defines all six commands.
for stack in stacks/STACK-*.md; do
  for cmd in "${commands[@]}"; do
    grep -q "^| \`\\\$$cmd\`" "$stack" || fail "$stack does not define \$$cmd"
  done
  grep -q '^### Gates in `\$VERIFY_CMD`' "$stack" || fail "$stack has no Gates section"
  grep -q '^## 10\. Base units & time' "$stack" || fail "$stack has no Base units & time section"
done

git diff --check
echo "Static Claude and Codex setup checks passed."
