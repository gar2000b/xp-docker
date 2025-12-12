#!/usr/bin/env bash

set -euo pipefail

docker ps --format \
'table {{.Names}}\t{{.Image}}\t{{.Label "org.opencontainers.image.version"}}'

