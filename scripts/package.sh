#!/bin/bash

set -e  # Exit on error

# Set build directory
BUILD_DIR="build"
INSTALL_DIR="install"

echo "[INFO] Building project..."

# Create and enter build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Run CMake with Release build type by default (disable coverage for packaging)
cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_COVERAGE=OFF -DCMAKE_INSTALL_PREFIX="../$INSTALL_DIR" ..

# Build all targets with all cores
make -j"$(nproc)"

# Install to ../install
make install

echo "[INFO] Creating packages..."

# Create packages using CPack
cpack

echo "[INFO] Build and packaging complete!"
echo "[INFO] Packages created:"
ls -la *.tar.gz *.zip *.deb 2>/dev/null || echo "No packages found"
