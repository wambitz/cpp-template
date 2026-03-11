#!/usr/bin/env bash
set -e

###############################################################################
# Build and run code coverage analysis
#
# Builds with coverage enabled, runs tests, and generates HTML coverage report.
# When run outside the container, delegates execution to Docker automatically.
#
# Usage:
#   ./scripts/coverage.sh
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"
source "$SCRIPT_DIR/docker/exec.sh"
delegate_to_container "$@"

# ---------------------------------------------------------------------------
# Coverage
# ---------------------------------------------------------------------------
cd "$PROJECT_ROOT"

BUILD_DIR="${PROJECT_ROOT}/build"
INSTALL_DIR="${PROJECT_ROOT}/install"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

log_step "Configuring CMake with coverage enabled..."
cmake -DCMAKE_BUILD_TYPE=Debug -DENABLE_COVERAGE=ON -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" "$PROJECT_ROOT"

log_step "Building with $(nproc) cores..."
make -j"$(nproc)"

log_step "Running tests..."
make test

log_step "Generating coverage report..."
export LC_ALL=C
lcov --capture --directory . --output-file coverage.info --ignore-errors mismatch
lcov --remove coverage.info '/usr/*' --output-file coverage.info --ignore-errors unused
lcov --remove coverage.info '*/build/*' --output-file coverage.info --ignore-errors unused
lcov --remove coverage.info '*/tests/*' --output-file coverage.info --ignore-errors unused
lcov --remove coverage.info '*/_deps/*' --output-file coverage.info --ignore-errors unused

genhtml coverage.info --output-directory coverage_report

log_info "Coverage report generated in ${BUILD_DIR}/coverage_report/"
log_info "Open ${BUILD_DIR}/coverage_report/index.html in your browser to view the report."
