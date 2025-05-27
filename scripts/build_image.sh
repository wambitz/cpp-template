#!/usr/bin/env bash
set -e

###############################################################################
# Build the C++ Dev Docker image
#
# Usage:
#   ./scripts/build_image.sh [--tag <image_tag>]
#
# Default image tag: cpp-dev:latest
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"
DOCKERFILE_PATH="${PROJECT_ROOT}/Dockerfile"

IMAGE_TAG="cpp-dev:latest"

# ------------------------------------------------------------------------------
# Build the Docker image
# ------------------------------------------------------------------------------
echo "[INFO] Building Docker image: ${IMAGE_TAG}"
echo "[INFO] Dockerfile: ${DOCKERFILE_PATH}"
echo "[INFO] Project name: ${PROJECT_NAME}"

docker build \
  -f "${DOCKERFILE_PATH}" \
  -t "${IMAGE_TAG}" \
  --build-arg USERNAME="$(whoami)" \
  --build-arg USER_ID="$(id -u)" \
  --build-arg GROUP_ID="$(id -g)" \
  --build-arg PROJECT_NAME="${PROJECT_NAME}" \
  "${PROJECT_ROOT}"

echo "[INFO] Docker image '${IMAGE_TAG}' built successfully."
