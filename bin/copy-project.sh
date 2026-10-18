#!/usr/bin/env bash
#
# copy-project.sh — copy this repo's static Claude and Codex roles and skills
# into a project repository as real files. Use it when agents cannot read
# the user-level links, for example in a cloud checkout. Commit the result.
#
# Usage:
#   bin/copy-project.sh                        # copy both hosts into the current repository
#   bin/copy-project.sh /path/to/project       # copy into another repository
#   bin/copy-project.sh --host claude          # copy Claude only
#   bin/copy-project.sh --force                # also overwrite files Git cannot restore

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

HOST="all"
FORCE=0
TARGET=""

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --host)
      [ "$#" -ge 2 ] || { echo "error: --host requires claude, codex, or all" >&2; exit 2; }
      HOST="$2"
      shift 2
      ;;
    --force)
      FORCE=1
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
      [ -z "$TARGET" ] || { echo "error: only one project directory is allowed" >&2; exit 2; }
      TARGET="$1"
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

# The target must be the top level of a Git work tree. Copied files are then
# visible in git status, and the owner reviews and commits them.
if [ -z "$TARGET" ]; then
  TARGET="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "error: the current directory is not in a Git repository; give a project directory" >&2
    exit 2
  }
fi
[ -d "$TARGET" ] || { echo "error: project directory does not exist: $TARGET" >&2; exit 2; }
TARGET="$(cd -P "$TARGET" && pwd -P)"
toplevel="$(git -C "$TARGET" rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error: not a Git repository: $TARGET" >&2
  exit 2
}
toplevel="$(cd -P "$toplevel" && pwd -P)"
[ "$toplevel" = "$TARGET" ] || {
  echo "error: give the repository top level ($toplevel), not a subdirectory" >&2
  exit 2
}
[ "$TARGET" != "$REPO_ROOT" ] || {
  echo "error: the target is the agent-setup repository itself" >&2
  exit 2
}

# Collect source -> destination pairs. The set is the same set that
# link-global.sh links: roles as files and skills as directories.
SOURCES=()
DESTS=()
DEST_DIRS=()

add_entries() {
  local src_dir="$1" pattern="$2" dest_dir="$3" kind="$4" entry
  DEST_DIRS+=("$dest_dir")
  for entry in "$src_dir"/$pattern; do
    if [ "$kind" = file ]; then
      [ -f "$entry" ] || continue
    else
      [ -d "$entry" ] || continue
      entry="${entry%/}"
    fi
    SOURCES+=("$entry")
    DESTS+=("$dest_dir/$(basename "$entry")")
  done
}

if [ "$HOST" = claude ] || [ "$HOST" = all ]; then
  add_entries "$REPO_ROOT/template/.claude/agents" "*.md" ".claude/agents" file
  add_entries "$REPO_ROOT/template/.claude/skills" "*/" ".claude/skills" dir
fi
if [ "$HOST" = codex ] || [ "$HOST" = all ]; then
  add_entries "$REPO_ROOT/template/.codex/agents" "*.toml" ".codex/agents" file
  add_entries "$REPO_ROOT/template/.agents/skills" "*/" ".agents/skills" dir
fi

# Expand skills into files. ENTRIES holds the role file or skill directory
# that owns each file. A symlink at that entry path is replaced.
FILE_SRCS=()
FILE_DSTS=()
ENTRIES=()
i=0
while [ "$i" -lt "${#SOURCES[@]}" ]; do
  src="${SOURCES[$i]}"
  relative="${DESTS[$i]}"
  i=$((i + 1))
  if [ -f "$src" ]; then
    FILE_SRCS+=("$src")
    FILE_DSTS+=("$relative")
    ENTRIES+=("$relative")
    continue
  fi
  while IFS= read -r file; do
    FILE_SRCS+=("$src/$file")
    FILE_DSTS+=("$relative/$file")
    ENTRIES+=("$relative")
  done < <(cd "$src" && find . -type f ! -name '.*' | sed 's|^\./||' | sort)
done

