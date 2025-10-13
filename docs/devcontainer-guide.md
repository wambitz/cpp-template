# DevContainer Configuration Guide

This project uses a **runtime UID/GID remapping** approach for maximum portability and simplicity.

## Overview

The Docker development environment automatically adapts to any user's UID/GID at runtime, eliminating permission issues and ensuring files created in the container have correct ownership on the host.

## How It Works

1. **Build Time**: 
   - Uses Ubuntu 24.04's built-in `ubuntu` user (UID/GID 1000 by default)
   - Installs development tools and configures sudo access
   - No user-specific configuration needed

2. **Runtime** (when container starts):
   - Entrypoint script receives your host UID/GID via environment variables
   - Remaps the `ubuntu` user to match your host user's UID/GID
   - Fixes ownership on home directory and workspace
   - Drops privileges and runs as remapped user

3. **Result**: 
   - All files created have correct ownership on your host system
   - Same image works for all users without rebuilding

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│ Docker Container                                        │
│                                                         │
│  Container Start (as root)                              │
│         ↓                                               │
│  entrypoint.sh receives HOST_UID/HOST_GID               │
│         ↓                                               │
│  Remaps ubuntu user: 1000 → your UID (e.g., 1000)       │
│         ↓                                               │
│  Drops to ubuntu user and runs command                  │
│         ↓                                               │
│  VS Code connects as: ubuntu (with your UID/GID)        │
└─────────────────────────────────────────────────────────┘
```

## Benefits

✅ **Simple** - Leverages Ubuntu 24.04's existing user (no custom user creation)  
✅ **Portable** - Same image works for all users regardless of their UID/GID  
✅ **Fast** - Minimal remapping operations, quick startup  
✅ **No rebuilds** - User changes don't require image rebuilds  
✅ **Team-friendly** - Share pre-built images via Docker registry  
✅ **CI/CD ready** - Works in any environment (local, cloud, CI pipelines)  
✅ **No conflicts** - Modifies existing user instead of creating conflicts  

## Files

### `.devcontainer/devcontainer.json`
VS Code DevContainer configuration:
- `containerUser: "root"` - Container starts as root (needed for remapping)
- `remoteUser: "ubuntu"` - VS Code connects as ubuntu user (after remapping)
- `containerEnv` - Passes `HOST_UID` and `HOST_GID` to entrypoint
- `initializeCommand` - Builds image before starting container

### `.devcontainer/entrypoint.sh`
Runtime UID/GID remapping script (26 lines):
- Receives HOST_UID and HOST_GID from environment
- Remaps ubuntu user/group to match host
- Fixes ownership on home directory and workspace
- Executes command as remapped user

### `Dockerfile`
Base image configuration:
- Installs C++ development tools
- Configures existing ubuntu user with sudo access
- Sets up colored bash prompt and aliases
- Copies and sets up entrypoint script

## Usage

### Using VS Code DevContainer (Recommended)

1. Open project in VS Code
2. Command Palette → "Dev Containers: Reopen in Container"
3. VS Code automatically:
   - Builds the image (if needed)
   - Starts container with your UID/GID
   - Connects you as ubuntu user with correct permissions

### Using Scripts Manually

**Build the image:**
```bash
./scripts/build_image.sh
```

**Run interactive container:**
```bash
./scripts/run.sh
```

**Check your identity inside container:**
```bash
docker run --rm \
  --env "HOST_UID=$(id -u)" \
  --env "HOST_GID=$(id -g)" \
  cpp-dev:latest id
```

### Example: Different Users, Same Image

```bash
# User 1 (UID 1000):
HOST_UID=1000 HOST_GID=1000 → ubuntu remapped to 1000:1000

# User 2 (UID 1001):
HOST_UID=1001 HOST_GID=1001 → ubuntu remapped to 1001:1001

# CI system (UID 5000):
HOST_UID=5000 HOST_GID=5000 → ubuntu remapped to 5000:5000
```

All using the **same Docker image** - no rebuilds needed!

## Testing

### Verify UID/GID Remapping

```bash
# Inside container, check your identity
id
# Expected: uid=1000(ubuntu) gid=1000(ubuntu) (or your actual UID/GID)
```

### Verify File Ownership

```bash
# Inside container
touch /workspaces/cpp-project-template/test_file
ls -la /workspaces/cpp-project-template/test_file
# Expected: owned by ubuntu inside container

# On host
ls -la test_file
# Expected: owned by your host user (e.g., jcastillo)
```

### Test with Different UID

```bash
docker run --rm \
  --env "HOST_UID=5555" \
  --env "HOST_GID=5555" \
  cpp-dev:latest id
