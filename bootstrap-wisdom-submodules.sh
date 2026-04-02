#!/usr/bin/env sh
# Add wisdom-scripts submodule to each consumer under the Wisdom root.
# Run after the scripts repo exists on GitHub.
#
# Usage: bash scripts/bootstrap-wisdom-submodules.sh [scripts-repo-url]
set -e
wisdom_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
url=${1:-https://github.com/Wisdom-PA/scripts.git}
for name in app backend contracts cube listener; do
  repo="$wisdom_root/$name"
  if [ ! -d "$repo/.git" ]; then
    echo "Skipping $name (no .git)" >&2
    continue
  fi
  if [ -e "$repo/wisdom-scripts" ]; then
    echo "$name: wisdom-scripts exists — skip"
    continue
  fi
  (cd "$repo" && git submodule add -b main "$url" wisdom-scripts && git submodule update --init --depth 1 wisdom-scripts)
  echo "$name: submodule added"
done
echo "Done. Commit .gitmodules on a feature branch in each repo."
