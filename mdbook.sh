#!/bin/sh
set -e

IMAGE="ghcr.io/nkenbou/docker-mdbook:latest"
BOOK_DIR="$(cd "$(dirname "$0")/docs" && pwd)"
CONTAINER_NAME="mdbook"

PORT="${MDBOOK_PORT:-3000}"
PORT_ARGS=""
DETACH_ARGS=""

case "${1:-}" in
  stop)
    docker stop "${CONTAINER_NAME}"
    exit 0
    ;;
  clean)
    rm -rf "${BOOK_DIR}/book" "${BOOK_DIR}/.mdbook-plantuml-cache"
    echo "Removed build artifacts and cache."
    exit 0
    ;;
  install-assets)
    WORK_DIR=$(mktemp -d)
    trap 'rm -rf "${WORK_DIR}"' EXIT
    echo '[book]' > "${WORK_DIR}/book.toml"
    docker run --rm \
      --entrypoint mdbook-mermaid \
      --user "$(id -u):$(id -g)" \
      -v "${WORK_DIR}:/work" \
      "${IMAGE}" \
      install /work
    cp "${WORK_DIR}/mermaid.min.js"  "${BOOK_DIR}/.mdbook/mermaid.min.js"
    cp "${WORK_DIR}/mermaid-init.js" "${BOOK_DIR}/.mdbook/mermaid-init.js"
    echo "Updated mermaid assets."
    exit 0
    ;;
  serve|watch)
    PORT_ARGS="-p ${PORT}:3000"
    DETACH_ARGS="-d"
    ;;
esac

# shellcheck disable=SC2086
docker run --rm \
  --name "${CONTAINER_NAME}" \
  -v "${BOOK_DIR}:/book" \
  ${PORT_ARGS} \
  ${DETACH_ARGS} \
  --user "$(id -u):$(id -g)" \
  "${IMAGE}" \
  "$@"

case "${1:-}" in
  serve|watch)
    echo "mdbook started: http://localhost:${PORT}"
    echo "To stop: ./mdbook.sh stop"
    ;;
esac
