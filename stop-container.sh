#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

if [ -z "$1" ]; then
    echo "Error: Container name is required"
    echo "Usage: $0 <container-name>"
    exit 1
fi

CONTAINER_NAME="$1"

echo ">>> Stopping container: $CONTAINER_NAME"
docker stop "$CONTAINER_NAME"

echo ">>> Container stopped: $CONTAINER_NAME"
