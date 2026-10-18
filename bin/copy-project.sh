#!/usr/bin/env bash
#
# copy-project.sh — copy this repo's static Claude and Codex roles and skills
# into a project directory as real files. Use it when agents cannot read the
# user-level links, for example in a cloud checkout. Commit the result.
#
# Usage:
#   bin/copy-project.sh                        # copy both hosts into the current directory
#   bin/copy-project.sh /path/to/project       # copy into another directory
#   bin/copy-project.sh --host claude          # copy Claude only
#   bin/copy-project.sh --yes                  # do not ask for confirmation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

HOST="all"
YES=0
TARGET="."
target_set=0

usage() {
  sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --host)
      [ "$#" -ge 2 ] || { echo "error: --host requires claude, codex, or all" >&2; exit 2; }
      HOST="$2"
      shift 2
      ;;
    -y|--yes)
      YES=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      [ "$target_set" -eq 0 ] || { echo "error: only one project directory is allowed" >&2; exit 2; }
      TARGET="$1"
      target_set=1
      shift
      ;;
  esac
done

case "$HOST" in
  claude|codex|all) ;;
  *)
    echo "error: --host must be claude, codex, or all" >&2
    exit 2
    ;;
esac

[ -d "$TARGET" ] || { echo "error: project directory does not exist: $TARGET" >&2; exit 2; }
TARGET="$(cd -P "$TARGET" && pwd -P)"
[ "$TARGET" != "$REPO_ROOT" ] || { echo "error: the target is the agent-setup repository itself" >&2; exit 2; }

# Collect source -> destination file pairs. The set is the same set that
# link-global.sh links: role files and the files in each skill directory.
# ENTRIES holds the role file or skill directory that owns each file.
SRCS=()
DSTS=()
ENTRIES=()

add_files() {
  local src_dir="$1" pattern="$2" dest_dir="$3" entry name file
  for entry in "$src_dir"/$pattern; do
    entry="${entry%/}"
    name="$dest_dir/$(basename "$entry")"
    if [ -f "$entry" ]; then
      SRCS+=("$entry")
      DSTS+=("$name")
      ENTRIES+=("$name")
    elif [ -d "$entry" ]; then
      while IFS= read -r file; do
        SRCS+=("$entry/$file")
        DSTS+=("$name/$file")
        ENTRIES+=("$name")
      done < <(cd "$entry" && find . -type f ! -name '.*' | sed 's|^\./||' | sort)
    fi
  done
}

if [ "$HOST" = claude ] || [ "$HOST" = all ]; then
  add_files "$REPO_ROOT/template/.claude/agents" "*.md" ".claude/agents"
  add_files "$REPO_ROOT/template/.claude/skills" "*/" ".claude/skills"
fi
if [ "$HOST" = codex ] || [ "$HOST" = all ]; then
  add_files "$REPO_ROOT/template/.codex/agents" "*.toml" ".codex/agents"
  add_files "$REPO_ROOT/template/.agents/skills" "*/" ".agents/skills"
fi

# Show what will change. A symlink is replaced with a real file, so its
# target does not change. Files with the same content are not copied.
CHANGED=()
i=0
while [ "$i" -lt "${#DSTS[@]}" ]; do
  dst="$TARGET/${DSTS[$i]}"
  if [ -L "$TARGET/${ENTRIES[$i]}" ] || [ -L "$dst" ] || [ ! -e "$dst" ]; then
    echo "new:       ${DSTS[$i]}"
    CHANGED+=("$i")
  elif ! cmp -s "${SRCS[$i]}" "$dst"; then
    echo "overwrite: ${DSTS[$i]}"
    CHANGED+=("$i")
  fi
  i=$((i + 1))
done

unchanged=$(( ${#DSTS[@]} - ${#CHANGED[@]} ))
if [ "${#CHANGED[@]}" -eq 0 ]; then
  echo "Nothing to copy: $unchanged files are up to date in $TARGET."
  exit 0
fi

echo
echo "This copies ${#CHANGED[@]} files into $TARGET ($unchanged up to date)."
echo "An overwritten file loses its local content."
if [ "$YES" -eq 0 ]; then
  printf 'Continue? [y/N] '
  read -r answer || answer=""
  case "$answer" in
    y|Y|yes|YES) ;;
    *) echo "Cancelled. No files were changed."; exit 1 ;;
  esac
fi

for i in "${CHANGED[@]}"; do
  entry="$TARGET/${ENTRIES[$i]}"
  dst="$TARGET/${DSTS[$i]}"
  # Remove a symlink first so that cp never writes through it.
  [ ! -L "$entry" ] || rm "$entry"
  [ ! -L "$dst" ] || rm "$dst"
  mkdir -p "$(dirname "$dst")"
  cp "${SRCS[$i]}" "$dst"
done

source_rev="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "Done: ${#CHANGED[@]} files copied from agent-setup $source_rev."
echo "Review the changes and commit them in the project."
