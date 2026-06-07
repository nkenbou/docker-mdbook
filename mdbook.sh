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
    echo "ビルド成果物とキャッシュを削除しました"
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
    echo "mdbook が起動しました: http://localhost:${PORT}"
    echo "停止するには: ./mdbook.sh stop"
    ;;
esac
