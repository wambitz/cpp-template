#!/usr/bin/env bash
set -e

###############################################################################
# Build the project using CMake
#
# Builds in Debug mode by default and installs to the install/ directory.
#
# Usage:
#   ./scripts/build.sh
###############################################################################

# Set build directory
BUILD_DIR="build"
INSTALL_DIR="install"

# Create and enter build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Run CMake with Debug build type by default (for development)
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="../$INSTALL_DIR" ..

# Build all targets with all cores
make -j"$(nproc)"

# Install to ../install
make install
