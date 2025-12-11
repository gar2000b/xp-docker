#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

# Detect if colors are supported
if [[ -t 1 ]] && command -v tput > /dev/null 2>&1; then
    # Terminal supports colors
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    NC=$(tput sgr0) # No Color
else
    # No color support - use empty strings
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

echo "=========================================="
echo "Docker Volume Size Checker"
echo "=========================================="
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
    echo ""
}

# Function to print container info
print_container_info() {
    local container=$1
    if docker ps -a --format "{{.Names}}" | grep -q "^${container}$"; then
        if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
            echo -e "${GREEN}[RUNNING]${NC} ${container}"
        else
            echo -e "${YELLOW}[STOPPED]${NC} ${container}"
        fi
    else
        echo -e "${RED}[NOT FOUND]${NC} ${container}"
    fi
}

# 1. Docker Volume Sizes (Named Volumes)
print_section "Docker Named Volumes"

echo "Checking Docker volumes defined in docker-compose.yml..."
echo ""

# Get all volumes from docker-compose
VOLUMES=$(docker compose config --volumes 2>/dev/null || docker-compose config --volumes 2>/dev/null || echo "")

if [ -n "$VOLUMES" ]; then
    for volume in $VOLUMES; do
        VOLUME_NAME="xp-docker_${volume}"
        if docker volume ls --format "{{.Name}}" | grep -q "^${VOLUME_NAME}$"; then
            VOLUME_SIZE=$(docker run --rm -v ${VOLUME_NAME}:/data alpine sh -c "du -sh /data 2>/dev/null | cut -f1" || echo "N/A")
            echo "  Volume: ${GREEN}${VOLUME_NAME}${NC}"
            echo "    Size: ${VOLUME_SIZE}"
            
            # Get volume mount point info
            VOLUME_INFO=$(docker volume inspect ${VOLUME_NAME} --format "{{.Mountpoint}}" 2>/dev/null || echo "")
            if [ -n "$VOLUME_INFO" ]; then
                echo "    Mount: ${VOLUME_INFO}"
            fi
            echo ""
        else
            echo "  Volume: ${YELLOW}${VOLUME_NAME}${NC} (not found)"
            echo ""
        fi
    done
else
    echo "  No named volumes found in docker-compose.yml"
fi

# 2. Container Filesystem Sizes
print_section "Container Filesystem Sizes"

CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep -E "(mariadb|influxdb|xp-)" || echo "")

if [ -n "$CONTAINERS" ]; then
    for container in $CONTAINERS; do
        print_container_info "$container"
        
        if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
            # Container is running - check internal filesystem
            echo "  Root filesystem size:"
            docker exec "$container" sh -c "df -h / 2>/dev/null | tail -1" 2>/dev/null || echo "    Unable to check"
            
            # Check specific data directories if they exist
            if docker exec "$container" test -d /var/lib/mysql 2>/dev/null; then
                MYSQL_SIZE=$(docker exec "$container" sh -c "du -sh /var/lib/mysql 2>/dev/null | cut -f1" || echo "N/A")
                echo "  /var/lib/mysql: ${MYSQL_SIZE}"
            fi
            
            if docker exec "$container" test -d /var/lib/influxdb2 2>/dev/null; then
                INFLUX_SIZE=$(docker exec "$container" sh -c "du -sh /var/lib/influxdb2 2>/dev/null | cut -f1" || echo "N/A")
                echo "  /var/lib/influxdb2: ${INFLUX_SIZE}"
                
                # Detailed InfluxDB breakdown
                echo "    Detailed breakdown:"
                docker exec "$container" sh -c "du -h --max-depth=1 /var/lib/influxdb2 2>/dev/null | sort -rh | head -10" 2>/dev/null || echo "      Unable to get breakdown"
            fi
            
            echo ""
        else
            echo "  (Container is stopped - cannot check internal filesystem)"
            echo ""
        fi
    done
else
    echo "  No containers found"
fi

# 3. Docker System Disk Usage
print_section "Docker System Disk Usage"

echo "Overall Docker disk usage:"
docker system df
echo ""

echo "Detailed volume usage:"
docker system df -v | grep -A 10 "VOLUME NAME" || docker system df -v
echo ""

# 4. Summary
print_section "Summary"

TOTAL_VOLUMES=$(docker volume ls --format "{{.Name}}" | grep "^xp-docker_" | wc -l)
RUNNING_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -E "(mariadb|influxdb|xp-)" | wc -l)
ALL_CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep -E "(mariadb|influxdb|xp-)" | wc -l)

echo "Total Docker volumes (xp-docker_*): ${TOTAL_VOLUMES}"
echo "Running containers: ${RUNNING_CONTAINERS}"
echo "All containers (running + stopped): ${ALL_CONTAINERS}"
echo ""

# 5. Host Disk Space
print_section "Host Disk Space"

echo "Available disk space on host:"
df -h / | tail -1
echo ""

# Check if we're in WSL or native Linux
if [ -d "/mnt/c" ]; then
    echo "Note: Running in WSL - Docker volumes are stored in the WSL filesystem"
    echo "WSL filesystem usage:"
    df -h / | grep -v "Filesystem"
fi

echo ""
echo "=========================================="
echo "Check complete!"
echo "=========================================="

