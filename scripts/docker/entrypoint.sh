#!/usr/bin/env bash
set -e

###############################################################################
# Docker entrypoint script for UID/GID remapping
#
# Remaps the ubuntu user's UID/GID at runtime to match the host user.
# This ensures proper file permissions for mounted volumes.
#
# Environment variables:
#   HOST_UID - Host user ID to remap to (default: 1000)
#   HOST_GID - Host group ID to remap to (default: 1000)
###############################################################################

# Get host UID/GID from environment (defaults to 1000 if not set)
HOST_UID=${HOST_UID:-1000}
HOST_GID=${HOST_GID:-1000}

# Container user (hardcoded to 'ubuntu' to match Ubuntu base image convention)
CONTAINER_USER=ubuntu

echo "Remapping '$CONTAINER_USER' to UID=$HOST_UID, GID=$HOST_GID"

# Remap group ID
groupmod -g $HOST_GID $CONTAINER_USER 2>/dev/null || true

# Remap user ID
CURRENT_UID=$(id -u $CONTAINER_USER)
CURRENT_GID=$(id -g $CONTAINER_USER)
if [ "$CURRENT_UID" != "$HOST_UID" ] || [ "$CURRENT_GID" != "$HOST_GID" ]; then
    if ! usermod -u $HOST_UID -g $HOST_GID $CONTAINER_USER; then
        echo "Error: Failed to change UID/GID for $CONTAINER_USER to $HOST_UID/$HOST_GID" >&2
        exit 1
    fi
fi
# Fix home directory ownership
chown -R $HOST_UID:$HOST_GID /home/$CONTAINER_USER 2>/dev/null || true

# Fix workspace ownership if it exists
if [ -d "/workspaces" ]; then
    chown -R $HOST_UID:$HOST_GID /workspaces 2>/dev/null || true
fi

echo "Setup complete: $CONTAINER_USER (UID=$HOST_UID, GID=$HOST_GID)"

# Execute command as the remapped user
exec sudo -u $CONTAINER_USER --preserve-env=PATH "$@"
