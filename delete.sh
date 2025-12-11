#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

echo ">>> Stopping containers..."
docker compose down

echo ">>> Removing volumes..."
docker volume rm xp-docker_mariadb_data || echo "Volume xp-docker_mariadb_data not found, skipping."
docker volume rm xp-docker_influxdb_data || echo "Volume xp-docker_influxdb_data not found, skipping."
docker volume rm xp-docker_influxdb_config || echo "Volume xp-docker_influxdb_config not found, skipping."

echo ">>> Delete complete."

