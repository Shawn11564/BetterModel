#!/usr/bin/env bash
# Usage: check-dungeons-base.sh <tag> <our commit> <upstream v3 commit>
# Passes when <tag> is <release>-dungeons.<n>, <release> is an upstream release tag, and our commit
# is built on exactly that release: it contains the release, and none of upstream's later
# (unreleased) v3 commits. Used by dungeons-release.yml; run it locally before tagging:
#   git fetch upstream --tags && .github/check-dungeons-base.sh 3.7.1-dungeons.2 HEAD upstream/v3
set -euo pipefail
tag=$1 ours=$2 upstream=$3

release=${tag%-dungeons.*}
if [[ "$release" == "$tag" || ! "${tag#"$release"-dungeons.}" =~ ^[0-9]+$ ]]; then
  echo "::error::Tag '$tag' must be <upstream release>-dungeons.<n>, e.g. 3.7.1-dungeons.2." >&2
  exit 1
fi
if ! release_commit=$(git rev-parse --verify --quiet "refs/tags/$release^{commit}"); then
  echo "::error::'$release' isn't an upstream release tag (git fetch upstream --tags)." >&2
  exit 1
fi
if ! git merge-base --is-ancestor "$release_commit" "$ours"; then
  echo "::error::The branch isn't built on release $release (git rebase --onto $release <old base> dungeons)." >&2
  exit 1
fi
base=$(git merge-base "$ours" "$upstream")
if [[ "$base" != "$release_commit" ]]; then
  echo "::error::The branch contains upstream commits after release $release (it's on $(git rev-parse --short "$base")). We only build on official releases." >&2
  exit 1
fi
echo "ok: $tag is built on upstream release $release ($(git rev-parse --short "$release_commit"))"
