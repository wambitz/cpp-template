#!/usr/bin/env bash
set -e

###############################################################################
# Install git hooks
#
# Points git to the .githooks/ directory so that version-controlled hooks
# are used automatically. Run once after cloning:
#
#   ./scripts/install-hooks.sh
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

git -C "$REPO_ROOT" config core.hooksPath .githooks
echo "[INFO] Git hooks installed (.githooks/). core.hooksPath set."
