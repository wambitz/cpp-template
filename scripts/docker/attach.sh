#!/usr/bin/env bash
set -e

# ------------------------------------------------------------------------------
# Attach to the running cpp-dev container as 'ubuntu' (remapped UID/GID)
# Fails if the container is not running (expected behavior).
# ------------------------------------------------------------------------------

CONTAINER_NAME="cpp-dev-${USER}"

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "[ERROR] Container '${CONTAINER_NAME}' is not running." >&2
  echo "Start it with: ./scripts/docker/run.sh" >&2
  exit 1
fi

docker exec -it -u ubuntu "$CONTAINER_NAME" bash
