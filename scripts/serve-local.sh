#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_DIR="$ROOT_DIR/vendor/bundle"
PORT="${PORT:-4000}"
BUNDLE_MIRROR="${BUNDLE_MIRROR:-https://gems.ruby-china.com}"
IMAGE_NAME="${IMAGE_NAME:-illionj-jekyll-local}"

mkdir -p "$BUNDLE_DIR"

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "[local] building local image: ${IMAGE_NAME}"
  docker build -t "$IMAGE_NAME" "$ROOT_DIR"
fi

echo "[local] starting Jekyll container on port ${PORT}"
echo "[local] bundle cache: ${BUNDLE_DIR}"
echo "[local] image: ${IMAGE_NAME}"
if [[ -n "$BUNDLE_MIRROR" ]]; then
  echo "[local] bundle mirror: ${BUNDLE_MIRROR}"
fi

exec docker run --rm \
  -it \
  -v "$ROOT_DIR:/srv/jekyll" \
  -v "$BUNDLE_DIR:/usr/local/bundle" \
  -p "$PORT:4000" \
  "$IMAGE_NAME" \
  bash -lc '
    set -euo pipefail
    echo "[container] ruby: $(ruby -v)"
    echo "[container] bundler: $(bundle -v)"
    echo "[container] configuring bundle path"
    bundle config set path /usr/local/bundle
    if [[ -n "'"$BUNDLE_MIRROR"'" ]]; then
      echo "[container] configuring rubygems mirror"
      bundle config set mirror.https://rubygems.org "'"$BUNDLE_MIRROR"'"
    fi
    echo "[container] checking gems"
    if bundle check; then
      echo "[container] gems already installed"
    else
      echo "[container] installing gems"
      bundle install --jobs 4 --retry 3 --verbose
    fi
    echo "[container] starting jekyll"
    exec bundle exec jekyll serve --trace --host 0.0.0.0 --port 4000 --force_polling
  '
