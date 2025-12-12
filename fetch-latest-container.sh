#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

# Check if service name argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <service-name>"
    echo ""
    echo "Example: $0 xp-ohlcv-generator-service"
    echo ""
    echo "Available services:"
    docker-compose config --services | sed 's/^/  - /'
    exit 1
fi

SERVICE_NAME="$1"

# Validate that the service exists in docker-compose.yml
if ! docker-compose config --services | grep -q "^${SERVICE_NAME}$"; then
    echo "Error: Service '${SERVICE_NAME}' not found in docker-compose.yml"
    echo ""
    echo "Available services:"
    docker-compose config --services | sed 's/^/  - /'
    exit 1
fi

echo "=========================================="
echo "Updating container: ${SERVICE_NAME}"
echo "=========================================="
echo ""

echo "Step 1: Pulling latest image..."
docker-compose pull "${SERVICE_NAME}"

echo ""
echo "Step 2: Recreating container with latest image..."
docker-compose up -d --force-recreate --no-deps "${SERVICE_NAME}"

echo ""
echo "=========================================="
echo "Container '${SERVICE_NAME}' updated successfully!"
echo "=========================================="
echo ""
echo "Container status:"
docker-compose ps "${SERVICE_NAME}"

