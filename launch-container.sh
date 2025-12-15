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

# Handle initialization for specific containers
if [ "$CONTAINER_NAME" = "mariadb" ]; then
    echo "Waiting for MariaDB to be fully ready..."
    for i in 10 9 8 7 6 5 4 3 2 1; do
        echo "  → initializing in $i seconds..."
        sleep 1
    done
    
    docker exec -i mariadb sh /sql/00_init_all.sh
    echo ">>> Launch complete. MariaDB is starting with a fresh data directory."
elif [ "$CONTAINER_NAME" = "influxdb" ]; then
    echo "Waiting for InfluxDB to be fully ready..."
    for i in 10 9 8 7 6 5 4 3 2 1; do
        echo "  → initializing in $i seconds..."
        sleep 1
    done
    
    docker exec -i influxdb influx bucket create --name ohlcv_data --org xp-project --token xp-admin-token-12345 --host http://localhost:8086 || echo "Bucket ohlcv_data may already exist (OK)"
    echo ">>> InfluxDB ohlcv_data bucket created."
else
    echo ">>> Container launched: $CONTAINER_NAME"
fi

# reset the blinking cursor
tput cnorm 2>/dev/null || true
printf '\e[?25h' 2>/dev/null || true
stty sane 2>/dev/null || true
