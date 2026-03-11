#!/usr/bin/env bash

###############################################################################
# Environment setup for all project scripts
#
# Provides:
#   - Colored output and logging helpers
#   - Project path resolution
#
# Usage (source from other scripts):
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/env.sh"
###############################################################################

# ==============================================================================
# Color definitions (disabled when output is not a terminal)
# ==============================================================================
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    RESET=''
fi

# ==============================================================================
# Logging helpers
#
# - printf is used instead of echo -e for portable escape handling
# - log_warn and log_error write to stderr so pipelines stay clean
# ==============================================================================
log_info()   { printf '%b %s\n' "${GREEN}[INFO]${RESET}" "$*"; }
log_warn()   { printf '%b %s\n' "${YELLOW}[WARN]${RESET}" "$*" >&2; }
log_error()  { printf '%b %s\n' "${RED}[ERROR]${RESET}" "$*" >&2; }
log_step()   { printf '%b %s\n' "${CYAN}[STEP]${RESET}" "$*"; }
log_docker() { printf '%b %s\n' "${BLUE}[CONTAINER]${RESET}" "$*"; }

# ==============================================================================
# Project paths
#
# SCRIPT_DIR must be set by the calling script before sourcing env.sh.
# ==============================================================================
if [ -z "${SCRIPT_DIR:-}" ]; then
    log_error "SCRIPT_DIR is not set. Please set SCRIPT_DIR before sourcing env.sh."
    return 1
fi

if [ ! -d "$SCRIPT_DIR" ]; then
    log_error "SCRIPT_DIR '$SCRIPT_DIR' does not exist or is not a directory."
    return 1
fi

if ! PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"; then
    log_error "Failed to determine PROJECT_ROOT from SCRIPT_DIR '$SCRIPT_DIR'."
    return 1
fi
PROJECT_NAME="$(basename "$PROJECT_ROOT")"
