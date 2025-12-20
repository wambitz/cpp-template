#!/usr/bin/env bash
set -e

###############################################################################
# Build and run code coverage analysis
#
# Builds with coverage enabled, runs tests, and generates HTML coverage report.
#
# Usage:
#   ./scripts/coverage.sh
###############################################################################

# Set build directory
BUILD_DIR="build"
INSTALL_DIR="install"

echo "Building with code coverage enabled..."

# Create and enter build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Run CMake with coverage enabled
cmake -DCMAKE_BUILD_TYPE=Debug -DENABLE_COVERAGE=ON -DCMAKE_INSTALL_PREFIX="../$INSTALL_DIR" ..

# Build all targets with all cores
make -j"$(nproc)"

# Run tests to generate coverage data
make test

# Generate coverage report with lcov
echo "Generating coverage report..."
export LC_ALL=C  # Fix locale warnings
lcov --capture --directory . --output-file coverage.info --ignore-errors mismatch
lcov --remove coverage.info '/usr/*' --output-file coverage.info --ignore-errors unused  # Remove system files
lcov --remove coverage.info '*/build/*' --output-file coverage.info --ignore-errors unused  # Remove build files
lcov --remove coverage.info '*/tests/*' --output-file coverage.info --ignore-errors unused  # Remove test files
lcov --remove coverage.info '*/_deps/*' --output-file coverage.info --ignore-errors unused  # Remove external deps

# Generate HTML report
genhtml coverage.info --output-directory coverage_report

echo "Coverage report generated in build/coverage_report/"
echo "Open build/coverage_report/index.html in your browser to view the report"

# Optional: Install the project
# make install
