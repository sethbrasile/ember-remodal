#!/usr/bin/env bash
# Checks that a packed ember-remodal holds exactly the files listed in
# scripts/pack-contents.txt, then prints the hashes npm records for it.
#
#   scripts/verify-pack.sh ember-remodal-2.18.1.tgz
set -euo pipefail

TARBALL="${1:?usage: scripts/verify-pack.sh <tarball>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! diff <(LC_ALL=C sort "$ROOT/scripts/pack-contents.txt") <(tar -tzf "$TARBALL" | LC_ALL=C sort); then
  echo "$TARBALL does not hold the expected files. Lines marked > are extra, < are missing." >&2
  exit 1
fi

echo "$(basename "$TARBALL"): $(tar -tzf "$TARBALL" | wc -l | tr -d ' ') files, as listed in scripts/pack-contents.txt"
echo "integrity: sha512-$(openssl dgst -sha512 -binary "$TARBALL" | openssl base64 -A)"
echo "shasum:    $(openssl dgst -sha1 "$TARBALL" | awk '{ print $NF }')"
