#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCS_DIR="${PROJECT_ROOT}/docs"

echo "[INFO] Generating Doxygen documentation..."
echo "[INFO] Doxygen version: $(doxygen --version)"

# Run doxygen from project root
doxygen "$DOCS_DIR/Doxyfile"

