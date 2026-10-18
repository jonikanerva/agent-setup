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
#   bin/copy-project.sh --force                # also overwrite uncommitted changes

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

# Do not overwrite uncommitted work in a destination without --force.
# Untracked files are not checked: an earlier, uncommitted copy is untracked.
if [ "$FORCE" -eq 0 ]; then
  dirty="$(git -C "$TARGET" status --porcelain --untracked-files=no -- "${DESTS[@]}")"
  if [ -n "$dirty" ]; then
    echo "error: uncommitted changes in copied paths; commit them or use --force:" >&2
    echo "$dirty" >&2
    exit 1
  fi
fi

copied=0
unchanged=0

# Create a directory inside the target. Check every component before mkdir:
# a symlinked component, for example .claude -> ~/.claude, can lead outside
# the project. Refuse it instead of writing through it.
safe_dir() {
  local relative="$1" current="$TARGET" part
  local IFS=/
  for part in $relative; do
    current="$current/$part"
    if [ -L "$current" ]; then
      echo "error: refusing to write through a symlink: ${current#"$TARGET"/}" >&2
      exit 1
    fi
    if [ -e "$current" ] && [ ! -d "$current" ]; then
      echo "error: a file exists where a directory is expected: ${current#"$TARGET"/}" >&2
      exit 1
    fi
  done
  mkdir -p "$TARGET/$relative"
}

# Copy one file. Remove a symlink first so that cp never writes through it.
copy_file() {
  local src="$1" relative="$2" dst="$TARGET/$2"
  safe_dir "$(dirname "$relative")"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -d "$dst" ]; then
    echo "error: a directory exists where a file is expected: $relative" >&2
    exit 1
  elif [ -f "$dst" ] && cmp -s "$src" "$dst"; then
    unchanged=$((unchanged + 1))
    return
  fi
  cp "$src" "$dst"
  echo "copied: $relative"
  copied=$((copied + 1))
}

i=0
while [ "$i" -lt "${#SOURCES[@]}" ]; do
  src="${SOURCES[$i]}"
  relative="${DESTS[$i]}"
  i=$((i + 1))
  if [ -f "$src" ]; then
    copy_file "$src" "$relative"
    continue
  fi
  # Copy a skill file by file. Extra files in the destination skill survive.
  # Check the parent first so that a symlink is removed only inside the target.
  safe_dir "$(dirname "$relative")"
  if [ -L "$TARGET/$relative" ]; then
    rm "$TARGET/$relative"
  elif [ -e "$TARGET/$relative" ] && [ ! -d "$TARGET/$relative" ]; then
    echo "error: a file exists where a directory is expected: $relative" >&2
    exit 1
  fi
  while IFS= read -r file; do
    copy_file "$src/$file" "$relative/$file"
  done < <(cd "$src" && find . -type f ! -name '.*' | sed 's|^\./||' | sort)
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
  if git -C "$TARGET" check-ignore -q "$dest_dir/" 2>/dev/null; then
    echo "warning: Git ignores $dest_dir; cloud checkouts do not receive it"
  fi
done

source_rev="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
if [ -n "$(git -C "$REPO_ROOT" status --porcelain -- template 2>/dev/null)" ]; then
  source_rev="$source_rev (with uncommitted template changes)"
fi

echo
echo "Done: $copied copied, $unchanged unchanged."
echo "Source: agent-setup $source_rev"
echo "Review the changes with git status and git diff, then commit them in $TARGET."
