#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

echo ">>> Starting containers..."
docker compose up -d

echo ">>> Containers started."

