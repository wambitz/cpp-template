# DevContainer Configuration Guide

This project implements runtime UID/GID remapping to ensure portability across different development environments.

## Overview

The Docker development environment dynamically adapts to user-specific UID/GID values at container startup, eliminating file ownership conflicts between the container and host filesystem.

## Mechanism

### Build Time

The container image uses Ubuntu 24.04's default `ubuntu` user (UID/GID 1000). Development tools and sudo privileges are configured during image build. No user-specific configuration is required at this stage.

### Runtime

When the container starts:

1. The entrypoint script receives host UID/GID values via environment variables
2. The `ubuntu` user is remapped to match the host user's UID/GID
3. Home directory and workspace ownership are updated
4. Execution proceeds as the remapped user

### Result

Files created within the container maintain correct ownership on the host filesystem. A single container image supports multiple users without rebuilding.

## Architecture

```
Container Lifecycle:

1. Container starts as root
2. entrypoint.sh receives HOST_UID/HOST_GID
3. ubuntu user remapped (1000 → host UID)
4. Ownership updated on home directory and workspace
5. Execution switches to remapped ubuntu user
6. VS Code connects as ubuntu (with host UID/GID)
```

## Advantages

- **Portability**: Single image supports multiple users with different UID/GID values
- **No Rebuilds**: User changes do not require image reconstruction
- **Performance**: Minimal overhead during container initialization
- **Distribution**: Pre-built images can be shared via container registry
- **CI/CD Integration**: Functions consistently across local, cloud, and pipeline environments
- **Conflict Avoidance**: Modifies existing user rather than creating new user entries  

## Configuration Files

### `.devcontainer/devcontainer.json`

Primary DevContainer configuration file:

- `containerUser: "root"` - Initial container user (required for UID/GID remapping)
- `remoteUser: "ubuntu"` - User context for VS Code connection (post-remapping)
- `containerEnv` - Environment variables passing host UID/GID to entrypoint
- `initializeCommand` - Pre-startup image build command

### `scripts/entrypoint.sh`

Runtime remapping script:

- Reads `HOST_UID` and `HOST_GID` from environment
- Modifies ubuntu user/group to match host values
- Updates file ownership on home directory and workspace
- Executes container command as remapped user

### `Dockerfile`

Container image definition:

- Base image: Ubuntu 24.04
- Development toolchain installation
- sudo configuration for ubuntu user
- Entrypoint script integration

## Usage

### VS Code DevContainer

1. Open project directory in VS Code
2. Execute command: "Dev Containers: Reopen in Container"
3. VS Code performs the following operations:
   - Builds container image if not present
   - Starts container with host UID/GID environment variables
   - Establishes connection as ubuntu user with remapped credentials

### Manual Container Operations

Build the container image:
```bash
./scripts/build_image.sh
```

Start interactive container session:
```bash
./scripts/run.sh
```

Verify identity remapping:
```bash
docker run --rm \
  --env "HOST_UID=$(id -u)" \
  --env "HOST_GID=$(id -g)" \
  cpp-dev:latest id
```

### Multi-User Scenario

The same container image supports different user contexts:

```bash
# Developer A (UID 1000)
HOST_UID=1000 HOST_GID=1000 → ubuntu remapped to 1000:1000

# Developer B (UID 1001)
HOST_UID=1001 HOST_GID=1001 → ubuntu remapped to 1001:1001

# CI Environment (UID 5000)
HOST_UID=5000 HOST_GID=5000 → ubuntu remapped to 5000:5000
```

No image rebuilds required for different user contexts.

## Verification

### UID/GID Remapping

Execute within container:
```bash
id
```

Expected output: `uid=<host_uid>(ubuntu) gid=<host_gid>(ubuntu)`

### File Ownership

Create test file within container:
```bash
touch /workspaces/cpp-project-template/test_file
ls -la /workspaces/cpp-project-template/test_file
```

Expected: File owned by ubuntu user in container

Verify on host:
```bash
ls -la test_file
```

Expected: File owned by host user

### Custom UID Test

```bash
docker run --rm \
  --env "HOST_UID=5555" \
  --env "HOST_GID=5555" \
  cpp-dev:latest id
```

