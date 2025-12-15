#!/usr/bin/env bash
set -e

# Always run from the directory where this script lives
cd "$(dirname "$0")"

if [ -z "$1" ]; then
    echo "Error: Container name is required"
    echo "Usage: $0 <container-name>"
    exit 1
fi

CONTAINER_NAME="$1"

echo ">>> Starting container: $CONTAINER_NAME"
docker compose up -d --pull always --force-recreate "$CONTAINER_NAME"

echo ">>> Container launched: $CONTAINER_NAME"

# reset the blinking cursor
tput cnorm 2>/dev/null || true
printf '\e[?25h' 2>/dev/null || true
stty sane 2>/dev/null || true
