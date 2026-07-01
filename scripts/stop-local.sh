#!/usr/bin/env bash

set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-illionj-jekyll-dev}"

if docker ps -a --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
  echo "[local] stopping container: ${CONTAINER_NAME}"
  docker rm -f "$CONTAINER_NAME" >/dev/null
  echo "[local] stopped"
else
  echo "[local] container not running: ${CONTAINER_NAME}"
fi
