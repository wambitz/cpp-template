#!/usr/bin/env bash
set -e

###############################################################################
# Install git hooks
#
# Points git to the .githooks/ directory so that version-controlled hooks
# are used automatically. Run once after cloning:
#
#   ./scripts/install-hooks.sh
#
# This script runs directly on the host (no Docker delegation).
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

git -C "$PROJECT_ROOT" config core.hooksPath .githooks
log_info "Git hooks installed (.githooks/). core.hooksPath set."
