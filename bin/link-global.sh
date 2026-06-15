#!/usr/bin/env bash
#
# link-global.sh — symlink this repo's agents & skills into ~/.claude so they
# are active in every Claude Code session, with the repo staying the single
# source of truth.
#
# The symlink target IS the repo file, so edits and `git pull` take effect
# immediately — no copy step. Re-run this script only when you ADD a new agent
# or skill (it creates the missing links), or pass --prune to clean up links
# whose source was removed from the repo.
#
# Usage:
#   bin/link-global.sh            # create/refresh symlinks
#   bin/link-global.sh --prune    # the above, plus remove dead repo links

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$REPO_ROOT/template/.claude"
DEST="$HOME/.claude"

PRUNE=0
[ "${1:-}" = "--prune" ] && PRUNE=1

linked=0
skipped=0
pruned=0

# Create a symlink dst -> src, but never clobber a real (non-symlink) file/dir.
link_one() {
  local src="$1" dst="$2"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "skip (real file/dir exists, not a symlink): $dst"
    skipped=$((skipped + 1))
    return
  fi
  ln -sfn "$src" "$dst"   # -f overwrites an existing symlink, -n avoids following a dir symlink
  echo "linked: $dst -> $src"
  linked=$((linked + 1))
}

# Remove symlinks under a dir that point into the repo but whose source is gone.
prune_dir() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  local entry target
  for entry in "$dir"/*; do
    [ -L "$entry" ] || continue
    target="$(readlink "$entry")"
    case "$target" in
      "$REPO_ROOT"/*)
        if [ ! -e "$target" ]; then
          rm "$entry"
          echo "pruned dead link: $entry"
          pruned=$((pruned + 1))
        fi
        ;;
    esac
  done
}

mkdir -p "$DEST/agents" "$DEST/skills"

# Agents: each *.md file -> ~/.claude/agents/<name>.md
for f in "$SRC"/agents/*.md; do
  [ -e "$f" ] || continue
  link_one "$f" "$DEST/agents/$(basename "$f")"
done

# Skills: each skill dir -> ~/.claude/skills/<name> (whole dir, incl. references/)
for d in "$SRC"/skills/*/; do
  [ -d "$d" ] || continue
  link_one "${d%/}" "$DEST/skills/$(basename "$d")"
done

if [ "$PRUNE" -eq 1 ]; then
  prune_dir "$DEST/agents"
  prune_dir "$DEST/skills"
fi

echo
echo "Done: $linked linked, $skipped skipped${PRUNE:+, $pruned pruned}."
echo "Edits in $SRC and 'git pull' are live immediately. Re-run after adding a new agent/skill."
