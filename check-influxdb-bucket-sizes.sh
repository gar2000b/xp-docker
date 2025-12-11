#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

echo "=========================================="
echo "InfluxDB Bucket Size Checker"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# InfluxDB connection details
INFLUXDB_CONTAINER="influxdb"
INFLUXDB_ORG="xp-project"
INFLUXDB_TOKEN="xp-admin-token-12345"
INFLUXDB_URL="http://localhost:8086"

# Check if InfluxDB container is running
if ! docker ps --format "{{.Names}}" | grep -q "^${INFLUXDB_CONTAINER}$"; then
    echo -e "${YELLOW}Warning: InfluxDB container is not running${NC}"
    echo "Please start the container first: docker compose up -d influxdb"
    exit 1
fi

echo -e "${BLUE}=== Listing All Buckets ===${NC}"
echo ""

# List all buckets
BUCKETS=$(docker exec -i ${INFLUXDB_CONTAINER} influx bucket list \
    --org ${INFLUXDB_ORG} \
    --token ${INFLUXDB_TOKEN} \
    --host ${INFLUXDB_URL} \
    --json 2>/dev/null | jq -r '.[].name' 2>/dev/null || echo "")

if [ -z "$BUCKETS" ]; then
    echo "No buckets found or unable to connect to InfluxDB"
    exit 1
fi

echo "Found buckets:"
for bucket in $BUCKETS; do
    echo "  - ${GREEN}${bucket}${NC}"
done
echo ""

echo -e "${BLUE}=== Bucket Data Point Counts ===${NC}"
echo ""

# For each bucket, count data points
for bucket in $BUCKETS; do
    echo -e "${GREEN}Bucket: ${bucket}${NC}"
    
    # Count total data points in the bucket
    COUNT_QUERY="from(bucket: \"${bucket}\") |> range(start: 0) |> count() |> sum()"
    
    COUNT_RESULT=$(docker exec -i ${INFLUXDB_CONTAINER} influx query \
        "${COUNT_QUERY}" \
        --org ${INFLUXDB_ORG} \
        --token ${INFLUXDB_TOKEN} \
        --host ${INFLUXDB_URL} \
        --raw 2>/dev/null | grep -oP '_value:\s*\K[0-9]+' | head -1 || echo "0")
    
    if [ -z "$COUNT_RESULT" ] || [ "$COUNT_RESULT" = "0" ]; then
        # Try alternative query format
        COUNT_RESULT=$(docker exec -i ${INFLUXDB_CONTAINER} influx query \
            "${COUNT_QUERY}" \
            --org ${INFLUXDB_ORG} \
            --token ${INFLUXDB_TOKEN} \
            --host ${INFLUXDB_URL} \
            2>/dev/null | grep -E "^[0-9]+$" | head -1 || echo "0")
    fi
    
    if [ "$COUNT_RESULT" != "0" ] && [ -n "$COUNT_RESULT" ]; then
        echo "  Total data points: ${COUNT_RESULT}"
        
        # Estimate size (assuming ~400 bytes per point on average)
        ESTIMATED_SIZE=$((COUNT_RESULT * 400))
        ESTIMATED_SIZE_MB=$((ESTIMATED_SIZE / 1024 / 1024))
        ESTIMATED_SIZE_KB=$((ESTIMATED_SIZE / 1024))
        
        if [ $ESTIMATED_SIZE_MB -gt 0 ]; then
            echo "  Estimated size: ~${ESTIMATED_SIZE_MB} MB"
        else
            echo "  Estimated size: ~${ESTIMATED_SIZE_KB} KB"
        fi
    else
        echo "  Total data points: 0 (empty bucket)"
    fi
    
    # Count by measurement if possible
    MEASUREMENTS_QUERY="import \"influxdata/influxdb/schema\" schema.measurements(bucket: \"${bucket}\")"
    
    MEASUREMENTS=$(docker exec -i ${INFLUXDB_CONTAINER} influx query \
        "${MEASUREMENTS_QUERY}" \
        --org ${INFLUXDB_ORG} \
        --token ${INFLUXDB_TOKEN} \
        --host ${INFLUXDB_URL} \
        --raw 2>/dev/null | grep -oP '_value:\s*"\K[^"]+' || echo "")
    
    if [ -n "$MEASUREMENTS" ]; then
        echo "  Measurements:"
        for measurement in $MEASUREMENTS; do
            # Count points per measurement
            MEAS_COUNT_QUERY="from(bucket: \"${bucket}\") |> range(start: 0) |> filter(fn: (r) => r._measurement == \"${measurement}\") |> count() |> sum()"
            
            MEAS_COUNT=$(docker exec -i ${INFLUXDB_CONTAINER} influx query \
                "${MEAS_COUNT_QUERY}" \
                --org ${INFLUXDB_ORG} \
                --token ${INFLUXDB_TOKEN} \
                --host ${INFLUXDB_URL} \
                --raw 2>/dev/null | grep -oP '_value:\s*\K[0-9]+' | head -1 || echo "0")
            
            if [ "$MEAS_COUNT" != "0" ] && [ -n "$MEAS_COUNT" ]; then
                echo "    - ${measurement}: ${MEAS_COUNT} points"
            fi
        done
    fi
    
    echo ""
done

echo -e "${BLUE}=== Bucket Retention Policies ===${NC}"
echo ""

# Show retention policies for each bucket
for bucket in $BUCKETS; do
    RETENTION=$(docker exec -i ${INFLUXDB_CONTAINER} influx bucket list \
        --org ${INFLUXDB_ORG} \
        --token ${INFLUXDB_TOKEN} \
        --host ${INFLUXDB_URL} \
        --json 2>/dev/null | jq -r ".[] | select(.name==\"${bucket}\") | .retentionRules[0].everySeconds" 2>/dev/null || echo "")
    
    if [ -n "$RETENTION" ] && [ "$RETENTION" != "null" ] && [ "$RETENTION" != "0" ]; then
        RETENTION_DAYS=$((RETENTION / 86400))
        echo "${bucket}: ${RETENTION_DAYS} days retention"
    else
        echo "${bucket}: No retention policy (infinite)"
    fi
done

echo ""
echo "=========================================="
echo "Check complete!"
echo "=========================================="
echo ""
echo "Note: Size estimates are approximate (~400 bytes per data point)"
echo "Actual size may vary based on field types, tags, and compression."

