# C++ Project Template

A modern, production-ready template for C++ development. All build and quality scripts run inside Docker automatically — no local toolchain required.

| Capability      | Tool / Setup                           | Status |
| --------------- | -------------------------------------- | ------ |
| Build           | CMake >= 3.20, C++17                   | ✔      |
| Unit tests      | GoogleTest v1.14.0 (FetchContent)      | ✔      |
| Formatting      | clang-format (pre-push hook)           | ✔      |
| Linting         | clang-tidy (pre-push hook)             | ✔      |
| Coverage        | lcov / gcov                            | ✔      |
| Docs            | Doxygen                                | ✔      |
| Dev environment | Docker + VS Code DevContainer          | ✔      |
| CI              | GitHub Actions (Ubuntu 24.04)          | ✔      |

---

## Quick start

```bash
git clone <your-fork> my_project && cd my_project

# Build the Docker image (one-time)
./scripts/docker/build_image.sh

# Install git hooks (runs format + lint checks on push)
./scripts/install-hooks.sh

# Build, test, done — scripts auto-delegate to Docker
./scripts/build.sh
./scripts/test.sh
```

Every script in `scripts/` auto-delegates to Docker when run from the host. You don't need CMake, clang-format, or any other tool installed locally — just Docker. See [docs/ci-container-delegation.md](docs/ci-container-delegation.md) for details.

---

## Project layout

```
.
├── CMakeLists.txt              root build script
├── Dockerfile                  dev container image
├── src/                        production code
│   ├── example_static/         static library (.a)
│   ├── example_shared/         shared library (.so + RPATH)
│   ├── example_interface/      header-only (INTERFACE) library
│   ├── example_public_private/ PUBLIC vs PRIVATE visibility demo
│   ├── example_plugin_loader/  runtime plugin loader (dlopen)
│   ├── example_plugin_impl/    sample plugin implementation
│   └── main/                   console application
├── tests/                      unit tests (GoogleTest)
├── scripts/                    build, test, format, lint, coverage, docs
│   └── docker/                 container management (build, run, attach, exec)
├── .githooks/                  git hooks (pre-push: format + lint)
├── .devcontainer/              VS Code DevContainer config
├── cmake/                      extra CMake modules
├── docs/                       documentation and guides
└── external/                   third-party code (empty by default)
```

### Documentation

- **PUBLIC/PRIVATE visibility**: [docs/public-private-guide.md](docs/public-private-guide.md)
- **RPATH configuration**: [docs/rpath-guide.md](docs/rpath-guide.md)
- **DevContainer setup**: [docs/devcontainer-guide.md](docs/devcontainer-guide.md)
- **CI and container delegation**: [docs/ci-container-delegation.md](docs/ci-container-delegation.md)
- **Remote debugging**: [docs/remote-debugging.md](docs/remote-debugging.md)

---

## Scripts

All scripts auto-delegate to Docker when run on the host. Inside the container or CI (`CI=true`), they run directly.

### Build and Development

| Script               | Purpose                                           |
| -------------------- | ------------------------------------------------- |
| `build.sh`           | Debug build with tests enabled                    |
| `test.sh`            | Run all tests                                     |
| `package.sh`         | Release build + CPack packaging                   |
| `coverage.sh`        | Build with coverage, run tests, generate report   |
| `format.sh`          | Apply clang-format (`--check` for CI mode)        |
| `lint.sh`            | Run clang-tidy (build first for compile_commands)  |
| `docs.sh`            | Generate Doxygen HTML documentation               |
| `install-hooks.sh`   | Set `core.hooksPath` to `.githooks/`              |

### Docker

| Script                      | Purpose                                    |
| --------------------------- | ------------------------------------------ |
| `docker/build_image.sh`     | Build the `cpp-dev:latest` image           |
| `docker/run.sh`             | Run the dev container with UID/GID remap   |
| `docker/attach.sh`          | Attach to running container as `ubuntu`    |

---

## Build options

The build scripts handle CMake configuration automatically. If you need to customize, these are the key CMake flags:

| Flag                     | Effect                           |
| ------------------------ | -------------------------------- |
| `-DENABLE_UNIT_TESTS=OFF` | Skip GoogleTest and test targets |
| `-DENABLE_COVERAGE=ON`   | Enable code coverage with gcov   |
| `-DBUILD_SHARED_LIBS=ON` | Build libraries as shared        |

### RPATH

Shared libraries and plugins use RPATH (`$ORIGIN/../lib`) for portable discovery — no `LD_LIBRARY_PATH` needed:

```
your-package/
├── bin/
│   └── main_exec                      ← RPATH: $ORIGIN/../lib
└── lib/
    ├── libexample_shared.so           ← found automatically
    └── libexample_plugin_impl.so      ← found by dlopen()
```

See [docs/rpath-guide.md](docs/rpath-guide.md) for details.

---

## Code quality

### Pre-push hooks

Git hooks live in `.githooks/` (version-controlled). Install once after cloning:

```bash
./scripts/install-hooks.sh
```

Before each push, the hook runs format and lint checks — delegating to Docker automatically. Clang-tidy requires `compile_commands.json` from a prior build; if missing, the hook skips lint and warns (format still runs).

---

## Docker and DevContainer

Build the image (one-time):

```bash
./scripts/docker/build_image.sh
```

Run an interactive container:

```bash
./scripts/docker/run.sh
```

Attach to a running container:

```bash
./scripts/docker/attach.sh
```

**VS Code DevContainer:** Reopen the workspace in the container via the Dev Containers extension. It uses the prebuilt `cpp-dev:latest` image with runtime UID/GID remapping. See [docs/devcontainer-guide.md](docs/devcontainer-guide.md).

---

## Continuous integration (GitHub Actions)

The CI pipeline runs on every push and pull request using the same project scripts:

```yaml
steps:
  - Install dependencies (cmake, clang-format, clang-tidy)
  - Format check (./scripts/format.sh --check)
  - Build (./scripts/build.sh)
  - Lint check (./scripts/lint.sh)
  - Test (./scripts/test.sh)
```

GitHub Actions sets `CI=true`, so scripts skip Docker delegation and run directly on the runner. See [docs/ci-container-delegation.md](docs/ci-container-delegation.md) for a GHCR upgrade path.

See [.github/workflows/ci.yml](.github/workflows/ci.yml) for the complete configuration.
