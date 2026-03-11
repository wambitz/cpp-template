#!/usr/bin/env bash
set -e

###############################################################################
# Format all C++ source/header files using clang-format
#
# Formats all C++ files in the project according to .clang-format config.
# When run outside the container, delegates execution to Docker automatically.
#
# Usage:
#   ./scripts/format.sh          - Format files in-place
#   ./scripts/format.sh --check  - Check formatting without modifying files
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"
source "$SCRIPT_DIR/docker/exec.sh"
delegate_to_container "$@"

# ---------------------------------------------------------------------------
# Format
# ---------------------------------------------------------------------------
CHECK_MODE=false
if [[ "$1" == "--check" ]]; then
    CHECK_MODE=true
    log_info "Running clang-format in check mode (no modifications)..."
else
    log_info "Running clang-format on source files..."
fi

EXTENSIONS=("*.cpp" "*.hpp" "*.cc" "*.h" "*.cxx" "*.hxx")
FOUND=false

for ext in "${EXTENSIONS[@]}"; do
    FILES=$(find "$PROJECT_ROOT/src" "$PROJECT_ROOT/tests" -type f -name "$ext" 2>/dev/null)

    for f in $FILES; do
        FOUND=true
        if $CHECK_MODE; then
            log_step "Checking $f"
            clang-format --dry-run --Werror "$f"
        else
            log_step "Formatting $f"
            clang-format -i "$f"
        fi
    done
done

if ! $FOUND; then
    log_warn "No files found to format."
else
    log_info "clang-format complete."
fi
