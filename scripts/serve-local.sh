#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${PORT:-8000}"
IMAGE_NAME="${IMAGE_NAME:-illionj-mkdocs-local}"
CONTAINER_NAME="${CONTAINER_NAME:-illionj-mkdocs-dev}"
FORCE_BUILD="${FORCE_BUILD:-0}"
PIP_INDEX_URL="${PIP_INDEX_URL:-https://pypi.tuna.tsinghua.edu.cn/simple}"

if [[ "$FORCE_BUILD" == "1" ]] || ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "[local] building local image: ${IMAGE_NAME}"
  echo "[local] pip index: ${PIP_INDEX_URL}"
  docker build \
    --build-arg "PIP_INDEX_URL=${PIP_INDEX_URL}" \
    -t "$IMAGE_NAME" \
    "$ROOT_DIR"
fi

if docker ps --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
  echo "[local] container already running: ${CONTAINER_NAME}"
  echo "[local] open: http://127.0.0.1:${PORT}"
  exit 0
fi

if docker ps -a --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
  docker rm -f "$CONTAINER_NAME" >/dev/null
fi

echo "[local] starting MkDocs container on port ${PORT}"
echo "[local] image: ${IMAGE_NAME}"
echo "[local] container: ${CONTAINER_NAME}"

exec docker run --rm \
  -it \
  --name "$CONTAINER_NAME" \
  -v "$ROOT_DIR:/site" \
  -p "$PORT:8000" \
  "$IMAGE_NAME" \
  mkdocs serve --dev-addr 0.0.0.0:8000
