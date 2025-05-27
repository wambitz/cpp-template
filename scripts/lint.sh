#!/usr/bin/env bash
set -e

# ------------------------------------------------------------------------------
# Run clang-tidy over all C++ source files using the build compile_commands.json
# ------------------------------------------------------------------------------

BUILD_DIR="build"
TIDY_BIN=$(command -v clang-tidy || true)

if [ -z "$TIDY_BIN" ]; then
    echo "[ERROR] clang-tidy not found. Install it first."
    exit 1
fi

if [ ! -f "$BUILD_DIR/compile_commands.json" ]; then
    echo "[INFO] Generating compile_commands.json..."
    cmake -S . -B "$BUILD_DIR" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
fi

echo "[INFO] Running clang-tidy over source files..."

find src/ tests/ -type f \( -name '*.cpp' -o -name '*.cxx' -o -name '*.cc' \) | while read -r file; do
    echo "[TIDY] $file"
    clang-tidy "$file" -p "$BUILD_DIR" || true
done

echo "[INFO] clang-tidy lint complete."
