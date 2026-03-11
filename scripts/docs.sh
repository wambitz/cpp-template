#!/usr/bin/env bash
set -e

###############################################################################
# Generate Doxygen documentation
#
# Generates HTML documentation from source code comments.
# When run outside the container, delegates execution to Docker automatically.
#
# Usage:
#   ./scripts/docs.sh
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"
source "$SCRIPT_DIR/docker/exec.sh"
delegate_to_container "$@"

# ---------------------------------------------------------------------------
# Documentation
# ---------------------------------------------------------------------------
cd "$PROJECT_ROOT"

log_info "Generating Doxygen documentation..."
log_info "Doxygen version: $(doxygen --version)"

doxygen docs/Doxyfile

log_info "Documentation generation complete."
