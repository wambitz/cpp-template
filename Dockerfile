# -----------------------------------------------------------------------------
# Dev Dockerfile for cpp-project-template
# -----------------------------------------------------------------------------
# This image is intended for local development and testing. Source code is mounted.
# -----------------------------------------------------------------------------

FROM ubuntu:24.04

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

ARG USERNAME=cppdev
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG PROJECT_NAME="cpp-project-template"

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
# Create user/group
# ------------------------------------------------------------------------------
RUN if [ -z "$(getent group $GROUP_ID)" ]; then \
        groupadd -g $GROUP_ID "$USERNAME"; \
    else \
        groupmod -n "$USERNAME" "$(getent group $GROUP_ID | cut -d: -f1)"; \
    fi && \
    if [ -z "$(getent passwd $USER_ID)" ]; then \
        useradd -m -u $USER_ID -g $GROUP_ID "$USERNAME"; \
    else \
        usermod -l "$USERNAME" -d /home/"$USERNAME" -m "$(getent passwd $USER_ID | cut -d: -f1)"; \
    fi

# ------------------------------------------------------------------------------
# Allow passwordless sudo
# ------------------------------------------------------------------------------
RUN echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ------------------------------------------------------------------------------
# Enable colored shell prompt
# ------------------------------------------------------------------------------
RUN sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/g' /home/$USERNAME/.bashrc

# -----------------------------------------------------------------------------
# Install pre-commit for code quality checks
# -----------------------------------------------------------------------------
RUN pip3 install --break-system-packages pre-commit

# ------------------------------------------------------------------------------
# Set project workspace directory
# ------------------------------------------------------------------------------
RUN mkdir -p /workspaces/$PROJECT_NAME && \
    chown -R $USERNAME:$USERNAME /workspaces

# ------------------------------------------------------------------------------
# Switch to dev user
# ------------------------------------------------------------------------------
USER $USERNAME
WORKDIR /workspaces/${PROJECT_NAME}

# ------------------------------------------------------------------------------
# Default shell
# ------------------------------------------------------------------------------
CMD ["/bin/bash"]
