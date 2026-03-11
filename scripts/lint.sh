#!/usr/bin/env bash
set -e

###############################################################################
# Run clang-tidy static analysis
#
# Runs clang-tidy over all C++ source files using compile_commands.json.
# When run outside the container, delegates execution to Docker automatically.
#
# Usage:
#   ./scripts/lint.sh
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"
source "$SCRIPT_DIR/docker/exec.sh"
delegate_to_container "$@"

# ---------------------------------------------------------------------------
# Lint
# ---------------------------------------------------------------------------
cd "$PROJECT_ROOT"

BUILD_DIR="${PROJECT_ROOT}/build"

log_info "Running clang-tidy over source files..."

find "${PROJECT_ROOT}/src" "${PROJECT_ROOT}/tests" -type f \( -name '*.cpp' -o -name '*.cxx' -o -name '*.cc' \) | while read -r file; do
    log_step "$file"
    clang-tidy "$file" -p "$BUILD_DIR" || true
done

log_info "clang-tidy lint complete."