Expected output: `uid=5555(ubuntu) gid=5555(ubuntu)`

## Troubleshooting

### Incorrect File Ownership

**Symptom**: Files created in container have incorrect ownership on host

**Diagnosis**: Verify environment variable configuration in `.devcontainer/devcontainer.json`:

```json
"containerEnv": {
  "HOST_UID": "${localEnv:UID}",
  "HOST_GID": "${localEnv:GID}"
}
```

### DevContainer Connection Failure

**Symptom**: Container fails to start or VS Code cannot establish connection

**Resolution**:
1. Verify `remoteUser: "ubuntu"` in devcontainer.json
2. Inspect container logs: `docker logs cpp-dev-$(whoami)`
3. Confirm entrypoint script permissions: `chmod +x scripts/entrypoint.sh`

### Permission Errors

**Symptom**: Write operations fail within container

**Resolution**:
1. Verify entrypoint script execution completed successfully
2. Inspect workspace ownership: `ls -la /workspaces`
3. Rebuild container image: `./scripts/build_image.sh`

### UID Remains at Default Value

**Symptom**: Container user displays UID 1000 regardless of host UID

**Explanation**: If host UID is 1000, no remapping is necessary. The ubuntu user's default UID matches the host, so the remapping operation is a no-op.

## Advanced Configuration

### GPU Access

GPU support is configured via `runArgs`:
```json
"runArgs": ["--gpus", "all"]
```

### X11 Display Forwarding

GUI application support is enabled through:
```json
"runArgs": [
  "--env", "DISPLAY=${localEnv:DISPLAY}",
  "--volume", "/tmp/.X11-unix:/tmp/.X11-unix"
]
```

### Debugging Capabilities

For debugging operations requiring ptrace, uncomment in devcontainer.json:
```json
"runArgs": [
  "--cap-add=SYS_PTRACE",
  "--security-opt", "seccomp=unconfined"
]
```

## Ubuntu 22.04 Compatibility

This configuration targets Ubuntu 24.04, which includes a pre-configured `ubuntu` user. For Ubuntu 22.04 support, user creation must be added to the Dockerfile.

Ubuntu 22.04 does not include an `ubuntu` user by default. Add the following to the Dockerfile:

```dockerfile
FROM ubuntu:22.04

# Create ubuntu user
RUN groupadd --gid 1000 ubuntu \
    && useradd --uid 1000 --gid 1000 -m -s /bin/bash ubuntu \
    && echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu
```

The entrypoint script and devcontainer.json require no modifications.

### Cross-Version Compatibility

For a Dockerfile supporting both Ubuntu 22.04 and 24.04:

```dockerfile
RUN getent group ubuntu || groupadd --gid 1000 ubuntu \
    && id ubuntu || useradd --uid 1000 --gid 1000 -m -s /bin/bash ubuntu \
    && echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu
```

This approach creates the user on 22.04 and exits gracefully on 24.04 where the user already exists.

## Alternative Approaches

### Build-Time UID/GID Configuration

```dockerfile
ARG USER_ID=1000
RUN useradd -u $USER_ID ...
```

Characteristics:
- Image specific to individual user
- Requires rebuild for different users
- Limited portability across development teams
- Simpler implementation without runtime entrypoint

### Runtime UID/GID Remapping (Current Implementation)

```bash
usermod -u $HOST_UID ubuntu
```

Characteristics:
- Single image supports multiple users
- No rebuild required for user changes
- Portable across teams and environments
- Additional complexity in entrypoint script

### Rationale

For a multi-user project template, portability and ease of use are prioritized over implementation simplicity. Runtime remapping enables immediate use after repository cloning without build configuration or image rebuilds.

## References

- [VS Code DevContainer Specification](https://containers.dev/)
- [Docker User Namespaces](https://docs.docker.com/engine/security/userns-remap/)
- [Linux File Permissions](https://www.linux.com/training-tutorials/understanding-linux-file-permissions/)

## Modification Guidelines

When updating the DevContainer configuration:

1. Test with multiple UID values
2. Verify file ownership consistency between container and host
3. Confirm VS Code connectivity
4. Update documentation to reflect behavioral changes
