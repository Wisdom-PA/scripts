#!/usr/bin/env sh
# Install core.hooksPath for Wisdom repos.
#
# Modes:
#   workspace (default) — siblings under Wisdom root; consumers -> ../scripts/git-hooks, scripts -> git-hooks
#   submodule — consumers -> wisdom-scripts/git-hooks (git submodule); scripts repo -> git-hooks
#
# Usage:
#   bash scripts/install-main-branch-hooks.sh
#   WISDOM_HOOKS_MODE=submodule bash scripts/install-main-branch-hooks.sh
#
# Single consumer clone (cwd = that repo root, submodule already at wisdom-scripts/):
#   WISDOM_HOOKS_MODE=submodule WISDOM_HOOKS_CURRENT_ONLY=1 bash path/to/install-main-branch-hooks.sh

set -e
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
if [ "$(basename "$script_dir")" = "wisdom-scripts" ] && [ "${WISDOM_HOOKS_CURRENT_ONLY:-0}" != "1" ]; then
  echo "This copy lives inside submodule wisdom-scripts/. Use WISDOM_HOOKS_CURRENT_ONLY=1 from the consumer root, or run scripts/install-main-branch-hooks.sh from a Wisdom workspace clone." >&2
  exit 1
fi
wisdom_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
mode=${WISDOM_HOOKS_MODE:-workspace}
repos="app backend contracts cube listener scripts"

set_hooks_path() {
  repo="$1"
  label="$2"
  rel="$3"
  (cd "$repo" && git config core.hooksPath "$rel")
  echo "core.hooksPath set for $label -> $rel"
}

if [ "${WISDOM_HOOKS_CURRENT_ONLY:-0}" = "1" ]; then
  if [ "$mode" != "submodule" ]; then
    echo "WISDOM_HOOKS_CURRENT_ONLY=1 requires WISDOM_HOOKS_MODE=submodule" >&2
    exit 1
  fi
  here=$(pwd)
  if [ ! -d "$here/.git" ]; then
    echo "Run from a git repository root (no .git here)." >&2
    exit 1
  fi
  if [ ! -d "$here/wisdom-scripts/git-hooks" ]; then
    echo "Missing wisdom-scripts/git-hooks. Add: git submodule add <scripts-url> wisdom-scripts" >&2
    exit 1
  fi
  (cd "$here" && git config core.hooksPath "wisdom-scripts/git-hooks")
  echo "core.hooksPath set for current repo -> wisdom-scripts/git-hooks"
  exit 0
fi

for name in $repos; do
  repo="$wisdom_root/$name"
  if [ ! -d "$repo/.git" ]; then
    echo "Skipping $name (no .git)" >&2
    continue
  fi
  if [ "$name" = "scripts" ]; then
    set_hooks_path "$repo" "$name" "git-hooks"
  elif [ "$mode" = "submodule" ]; then
    if [ ! -d "$repo/wisdom-scripts/git-hooks" ]; then
      echo "Skipping $name: no wisdom-scripts/git-hooks (add submodule in that repo)" >&2
      continue
    fi
    set_hooks_path "$repo" "$name" "wisdom-scripts/git-hooks"
  else
    set_hooks_path "$repo" "$name" "../scripts/git-hooks"
  fi
done

echo "Done. Mode=$mode"
