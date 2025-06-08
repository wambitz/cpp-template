# Debugging Guide (GDB)

> **Audience:** Developers working on this repository who want to step through the code with VS Code & GDB – regardless of whether they run locally, in a Dev Container, or by attaching to an already running container.
>
> **TL;DR matrix**
>
> | Scenario                      | Rec? | Pros                                                                                     | Cons / Gotchas                                                                                                                                                                                                             |
> | ----------------------------- | ---- | ---------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
> | **Native (host)**             | 🚫   | Fast startup if you already have tool‑chain                                              | *Path collisions* when the same code is built inside the container ⇒ you must `rm -rf build/` and re‑configure each time you switch. Pollutes host with build deps; easy to forget `SYS_PTRACE` flags when running Docker. |
> | **Dev Container**             | ✅    | Zero host pollution, extensions auto‑installed, paths identical, one‑click F5            | Needs Dev Containers extension; first launch slightly slower due to server copy                                                                                                                                            |
> | **Attach → In‑container GDB** | 🟡   | Works if Dev Container isn’t possible (e.g., remote CI box)                              | Must ensure C/C++ extension exists in `~/.vscode-server`; manual install otherwise                                                                                                                                         |
> | **Attach → `gdbserver`**      | 🟡   | Decouples build & run – good for prod‑like container that shouldn’t carry heavy dev deps | Requires `gdbserver` package inside image and `sourceFileMap` dance                                                                                                                                                        |

---

## 1  Native (host) – *not recommended*

```bash
# Host build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j$(nproc)
code .   # open VS Code in repo root
```

* If you later build **inside the container** the absolute paths embedded in `build/CMakeCache.txt` no longer match; CMake will complain and symbols won’t resolve. Delete the cache before each context‑switch:

```bash
rm -rf build/  # then rebuild in the other environment
```

* Host must have GDB & compilers; you’ll need to install them manually.

**Bottom line:** only useful for a quick edit when Docker isn’t available.

---

## 2  Dev Container – *preferred workflow*

1. Install the **Dev Containers** and **C/C++** extensions in your desktop VS Code.
2. Make sure the repo contains `.devcontainer/` with a `devcontainer.json` similar to:

```jsonc
{
  "name": "C++ DevContainer (Prebuilt)",
  "image": "cpp-dev:latest",  // <-- Replace with your real image tag (e.g. user/cpp-dev:1.0)

  "initializeCommand": "./scripts/build_image.sh",

  "updateRemoteUserUID": false,

  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.shell.linux": "bash",
        "editor.formatOnSave": true,
        "C_Cpp.clang_format_style": "file",
        "C_Cpp.default.cppStandard": "c++17"
      },
      "extensions": [
        "ms-vscode.cpptools",
        "ms-vscode.cmake-tools"
      ]
    }
  },

  "postStartCommand": "bash",

  "runArgs": [
    "--rm",
    "--hostname", "cpp-devcontainer",
    "--name", "cpp-devcontainer",
    "--env", "DISPLAY=${localEnv:DISPLAY}",
    "--volume", "/tmp/.X11-unix:/tmp/.X11-unix",
    "--gpus", "all"
    "--cap-add=SYS_PTRACE",
    "--security-opt", "seccomp=unconfined"
  ]
}
```

3. In VS Code → **F1 › Dev Containers: Reopen in Container**.
4. The first launch copies the VS Code server & listed extensions into the container. Subsequent opens are instant.
5. Use **`Debug in container`** from `.vscode/launch.json`:

```jsonc
{
  "name": "Debug in container",
  "type": "cppdbg",
  "request": "launch",
  "program": "${workspaceFolder}/build/src/main/main_exec",
  "cwd": "${workspaceFolder}",
  "stopAtEntry": true,
  "MIMode": "gdb",
  "miDebuggerPath": "/usr/bin/gdb"
}
```

Everything is path‑consistent, so no `sourceFileMap` is needed.

---

## 3  Attaching to a running container (when you can’t use Dev Container)

### 3.1   Plain GDB inside the container

1. **Run the container** (don’t forget `ptrace` perms):

    ```bash
    docker run --rm -it \
      --name "cpp-dev-gdbsrv" \
      --cap-add=SYS_PTRACE \
      --security-opt seccomp=unconfined \
      -p 2345:2345 \
      -v "${PWD}:/workspaces/cpp-project-template" \
      "cpp-dev:latest" 
    ```

2. **Build** *inside* the container so symbols match paths.
3. **Install VS Code extensions once** (only required for a fresh container):

   ```bash
   ~/.vscode-server/bin/<hash_id>/bin$ ./code-server --install-extension ms-vscode.cpptools # --force (optional)
   ```

   *Alternative:* click *Install in Container* from the VS Code UI.

4. Use `Debug main_exec` / `Debug unit_tests` configs:

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

5. **Persistence rule:** extensions live in the container filesystem. `docker stop/start` keeps them; `docker rm` wipes them unless you mounted a volume at `~/.vscode-server`.

### 3.2   `gdbserver` attach (decoupled build vs. run)

1. **Ensure `gdbserver` package is in the image** (Ubuntu example):

    ```dockerfile
    RUN apt-get update && apt-get install -y gdbserver && rm -rf /var/lib/apt/lists/*
    ```

2. **Run the container** and start the server:

    ```bash
    # inside the container
    /usr/bin/gdbserver :2345 /workspaces/cpp-project-template/build/src/main/main_exec
    ```

3. **Host‑side `launch.json`:**

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

4. **Why `sourceFileMap`?** The binary contains container paths; this map tells VS Code how to translate them to your host checkout so breakpoints resolve.

    *Tip:* mounting the project at the **same absolute path** inside and outside (`-v "$PWD":$PWD`) lets you drop `sourceFileMap` entirely.

---

## 4  Troubleshooting cheatsheet

| Symptom                                           | Fix                                                                                    |
| ------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Breakpoint is hollow gray                         | Rebuild with `-g -O0`; check that VS Code found the right file path (`DEBUG CONSOLE`). |
| `cppdbg: cannot find executable`                  | Path in `program` is wrong or build dir hasn’t been generated. Build first.            |
| “Configured debug type ‘cppdbg’ is not supported” | C/C++ extension missing on **remote side** – install via Dev Container or CLI.         |
| GDB fails `ptrace`                                | Run container with `--cap-add=SYS_PTRACE --security-opt seccomp=unconfined`.           |
| CMake cache mismatch when switching envs          | `rm -rf build/` and re‑configure in the current environment.                           |

---

### Appendix – Full sample `launch.json`

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
    { // NOTE: This needs gdbserver installed and running
      // See: docs/remote-debugging.md and scripts/launch_gdbserver.sh
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
