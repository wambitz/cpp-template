#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Launch a throw-away cpp-dev container that immediately runs gdbserver
# against a known binary, exposes it on localhost:2345, and dies when GDB
# disconnects.
#
# USAGE:
#   ./scripts/run_gdbserver.sh
#
# NOTES:
#   • Re-builds the image automatically if missing.
#   • Requires Docker CLI + Linux host (for --cap-add=SYS_PTRACE).
###############################################################################

SCRIPT_DIR="$( cd -- "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( dirname "${SCRIPT_DIR}" )"

IMAGE_NAME="cpp-dev:latest"        # <-- keep in sync with build_image.sh
CONTAINER_NAME="cpp-dev-gdbsrv"    # you can reuse the name each time

# ---------------------------------------------------------------------------
# Ensure the dev image exists (build if not)
# ---------------------------------------------------------------------------
if ! docker image inspect "${IMAGE_NAME}" &>/dev/null; then
  echo "[INFO] Docker image '${IMAGE_NAME}' not found,  building it first..."
  "${SCRIPT_DIR}/build_image.sh"
fi

# ---------------------------------------------------------------------------
# Define the in-container path to the binary you want to debug
# (Adjust if your build tree is different.)
# ---------------------------------------------------------------------------
PROJ_IN_CONTAINER="/workspaces/cpp-project-template"
TARGET_BIN="${PROJ_IN_CONTAINER}/build/src/main/main_exec"

# ---------------------------------------------------------------------------
# Compose the command that runs *inside* the container
# ---------------------------------------------------------------------------
# read -r -d '' IN_CONTAINER_CMD <<'BASH'
# set -e
# # Install gdbserver only if missing (adds ~2 MB)
# if ! command -v gdbserver &>/dev/null; then
#   echo "[INFO] Installing gdbserver..."
#   sudo apt-get update -qq
#   sudo apt-get install -y --no-install-recommends gdbserver
# fi

# echo "[INFO] Starting gdbserver on :2345"
# exec gdbserver :2345 '"${TARGET_BIN}"'
# BASH

# ---------------------------------------------------------------------------
# Launch the throw-away container
# ---------------------------------------------------------------------------
docker run --rm -it \
  --name "${CONTAINER_NAME}" \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  -p 2345:2345 \
  -v "${PROJECT_ROOT}:${PROJ_IN_CONTAINER}" \
  "${IMAGE_NAME}" 
  # bash -c "${IN_CONTAINER_CMD//\"/\\\"}"

# When gdbserver exits (you quit the debug session) the container stops
echo "[INFO] Container finished - gdbserver session ended."
