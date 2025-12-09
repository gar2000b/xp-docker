#!/usr/bin/env bash
set -e

# Always run from the directory where this script lives
cd "$(dirname "$0")"

echo ">>> Stopping any running containers..."
docker compose down

echo ">>> Removing MariaDB volume docker_mariadb_data..."
docker volume rm xp-docker_mariadb_data || echo "Volume docker_mariadb_data not found, skipping."

echo ">>> Starting fresh stack (this will run init SQL scripts)..."
docker compose up -d --pull always --force-recreate

echo "Waiting for MariaDB to be fully ready..."
for i in 10 9 8 7 6 5 4 3 2 1; do
  echo "  → initializing in $i seconds..."
  sleep 1
done

docker exec -i mariadb sh /sql/00_init_all.sh

echo ">>> Launch complete. MariaDB is starting with a fresh data directory."

tree
