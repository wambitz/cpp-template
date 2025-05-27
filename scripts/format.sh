#!/bin/bash

# --------------------------------------------------------------------
# Format all C++ source/header files in the project using clang-format
# --------------------------------------------------------------------

#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "[INFO] Running clang-format on source files..."

EXTENSIONS=("*.cpp" "*.hpp" "*.cc" "*.h" "*.cxx" "*.hxx")
FOUND=false

for ext in "${EXTENSIONS[@]}"; do
    FILES=$(find "$PROJECT_ROOT/src" "$PROJECT_ROOT/tests" -type f -name "$ext" 2>/dev/null)

    for f in $FILES; do
        FOUND=true
        echo "Formatting $f"
        clang-format -i "$f"
    done
done

if ! $FOUND; then
    echo "[INFO] No files found to format."
else
    echo "[INFO] clang-format complete."
fi
