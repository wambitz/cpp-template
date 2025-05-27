#!/bin/bash

set -e  # Exit on error

# Set build directory
BUILD_DIR="build"

# Create and enter build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Run CMake
cmake ..

# Build all targets with all cores
make -j"$(nproc)"
