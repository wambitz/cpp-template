#!/bin/bash

set -e  # Exit on error

# Set build directory
BUILD_DIR="build"
INSTALL_DIR="install"

# Create and enter build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Run CMake
cmake -DCMAKE_INSTALL_PREFIX="../$INSTALL_DIR" ..

# Build all targets with all cores
make -j"$(nproc)"

# Install to ../install
make install
