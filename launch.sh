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

echo "Waiting for MariaDB and InfluxDB to be fully ready..."
for i in 10 9 8 7 6 5 4 3 2 1; do
  echo "  → initializing in $i seconds..."
  sleep 1
done

docker exec -i mariadb sh /sql/00_init_all.sh

echo ">>> Launch complete. MariaDB is starting with a fresh data directory."

docker exec -i influxdb influx bucket create --name ohlcv_data --org xp-project --token xp-admin-token-12345 --host http://localhost:8086 || echo "Bucket ohlcv_data may already exist (OK)"

echo ">>> InfluxDB ohlcv_data bucket created."

docker exec kafka-1 /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-1:29092,kafka-2:29092,kafka-3:29092 --create --topic ohlcv-topic --partitions 3 --replication-factor 3 --if-not-exists

echo ">>> Kafka ohlcv-topic created."

tree

# reset the blinking cursor
tput cnorm 2>/dev/null || true
printf '\e[?25h' 2>/dev/null || true
stty sane 2>/dev/null || true
