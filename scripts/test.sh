#!/usr/bin/env bash
set -e

###############################################################################
# Run project tests
#
# Runs ctest on the build directory with verbose output on failure.
# When run outside the container, delegates execution to Docker automatically.
#
# Usage:
#   ./scripts/test.sh
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"
source "$SCRIPT_DIR/docker/exec.sh"
delegate_to_container "$@"

# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------
BUILD_DIR="${PROJECT_ROOT}/build"

if [ ! -d "$BUILD_DIR" ]; then
    log_error "Build directory not found. Run ./scripts/build.sh first."
    exit 1
fi

cd "$BUILD_DIR"

log_step "Running tests..."
ctest --output-on-failure

log_info "All tests passed."
