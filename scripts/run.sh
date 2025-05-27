#!/usr/bin/env bash
set -e

# ------------------------------------------------------------------------------
# Run the prebuilt cpp-dev Docker image interactively with matching settings
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_NAME="cpp-project-template"
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
# ------------------------------------------------------------------------------
docker run --rm -it \
    --hostname cpp-devcontainer \
    --name cpp-devcontainer \
    --env "DISPLAY=${DISPLAY}" \
    --volume /tmp/.X11-unix:/tmp/.X11-unix \
    --volume "$PROJECT_ROOT:/workspaces/$PROJECT_NAME" \
    --gpus all \
    --workdir /workspaces/$PROJECT_NAME \
    "$IMAGE_NAME"
