# GDB Debugging Guide

This guide covers GDB debugging workflows for local, DevContainer, and remote container environments.

## Debugging Approaches

| Approach                      | Recommended | Advantages                                                                      | Limitations                                                                                                                                    |
| ----------------------------- | ----------- | ------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| Native (host)                 | No          | Fast startup with existing toolchain                                            | Path conflicts when switching between host and container builds require clean rebuilds; pollutes host with build dependencies                  |
| Dev Container                 | Yes         | Isolated environment, automated extension installation, consistent paths        | Requires Dev Containers extension; initial launch includes server installation overhead                                                        |
| Attach with container GDB     | Conditional | Applicable when DevContainer is unavailable (e.g., remote CI)                   | Requires C/C++ extension in ~/.vscode-server; manual installation may be necessary                                                           |
| Attach with gdbserver         | Conditional | Separates build and runtime environments; suitable for production-like containers | Requires gdbserver package; needs sourceFileMap configuration for path translation                                                         |

## Native Host Debugging

Build on host system:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j$(nproc)
code .
```

**Path Conflict Issue**: Building in both host and container environments creates path inconsistencies in build/CMakeCache.txt. When switching environments, remove the build cache:

```bash
rm -rf build/
```

**Requirements**: Host system must have GDB and compiler toolchain installed.

**Use Case**: Quick edits when Docker is unavailable. Not recommended for regular development.

## DevContainer Debugging

### Prerequisites

1. Install Dev Containers extension in VS Code
2. Install C/C++ extension in VS Code
3. Verify .devcontainer/devcontainer.json configuration

### Workflow

1. Execute: Dev Containers: Reopen in Container
2. First launch installs VS Code server and extensions into container
3. Subsequent launches connect immediately
4. Use debug configuration from .vscode/launch.json

Path consistency between host and container eliminates the need for sourceFileMap configuration.

## Container Attach Debugging

### Method 1: In-Container GDB

Start container with ptrace capabilities:

```bash
docker run --rm -it \
  --name "cpp-dev-gdbsrv" \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  -p 2345:2345 \
  -v "${PWD}:/workspaces/cpp-project-template" \
  "cpp-dev:latest"
```

Build project inside container to ensure symbol path consistency.

Install VS Code extensions (required once per container):

```bash
~/.vscode-server/bin/<hash>/bin/code-server --install-extension ms-vscode.cpptools
```

Alternatively, use the VS Code UI to install extensions in the container.

Debug configuration:

```jsonc
{
  "name": "Debug main_exec",
  "type": "cppdbg",
  "request": "launch",
  "program": "${workspaceFolder}/build/src/main/main_exec",
  "stopAtEntry": true,
  "cwd": "${workspaceFolder}/build/src/main",
  "MIMode": "gdb",
  "miDebuggerPath": "/usr/bin/gdb"
}
```

**Extension Persistence**: Extensions persist across container stop/start cycles but are removed when the container is deleted. Mount a volume at ~/.vscode-server for persistence across container recreation.

### Method 2: gdbserver Attach

Install gdbserver in container image:

```dockerfile
RUN apt-get update && apt-get install -y gdbserver && rm -rf /var/lib/apt/lists/*
```

Start gdbserver in container:

```bash
/usr/bin/gdbserver :2345 /workspaces/cpp-project-template/build/src/main/main_exec
```

Host-side launch configuration:

```jsonc
{
  "name": "Attach to gdbserver in container",
  "type": "cppdbg",
  "request": "launch",
  "program": "${workspaceFolder}/build/src/main/main_exec",
  "miDebuggerServerAddress": "localhost:2345",
  "MIMode": "gdb",
  "stopAtEntry": true,
  "sourceFileMap": {
    "/workspaces/cpp-project-template": "${workspaceFolder}"
  },
  "cwd": "${workspaceFolder}"
}
```

**Path Translation**: The sourceFileMap translates container paths to host paths for breakpoint resolution. If the project is mounted at identical paths in both environments, this mapping can be omitted.

## Troubleshooting

| Symptom                                    | Resolution                                                                                        |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------- |
| Breakpoint appears as hollow circle        | Rebuild with -g -O0; verify file path in DEBUG CONSOLE                                          |
| cppdbg: cannot find executable           | Verify program path in launch configuration; ensure build directory exists                      |
| Configured debug type 'cppdbg' not supported | Install C/C++ extension on remote side via DevContainer or CLI                                    |
| GDB ptrace operation fails                 | Start container with --cap-add=SYS_PTRACE --security-opt seccomp=unconfined                     |
| CMake cache mismatch between environments  | Execute rm -rf build/ and reconfigure in current environment                                    |

## Launch Configuration Reference

```jsonc
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug main_exec",
      "type": "cppdbg",
      "request": "launch",
      "program": "${workspaceFolder}/build/src/main/main_exec",
      "args": [],
      "stopAtEntry": true,
      "cwd": "${workspaceFolder}/build/src/main",
      "MIMode": "gdb",
      "miDebuggerPath": "/usr/bin/gdb",
      "externalConsole": false
    },
    {
      "name": "Debug unit_tests",
      "type": "cppdbg",
      "request": "launch",
      "program": "${workspaceFolder}/build/tests/unit_tests",
      "args": [],
      "stopAtEntry": true,
      "cwd": "${workspaceFolder}/build/tests",
      "MIMode": "gdb",
      "miDebuggerPath": "/usr/bin/gdb",
      "externalConsole": false
    },
    {
      "name": "Attach to gdbserver in container",
      "type": "cppdbg",
      "request": "launch",
      "program": "${workspaceFolder}/build/src/main/main_exec",
      "miDebuggerServerAddress": "localhost:2345",
      "MIMode": "gdb",
      "stopAtEntry": true,
      "sourceFileMap": {
        "/workspaces/cpp-project-template": "${workspaceFolder}"
      },
      "cwd": "${workspaceFolder}"
    }
  ]
}
```