# Expected: uid=5555(ubuntu) gid=5555(ubuntu)
```

## Troubleshooting

### Files have wrong ownership on host

**Symptom**: Files created in container are owned by root or wrong user on host

**Solution**: Ensure HOST_UID and HOST_GID are being passed correctly:
```bash
# Check environment variables in devcontainer.json
"containerEnv": {
  "HOST_UID": "${localEnv:UID}",
  "HOST_GID": "${localEnv:GID}"
}
```

### VS Code can't connect to container

**Symptom**: DevContainer fails to start or VS Code can't connect

**Solution**: 
1. Check that `remoteUser: "ubuntu"` is set in devcontainer.json
2. Check container logs: `docker logs cpp-dev-$(whoami)`
3. Verify entrypoint script is executable: `chmod +x .devcontainer/entrypoint.sh`

### Permission denied errors inside container

**Symptom**: Cannot write files or access directories

**Solution**:
1. Verify entrypoint ran successfully (check for "Setup complete" message)
2. Check workspace ownership: `ls -la /workspaces`
3. Rebuild image: `./scripts/build_image.sh`

### Container starts but user is still UID 1000

**Symptom**: Inside container, `id` shows UID 1000 when you expected different

**Solution**: Your host UID is probably 1000 (very common). The remapping worked correctly - ubuntu user already had UID 1000 so no change was needed.

## Advanced Configuration

### Custom GPU Support

Already configured in `runArgs`:
```json
"runArgs": ["--gpus", "all"]
```

### X11 Display Forwarding

Already configured for GUI applications:
```json
"runArgs": [
  "--env", "DISPLAY=${localEnv:DISPLAY}",
  "--volume", "/tmp/.X11-unix:/tmp/.X11-unix"
]
```

### Debug Tools (Optional)

Uncomment in devcontainer.json if needed:
```json
"runArgs": [
  "--cap-add=SYS_PTRACE",
  "--security-opt", "seccomp=unconfined"
]
```

## Ubuntu 22.04 Compatibility

This setup is designed for **Ubuntu 24.04**, which includes a built-in `ubuntu` user. If you need **Ubuntu 22.04** support:

**The Issue:** Ubuntu 22.04 base image does not include an `ubuntu` user.

**Solution:** Add user creation to the Dockerfile:

```dockerfile
FROM ubuntu:22.04

# Install packages...

# Create ubuntu user (doesn't exist in 22.04)
RUN groupadd --gid 1000 ubuntu \
    && useradd --uid 1000 --gid 1000 -m -s /bin/bash ubuntu \
    && echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu

# Rest of Dockerfile stays the same...
```

**No changes needed** to entrypoint or devcontainer.json - they work identically!

**Universal Approach** (supports both 22.04 and 24.04):
```dockerfile
# Create ubuntu user if it doesn't exist
RUN groupadd --gid 1000 ubuntu 2>/dev/null || true \
    && useradd --uid 1000 --gid 1000 -m -s /bin/bash ubuntu 2>/dev/null || true \
    && echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu
```

The `|| true` makes it work for both versions - creates user on 22.04, fails silently on 24.04.

## Comparison with Other Approaches

### Build-time UID/GID (Previous Approach)
```dockerfile
ARG USER_ID=1000
RUN useradd -u $USER_ID ...
```
- ❌ Image tied to specific user
- ❌ Requires rebuild for different users
- ❌ Not portable across teams
- ✅ Simple, no entrypoint needed

### Runtime Remapping (Current Approach)
```bash
# Entrypoint remaps at startup
usermod -u $HOST_UID ubuntu
```
- ✅ One image for all users
- ✅ No rebuilds needed
- ✅ Portable and shareable
- ⚠️ Slightly more complex entrypoint

### Why Runtime Remapping Wins

For a **project template** like this, portability is key. Users should be able to clone and use immediately without configuring build arguments or rebuilding images. The small complexity cost in the entrypoint is worth the massive gain in portability and user experience.

## References

- [VS Code DevContainer Specification](https://containers.dev/)
- [Docker User Namespaces](https://docs.docker.com/engine/security/userns-remap/)
- [Linux UID/GID Overview](https://www.linux.com/training-tutorials/understanding-linux-file-permissions/)

## Contributing

When modifying the DevContainer setup:

1. Test with different UIDs: `docker run --env HOST_UID=5000 ...`
2. Verify file ownership on host after creating files in container
3. Test VS Code connection: Reopen in Container
4. Update this documentation if behavior changes