# Check every destination before the first write. A symlinked directory, for
# example .claude -> ~/.claude, can lead outside the project; refuse it.
# Only the owning entry or the file itself can be a symlink; it is replaced.
check_path() {
  local relative="$1" entry="$2" current="$TARGET" part
  local IFS=/
  for part in $relative; do
    current="$current/$part"
    if [ -L "$current" ]; then
      [ "$current" = "$TARGET/$entry" ] || [ "$current" = "$TARGET/$relative" ] && return 0
      echo "error: refusing to write through a symlink: ${current#"$TARGET"/}" >&2
      exit 1
    fi
    if [ "$current" = "$TARGET/$relative" ]; then
      if [ -d "$current" ]; then
        echo "error: a directory exists where a file is expected: $relative" >&2
        exit 1
      fi
    elif [ -e "$current" ] && [ ! -d "$current" ]; then
      echo "error: a file exists where a directory is expected: ${current#"$TARGET"/}" >&2
      exit 1
    fi
  done
}

# Do not overwrite content that Git cannot restore without --force: a file
# with uncommitted changes, or an untracked or ignored file. If git status
# fails, stop: an unknown state must not allow an overwrite.
blocked=()
i=0
while [ "$i" -lt "${#FILE_DSTS[@]}" ]; do
  relative="${FILE_DSTS[$i]}"
  check_path "$relative" "${ENTRIES[$i]}"
  dst="$TARGET/$relative"
  i=$((i + 1))
  # A symlink is replaced, and its target does not change.
  [ ! -L "$TARGET/${ENTRIES[$((i - 1))]}" ] && [ ! -L "$dst" ] && [ -f "$dst" ] || continue
  cmp -s "${FILE_SRCS[$((i - 1))]}" "$dst" && continue
  state="$(git -C "$TARGET" status --porcelain --ignored --untracked-files=all -- "$relative")" || {
    echo "error: git status failed in $TARGET; no files were changed" >&2
    exit 1
  }
  [ -z "$state" ] || blocked+=("$relative")
done
if [ "${#blocked[@]}" -gt 0 ] && [ "$FORCE" -eq 0 ]; then
  echo "error: Git cannot restore these files (uncommitted, untracked, or ignored)." >&2
  echo "Commit them, or use --force to overwrite them:" >&2
  printf '  %s\n' "${blocked[@]}" >&2
  exit 1
fi

copied=0
unchanged=0
i=0
while [ "$i" -lt "${#FILE_DSTS[@]}" ]; do
  src="${FILE_SRCS[$i]}"
  relative="${FILE_DSTS[$i]}"
  entry="$TARGET/${ENTRIES[$i]}"
  dst="$TARGET/$relative"
  i=$((i + 1))
  # Remove a symlink first so that cp never writes through it.
  [ -L "$entry" ] && rm "$entry"
  [ -L "$dst" ] && rm "$dst"
  mkdir -p "$(dirname "$dst")"
  if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
    unchanged=$((unchanged + 1))
    continue
  fi
  cp "$src" "$dst"
  echo "copied: $relative"
  copied=$((copied + 1))
done

# Report entries that this copy does not own. The script never deletes them.
for dest_dir in "${DEST_DIRS[@]}"; do
  [ -d "$TARGET/$dest_dir" ] || continue
  for entry in "$TARGET/$dest_dir"/*; do
    [ -e "$entry" ] || [ -L "$entry" ] || continue
    relative="$dest_dir/$(basename "$entry")"
    owned=0
    for dest in "${DESTS[@]}"; do
      [ "$dest" = "$relative" ] && owned=1 && break
    done
    [ "$owned" -eq 1 ] || echo "kept (not from agent-setup): $relative"
  done
done

# Warn about ignored copies. Cloud checkouts do not receive ignored files.
# check-ignore exits 0 when it finds ignored paths, 1 when it finds none.
status=0
ignored="$(git -C "$TARGET" check-ignore -- "${FILE_DSTS[@]}")" || status=$?
if [ "$status" -eq 0 ]; then
  echo "warning: Git ignores these copied files; cloud checkouts do not receive them:"
  printf '%s\n' "$ignored" | sed 's/^/  /'
elif [ "$status" -ne 1 ]; then
  echo "warning: git check-ignore failed; check ignored files yourself"
fi

source_rev="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
if [ -n "$(git -C "$REPO_ROOT" status --porcelain -- template 2>/dev/null)" ]; then
  source_rev="$source_rev (with uncommitted template changes)"
fi

echo
echo "Done: $copied copied, $unchanged unchanged."
echo "Source: agent-setup $source_rev"
echo "Review the changes with git status and git diff, then commit them in $TARGET."
