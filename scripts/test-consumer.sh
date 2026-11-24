#!/usr/bin/env bash
# Tests a packed ember-remodal the way an app gets it: copies a fixture app to
# a clean directory, installs the tarball there, and runs the app's acceptance
# tests in headless Chrome.
#
#   scripts/test-consumer.sh floor ember-remodal-2.18.1.tgz
#   scripts/test-consumer.sh 2.18  ember-remodal-2.18.1.tgz
#   scripts/test-consumer.sh 3.28  ember-remodal-2.18.1.tgz
#
#   floor  Ember CLI 2.18.2 app running the Ember 2.3.2 runtime, its template
#          compiler and jQuery 2.2.4
#   2.18   the same app untouched: Ember 2.18.2 and jQuery 3.3.1
#   3.28   Ember CLI 3.28.6 app: Ember 3.28.12, @ember/jquery with jQuery 3.8.0
#          and the jquery-integration optional feature
#
# Needs yarn 1, curl and Chrome. CI runs floor and 2.18 on Node 8.17.0 and 3.28
# on Node 24.21.0. The app is built in a temp directory, or in $CONSUMER_DIR if set.
# Set $TEST_PORT to run two of these at once.
#
# The fixture apps do not list ember-wormhole or remodal. The tarball has to
# bring them.
set -euo pipefail

USAGE="usage: scripts/test-consumer.sh <floor|2.18|3.28> <tarball>"
CONSUMER="${1:?$USAGE}"
TARBALL_ARG="${2:?$USAGE}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARBALL="$(cd "$(dirname "$TARBALL_ARG")" && pwd)/$(basename "$TARBALL_ARG")"
PORT="${TEST_PORT:-7357}"

# FIXTURE is the app to copy. CLI and SOURCE are the versions its lockfile pins
# in node_modules. EMBER and JQUERY are what the browser must report.
case "$CONSUMER" in
  floor)
    FIXTURE=classic; CLI=2.18.2; SOURCE=2.18.2; EMBER=2.3.2; JQUERY=2.2.4
    INSTALL_FLAGS=(--ignore-engines --ignore-optional --non-interactive) ;;
  2.18)
    FIXTURE=classic; CLI=2.18.2; SOURCE=2.18.2; EMBER=2.18.2; JQUERY=3.3.1
    INSTALL_FLAGS=(--ignore-engines --ignore-optional --non-interactive) ;;
  3.28)
    FIXTURE=ember-3.28; CLI=3.28.6; SOURCE=3.28.12; EMBER=3.28.12; JQUERY=3.8.0
    INSTALL_FLAGS=(--non-interactive) ;;
  *)
    echo "$USAGE" >&2; exit 2 ;;
esac

# Ember 2.3.2 is not on npm (ember-source starts at 2.11), so the floor takes
# the builds published to this repository at tag 2.3.2.
EMBER_FLOOR_COMMIT=98e3bff9dbbbb7907b8e5ada7483ba0c16c18481
EMBER_FLOOR_URL="https://raw.githubusercontent.com/components/ember/$EMBER_FLOOR_COMMIT"
EMBER_FLOOR_FILES=(ember.debug.js ember.prod.js ember.min.js ember-runtime.js ember-template-compiler.js ember-testing.js)
JQUERY_FLOOR_URL=https://registry.npmjs.org/jquery/-/jquery-2.2.4.tgz

check_sha256() {
  if command -v sha256sum > /dev/null; then sha256sum -c "$1"; else shasum -a 256 -c "$1"; fi
}

integrity() {
  echo "sha512-$(openssl dgst -sha512 -binary "$1" | openssl base64 -A)"
}

# A module that fails to load can leave the test run waiting forever.
limit() { if command -v timeout > /dev/null; then timeout 600 "$@"; else "$@"; fi; }

