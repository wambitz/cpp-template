#!/usr/bin/env bash
set -e

###############################################################################
# Build the project using CMake
#
# Builds in Debug mode by default and installs to the install/ directory.
# When run outside the container, delegates execution to Docker automatically.
#
# Usage:
#   ./scripts/build.sh
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"
source "$SCRIPT_DIR/docker/exec.sh"
delegate_to_container "$@"

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
BUILD_DIR="build"
INSTALL_DIR="install"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

log_step "Configuring CMake (Debug)..."
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="../$INSTALL_DIR" ..

log_step "Building with $(nproc) cores..."
make -j"$(nproc)"

log_step "Installing to ../$INSTALL_DIR"
make install

log_info "Build complete."
