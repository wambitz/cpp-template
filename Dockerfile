# -----------------------------------------------------------------------------
# Dev Dockerfile for cpp-project-template
# -----------------------------------------------------------------------------
# This image is intended for local development and testing. Source code is mounted.
# Uses runtime UID/GID remapping for portability across different hosts.
# Leverages Ubuntu 24.04's built-in 'ubuntu' user for simplicity.
# -----------------------------------------------------------------------------

FROM ubuntu:24.04

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# -----------------------------------------------------------------------------
# Install common C++ dev tools and utilities
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    sudo \
    build-essential \
    cmake \
    clang-format \
    clang-tidy \
    doxygen \
    git \
    wget \
    curl \
    lcov \
    gdb \
    valgrind \
    python3-pip \
    ca-certificates \
    tree \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# Create 'ubuntu' user if it doesn't exist (for Ubuntu 22.04 compatibility)
# 
# Ubuntu 24.04 already includes this user; Ubuntu 22.04 does not.
# UID/GID will be remapped at runtime by entrypoint.sh to match host.
#
# IMPORTANT: We hardcode 'ubuntu' to avoid UID conflicts:
# - Ubuntu base images already have an 'ubuntu' user at UID 1000
# - If we used a different username and tried to create it with UID 1000,
#   the 'useradd' command would fail due to UID conflict
# - Runtime remapping (via usermod) changes the numeric UID/GID, not the name
# - File permissions use numeric UIDs, so the username is just a label
# ------------------------------------------------------------------------------
RUN if ! id -u ubuntu > /dev/null 2>&1; then \
        useradd -m -s /bin/bash -u 1000 ubuntu; \
    fi

# ------------------------------------------------------------------------------
# Configure sudo access for ubuntu user
# ------------------------------------------------------------------------------
RUN echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu

# ------------------------------------------------------------------------------
# Enable colored terminal prompts (OPTIONAL - forces colors unconditionally)
#
# Without TERM=xterm-256color (set in run.sh and devcontainer.json), TERM
# defaults to "xterm" which lacks color support. Setting TERM=xterm-256color
# enables Ubuntu's .bashrc auto-detection to recognize and use colors.
#
# Uncommenting the line below forces colors unconditionally, bypassing detection.
# This ensures colors work even if TERM isn't properly set, or in non-interactive
# contexts. Safe for modern environments like Ubuntu 22.04/24.04.
#
# Only downside: may show escape codes on very old terminals without color support.
# ------------------------------------------------------------------------------
# RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /home/ubuntu/.bashrc

# -----------------------------------------------------------------------------
# Install pre-commit for code quality checks
# -----------------------------------------------------------------------------
RUN pip3 install --break-system-packages pre-commit cmake-format

# ------------------------------------------------------------------------------
# Copy entrypoint script
# ------------------------------------------------------------------------------
COPY scripts/docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# ------------------------------------------------------------------------------
# Set working directory
# ------------------------------------------------------------------------------
WORKDIR /workspaces

# ------------------------------------------------------------------------------
# Use entrypoint to handle UID/GID remapping at runtime
# ------------------------------------------------------------------------------
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
