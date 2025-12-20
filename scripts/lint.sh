#!/usr/bin/env bash
set -e

###############################################################################
# Run clang-tidy static analysis
#
# Runs clang-tidy over all C++ source files using compile_commands.json.
#
# Usage:
#   ./scripts/lint.sh
###############################################################################

BUILD_DIR="build"
TIDY_BIN=$(command -v clang-tidy || true)

if [ -z "$TIDY_BIN" ]; then
    echo "[ERROR] clang-tidy not found. Install it first."
    exit 1
fi

echo "[INFO] Running clang-tidy over source files..."

find src/ tests/ -type f \( -name '*.cpp' -o -name '*.cxx' -o -name '*.cc' \) | while read -r file; do
    echo "[TIDY] $file"
    clang-tidy "$file" -p "$BUILD_DIR" || true
done

echo "[INFO] clang-tidy lint complete."
