#!/usr/bin/env bash
set -e

###############################################################################
# Run the cpp-dev Docker image interactively
#
# Runs the prebuilt cpp-dev image with host UID/GID remapping.
# Matches DevContainer behavior for consistent file permissions.
#
# Usage:
#   ./scripts/docker/run.sh
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"
IMAGE_NAME="cpp-dev:latest"

# ------------------------------------------------------------------------------
# Ensure image exists
# ------------------------------------------------------------------------------
if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    echo "[INFO] Image '$IMAGE_NAME' not found. Building it first..."
    "${SCRIPT_DIR}/build_image.sh"
fi

# ------------------------------------------------------------------------------
# Run the container with DevContainer-compatible settings
# Pass HOST_UID and HOST_GID for runtime remapping
# ------------------------------------------------------------------------------
docker run --rm -it \
    --hostname cpp-devcontainer \
    --name "cpp-dev-${USER}" \
    --env "HOST_UID=$(id -u)" \
    --env "HOST_GID=$(id -g)" \
    --env "DISPLAY=${DISPLAY}" \
    --env TERM=xterm-256color \
    --volume /tmp/.X11-unix:/tmp/.X11-unix \
    --volume "$PROJECT_ROOT:/workspaces/$PROJECT_NAME" \
    --gpus all \
    --workdir /workspaces/$PROJECT_NAME \
    "$IMAGE_NAME"
