#!/usr/bin/env bash
# Create GitHub repos and push local content. Run from Wisdom folder.
# Prerequisite: gh auth login (run once in Git Bash)

set -e
GH="${GH:-gh}"   # use "gh" if in PATH, or set GH="/c/Program Files/GitHub CLI/gh.exe" for Git Bash
ORG="${GITHUB_ORG:-Wisdom-PA}"
BASE="${1:-.}"   # base dir containing cube, app, contracts, backend

echo "Using gh: $GH"
echo "Org: $ORG"
echo "Base: $BASE"
$GH auth status

for repo in cube app contracts backend listener scripts; do
  echo "--- Creating $ORG/$repo and pushing ---"
  $GH repo create "$ORG/$repo" --public --source="$BASE/$repo" --remote=origin --push --description "Listener project: $repo"
done

echo "Done. All repos in this list were created and pushed."
