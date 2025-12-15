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
docker stop "$CONTAINER_NAME" || echo "Container $CONTAINER_NAME not running, skipping stop."

echo ">>> Removing container: $CONTAINER_NAME"
docker rm "$CONTAINER_NAME" || echo "Container $CONTAINER_NAME not found, skipping remove."

# Remove volumes for specific containers
if [ "$CONTAINER_NAME" = "mariadb" ]; then
    echo ">>> Removing MariaDB volume..."
    docker volume rm xp-docker_mariadb_data || echo "Volume xp-docker_mariadb_data not found, skipping."
elif [ "$CONTAINER_NAME" = "influxdb" ]; then
    echo ">>> Removing InfluxDB volumes..."
    docker volume rm xp-docker_influxdb_data || echo "Volume xp-docker_influxdb_data not found, skipping."
    docker volume rm xp-docker_influxdb_config || echo "Volume xp-docker_influxdb_config not found, skipping."
elif [ "$CONTAINER_NAME" = "kafka-1" ]; then
    echo ">>> Removing Kafka-1 volume..."
    docker volume rm xp-docker_kafka-1_data || echo "Volume xp-docker_kafka-1_data not found, skipping."
elif [ "$CONTAINER_NAME" = "kafka-2" ]; then
    echo ">>> Removing Kafka-2 volume..."
    docker volume rm xp-docker_kafka-2_data || echo "Volume xp-docker_kafka-2_data not found, skipping."
elif [ "$CONTAINER_NAME" = "kafka-3" ]; then
    echo ">>> Removing Kafka-3 volume..."
    docker volume rm xp-docker_kafka-3_data || echo "Volume xp-docker_kafka-3_data not found, skipping."
fi

echo ">>> Delete complete."

# reset the blinking cursor
tput cnorm 2>/dev/null || true
printf '\e[?25h' 2>/dev/null || true
stty sane 2>/dev/null || true
