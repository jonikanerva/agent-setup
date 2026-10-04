#!/usr/bin/env bash
#
# link-global.sh — symlink this repo's static Claude and Codex roles and skills
# into the user-level discovery locations. The repository remains the single
# source of truth for these global files.
#
# Usage:
#   bin/link-global.sh                         # link both hosts
#   bin/link-global.sh --host claude           # link Claude only
#   bin/link-global.sh --host codex            # link Codex only
#   bin/link-global.sh --host all --prune       # also remove dead repo links

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST_HOME="${AGENT_SETUP_HOME:-$HOME}"

HOST="all"
PRUNE=0

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
    --prune)
      PRUNE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
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
  ln -sfn "$src" "$dst"
  echo "linked: $dst -> $src"
  linked=$((linked + 1))
}

# Remove symlinks under a directory when they point into this repo and their
# source no longer exists. Real files and links owned by other setups survive.
prune_dir() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  local entry target target_parent
  for entry in "$dir"/*; do
    [ -L "$entry" ] || continue
    target="$(readlink "$entry")"
    case "$target" in
      "$REPO_ROOT"/*)
        # A string prefix does not prove ownership: ../ or a symlinked parent
        # can leave this repository. If the parent cannot be resolved, keep
        # the link. Pruning must prefer a stale link over unrelated deletion.
        target_parent="$(cd -P "$(dirname "$target")" 2>/dev/null && pwd -P)" || continue
        case "$target_parent/" in
          "$REPO_ROOT/"*) ;;
          *) continue ;;
        esac
        if [ ! -e "$target" ]; then
          rm "$entry"
          echo "pruned dead link: $entry"
          pruned=$((pruned + 1))
        fi
        ;;
    esac
  done
}

link_claude() {
  local src="$REPO_ROOT/template/.claude"
  local dest="$DEST_HOME/.claude"

  mkdir -p "$dest/agents" "$dest/skills"

  local file dir
  for file in "$src"/agents/*.md; do
    [ -e "$file" ] || continue
    link_one "$file" "$dest/agents/$(basename "$file")"
  done

  for dir in "$src"/skills/*/; do
    [ -d "$dir" ] || continue
    link_one "${dir%/}" "$dest/skills/$(basename "$dir")"
  done

  if [ "$PRUNE" -eq 1 ]; then
    prune_dir "$dest/agents"
    prune_dir "$dest/skills"
  fi
}

link_codex() {
  local agent_src="$REPO_ROOT/template/.codex/agents"
  local skill_src="$REPO_ROOT/template/.agents/skills"
  local codex_dest="$DEST_HOME/.codex"
  local skill_dest="$DEST_HOME/.agents/skills"

  mkdir -p "$codex_dest/agents" "$skill_dest"
  local file dir
  for file in "$agent_src"/*.toml; do
    [ -e "$file" ] || continue
    link_one "$file" "$codex_dest/agents/$(basename "$file")"
  done

  for dir in "$skill_src"/*/; do
    [ -d "$dir" ] || continue
    link_one "${dir%/}" "$skill_dest/$(basename "$dir")"
  done

  if [ "$PRUNE" -eq 1 ]; then
    prune_dir "$codex_dest/agents"
    prune_dir "$skill_dest"
  fi
}

case "$HOST" in
  claude) link_claude ;;
  codex) link_codex ;;
  all)
    link_claude
    link_codex
    ;;
esac

echo
echo "Done: $linked linked, $skipped skipped, $pruned pruned."
echo "Static role and skill changes are live for new $HOST sessions. Re-run only after adding or removing entries."
