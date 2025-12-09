#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

echo ">>> Stopping containers..."
docker compose stop

echo ">>> Containers stopped."