# Replaces the installed Ember and jQuery builds with the floor versions. Both
# package.json files keep reporting what yarn installed, so the versions the
# browser reports in the acceptance test are the proof of what ran.
swap_floor_runtime() {
  local downloads="$WORK/floor-runtime" file jquery_dir
  rm -rf "$downloads"
  mkdir -p "$downloads"
  for file in "${EMBER_FLOOR_FILES[@]}"; do
    curl -fsSL --retry 3 -o "$downloads/$file" "$EMBER_FLOOR_URL/$file"
  done
  curl -fsSL --retry 3 -o "$downloads/jquery-2.2.4.tgz" "$JQUERY_FLOOR_URL"
  (cd "$downloads" && check_sha256 "$ROOT/scripts/consumers/floor-runtime.sha256")

  for file in "${EMBER_FLOOR_FILES[@]}"; do
    cp "$downloads/$file" "node_modules/ember-source/dist/$file"
  done

  # ember-source takes jquery.js from the copy of jquery the app resolves.
  jquery_dir="$(node -p "require('path').dirname(require.resolve('jquery/package.json'))")"
  tar -xzf "$downloads/jquery-2.2.4.tgz" -C "$downloads"
  cp "$downloads/package/dist/jquery.js" "$downloads/package/dist/jquery.min.js" "$jquery_dir/dist/"
}

[ -f "$TARBALL" ] || { echo "No tarball at $TARBALL" >&2; exit 2; }
WORK="${CONSUMER_DIR:-$(mktemp -d)}"
APP="$WORK/app"
mkdir -p "$WORK"
rm -rf "$APP" "$WORK/unpacked" "$WORK/broccoli-cache"
mkdir "$WORK/unpacked"
tar -xzf "$TARBALL" -C "$WORK/unpacked"
PACKED="$(node -p "require('$WORK/unpacked/package/package.json').version")"

echo "== consumer $CONSUMER: ember-remodal $PACKED, $(integrity "$TARBALL")"
echo "== node $(node --version), yarn $(yarn --version), work directory $WORK"
cp -R "$ROOT/scripts/consumers/$FIXTURE" "$APP"
cd "$APP"

echo "== installing the app from its lockfile"
yarn install --frozen-lockfile "${INSTALL_FLAGS[@]}" > "$WORK/install.log" 2>&1 \
  || { tail -30 "$WORK/install.log"; exit 1; }

echo "== installing the tarball"
yarn add "ember-remodal@file:$TARBALL" "${INSTALL_FLAGS[@]}" > "$WORK/add.log" 2>&1 \
  || { tail -30 "$WORK/add.log"; exit 1; }
# yarn caches tarballs, so make sure the app got the code that was just packed.
diff -r -x node_modules "$WORK/unpacked/package" node_modules/ember-remodal \
  || { echo "The installed ember-remodal is not the packed one." >&2; exit 1; }

INSTALLED_CLI="$(node -p "require('ember-cli/package.json').version")"
INSTALLED_SOURCE="$(node -p "require('ember-source/package.json').version")"
if [ "$INSTALLED_CLI" != "$CLI" ] || [ "$INSTALLED_SOURCE" != "$SOURCE" ]; then
  echo "Expected ember-cli $CLI and ember-source $SOURCE, got $INSTALLED_CLI and $INSTALLED_SOURCE." >&2
  exit 1
fi

if [ "$CONSUMER" = floor ]; then
  echo "== swapping in the Ember $EMBER runtime and jQuery $JQUERY"
  swap_floor_runtime
fi

mkdir -p tests/helpers
cat > tests/helpers/expected.js <<EOF
export default {
  ember: '$EMBER',
  jquery: '$JQUERY',
  remodal: '$PACKED'
};
EOF

echo "== ember-cli $INSTALLED_CLI, expecting Ember $EMBER and jQuery $JQUERY in the browser"
# A cache from another run could hold templates another compiler produced.
export BROCCOLI_PERSISTENT_FILTER_CACHE_ROOT="$WORK/broccoli-cache"
limit ./node_modules/.bin/ember test --test-port "$PORT" 2>&1 | tee "$WORK/test.log"

# The run has to include every acceptance test, not merely exit clean.
RAN="$(grep -c '^ok .*Acceptance | packed ember-remodal: ' "$WORK/test.log" || true)"
if [ "$RAN" != 4 ]; then
  echo "Expected 4 passing packed ember-remodal tests, saw $RAN." >&2
  exit 1
fi

echo "== passed: consumer $CONSUMER, ember-remodal $PACKED on Ember $EMBER with jQuery $JQUERY"
