#!/bin/bash

# --------------------------------------------------------------------
# Format all C++ source/header files in the project using clang-format
# Usage:
#   ./format.sh          - Format files in-place
#   ./format.sh --check  - Check formatting without modifying files
# --------------------------------------------------------------------

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if --check flag is passed
CHECK_MODE=false
if [[ "$1" == "--check" ]]; then
    CHECK_MODE=true
    echo "[INFO] Running clang-format in check mode (no modifications)..."
else
    echo "[INFO] Running clang-format on source files..."
fi

EXTENSIONS=("*.cpp" "*.hpp" "*.cc" "*.h" "*.cxx" "*.hxx")
FOUND=false

for ext in "${EXTENSIONS[@]}"; do
    FILES=$(find "$PROJECT_ROOT/src" "$PROJECT_ROOT/tests" -type f -name "$ext" 2>/dev/null)

    for f in $FILES; do
        FOUND=true
        if $CHECK_MODE; then
            echo "Checking $f"
            clang-format --dry-run --Werror "$f"
        else
            echo "Formatting $f"
            clang-format -i "$f"
        fi
    done
done

if ! $FOUND; then
    echo "[INFO] No files found to format."
else
    echo "[INFO] clang-format complete."
fi
