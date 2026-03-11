#!/usr/bin/env bash
set -e

###############################################################################
# Package the project for distribution
#
# Builds in Release mode and creates distributable packages.
# When run outside the container, delegates execution to Docker automatically.
#
# Usage:
#   ./scripts/package.sh
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"
source "$SCRIPT_DIR/docker/exec.sh"
delegate_to_container "$@"

# ---------------------------------------------------------------------------
# Package
# ---------------------------------------------------------------------------
BUILD_DIR="build"
INSTALL_DIR="install"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

log_step "Configuring CMake (Release)..."
cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_COVERAGE=OFF -DCMAKE_INSTALL_PREFIX="../$INSTALL_DIR" ..

log_step "Building with $(nproc) cores..."
make -j"$(nproc)"

log_step "Installing to ../$INSTALL_DIR"
make install

log_step "Creating packages with CPack..."
cpack

log_info "Build and packaging complete."
log_info "Packages created:"
ls -la *.tar.gz *.zip *.deb 2>/dev/null || log_warn "No packages found."
