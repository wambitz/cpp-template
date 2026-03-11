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
# ==============================================================================
log_info()    { echo -e "${GREEN}[INFO]${RESET} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $*"; }
log_step()    { echo -e "${CYAN}[STEP]${RESET} $*"; }
log_docker()  { echo -e "${BLUE}[CONTAINER]${RESET} $*"; }

# ==============================================================================
# Project paths
#
# SCRIPT_DIR must be set by the calling script before sourcing env.sh.
# ==============================================================================
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"
