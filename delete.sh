#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

echo ">>> Stopping containers..."
docker compose down

echo ">>> Removing MariaDB volume docker_mariadb_data..."
docker volume rm docker_mariadb_data || echo "Volume docker_mariadb_data not found, skipping."

echo ">>> Delete complete."

