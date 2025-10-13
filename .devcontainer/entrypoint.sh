#!/bin/bash
set -e

# Get host UID/GID from environment (defaults to 1000 if not set)
HOST_UID=${HOST_UID:-1000}
HOST_GID=${HOST_GID:-1000}

CONTAINER_USER=ubuntu

echo "Remapping '$CONTAINER_USER' to UID=$HOST_UID, GID=$HOST_GID"

# Remap group ID
groupmod -g $HOST_GID $CONTAINER_USER 2>/dev/null || true

# Remap user ID
usermod -u $HOST_UID -g $HOST_GID $CONTAINER_USER 2>/dev/null || true

# Fix home directory ownership
chown -R $HOST_UID:$HOST_GID /home/$CONTAINER_USER 2>/dev/null || true

# Fix workspace ownership if it exists
if [ -d "/workspaces" ]; then
    chown -R $HOST_UID:$HOST_GID /workspaces 2>/dev/null || true
fi

echo "Setup complete: $CONTAINER_USER (UID=$HOST_UID, GID=$HOST_GID)"

# Execute command as the remapped user
exec sudo -u $CONTAINER_USER --preserve-env=PATH "$@"
