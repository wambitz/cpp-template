#!/usr/bin/env bash

###############################################################################
# Container delegation for project scripts
#
# When a script is invoked outside the container, this module re-executes it
# inside a disposable Docker container (docker run --rm) and exits.
# If already inside the container, it returns immediately and the calling
# script continues as normal.
#
# How it works:
#
#   Host shell                            Container shell
#   ----------                            ----------------
#   ./scripts/build.sh
#     source env.sh
#     source docker/exec.sh
#     delegate_to_container
#       docker run --rm ... build.sh  -->  ./scripts/build.sh
#       exit $?                              source env.sh
#                                            source docker/exec.sh
#                                            delegate_to_container
#                                              sees /.dockerenv
#                                              return 0
#                                            cmake ...
#                                            make ...
#                                         <-- exits (container destroyed)
#
# The host starts a subprocess (docker run) that runs the SAME script from
# scratch. The second invocation detects /.dockerenv, skips delegation,
# and executes the real work. The host waits for the exit code and forwards it.
# The container is destroyed automatically after the script finishes (--rm).
#
# Requires env.sh to be sourced first (for logging helpers and PROJECT_ROOT).
#
# Usage (from any project script, after sourcing env.sh):
#   source "$SCRIPT_DIR/docker/exec.sh"
#   delegate_to_container "$@"
###############################################################################

IMAGE_NAME="cpp-dev:latest"
CONTAINER_WORKDIR="/workspaces/${PROJECT_NAME}"

delegate_to_container() {
    # Already inside the container -- nothing to do
    if [ -f /.dockerenv ]; then
        return 0
    fi

    # CI environments provide their own toolchain -- skip delegation
    if [ "${CI:-}" = "true" ]; then
        return 0
    fi

    # Resolve the calling script path relative to project root (portable)
    local caller_script="${BASH_SOURCE[1]}"
    local script_absolute
    script_absolute="$(cd "$(dirname "$caller_script")" && pwd)/$(basename "$caller_script")"
    local script_relative="${script_absolute#"$PROJECT_ROOT"/}"

    if [ "$script_relative" = "$script_absolute" ]; then
        log_error "Script '${caller_script}' is not under PROJECT_ROOT '${PROJECT_ROOT}'."
        return 1
    fi

    # Preflight: verify Docker is installed and the daemon is reachable
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker to use container delegation."
        return 1
    fi

    if ! docker version &> /dev/null; then
        log_error "Docker daemon is not reachable. Is the Docker service running?"
        return 1
    fi

    log_docker "Running outside container -- delegating to Docker..."

    # Build the image if it does not exist yet
    if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
        log_docker "Image '${IMAGE_NAME}' not found. Building it first..."
        "${PROJECT_ROOT}/scripts/docker/build_image.sh"
    fi

    # Run the script inside a disposable container
    docker run --rm \
        --hostname cpp-devcontainer \
        --env "HOST_UID=$(id -u)" \
        --env "HOST_GID=$(id -g)" \
        --env TERM=xterm-256color \
        --volume "$PROJECT_ROOT:${CONTAINER_WORKDIR}" \
        --workdir "${CONTAINER_WORKDIR}" \
        "$IMAGE_NAME" \
        bash "${CONTAINER_WORKDIR}/${script_relative}" "$@"

    exit $?
}
