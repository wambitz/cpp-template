# C++ Project Template

A modern, production-ready template for C++ development.

| Capability      | Tool / Setup                           | Status |
| --------------- | -------------------------------------- | ------ |
| Build           | CMake ≥ 3.20                           | ✔      |
| Unit tests      | GoogleTest (optional)                  | ✔      |
| Formatting      | clang-format (pre-commit)              | ✔      |
| Linting         | clang-tidy (pre-commit)                | ✔      |
| Docs            | Doxygen                                | ✔      |
| Dev environment | Docker image, VS Code DevContainer     | ✔      |
| CI              | GitHub Actions (Ubuntu 24.04)          | ✔      |

---

## Quick start

```bash
git clone <your-fork> my_project && cd my_project

# Install pre-commit hooks (for code quality checks on push)
pre-commit install --hook-type pre-push

cmake -S . -B build                  # -DENABLE_UNIT_TESTS=OFF to skip tests
cmake --build build -j$(nproc)
./build/bin/main_exec
ctest --test-dir build --output-on-failure   # if tests enabled
```

---

## Project layout

```
.
├── CMakeLists.txt           root build script
├── src/                     production code
│   ├── example_public_private/ PUBLIC vs PRIVATE visibility (see README)
│   ├── example_interface/   INTERFACE library (header-only)
│   ├── example_static/      static library example (.a)
│   ├── example_shared/      shared library example (.so + RPATH)
│   ├── example_plugin_loader/ runtime plugin loader (dlopen)
│   ├── example_plugin_impl/ sample plugin implementation
│   └── main/                console application
├── tests/                   unit tests (GoogleTest)
├── external/                third-party code (empty by default)
├── scripts/                 helper scripts
├── docs/                    documentation (Doxygen, guides)
└── .devcontainer/           VS Code container files
```

### Documentation

- **PUBLIC/PRIVATE visibility**: See [docs/public-private-guide.md](docs/public-private-guide.md)
- **RPATH configuration**: See [docs/rpath-guide.md](docs/rpath-guide.md)
- **DevContainer setup**: See [docs/devcontainer-guide.md](docs/devcontainer-guide.md)

---

## Build options

### CMake

```bash
# Development build (Debug, with debug symbols)
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug

# Release build (optimized, for packaging)
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
```

**Key flags**:

| Flag                     | Effect                           |
| ------------------------ | -------------------------------- |
| `-DENABLE_UNIT_TESTS=OFF` | Skip GoogleTest and test targets |
| `-DENABLE_COVERAGE=ON`   | Enable code coverage with gcov   |
| `-DBUILD_SHARED_LIBS=ON` | Build libraries as shared        |

### Library Dependencies and RPATH

This project uses **RPATH** (Runtime Path) for portable library discovery:

```
your-package/
├── bin/
│   └── main_exec                      ← RPATH: $ORIGIN/../lib
└── lib/
    ├── libexample_shared.so           ← Found automatically
    └── libexample_plugin_impl.so      ← Found by dlopen()
```

**Key Benefits:**
- **Self-contained packages** - work anywhere without installation
- **No environment setup** - no `LD_LIBRARY_PATH` needed
- **Plugin discovery** - `dlopen()` finds plugins via RPATH
- **Clean code** - no hardcoded paths

**For detailed RPATH explanation, examples, and troubleshooting, see [docs/rpath-guide.md](docs/rpath-guide.md)**

---

## Scripts

### Build and Development

| Script        | Purpose                                              |
| ------------- | ---------------------------------------------------- |
| `build.sh`    | Configure and compile (Debug mode)                   |
| `package.sh`  | Build and create distributable packages (Release)    |
| `coverage.sh` | Build with coverage, run tests, generate report      |
| `format.sh`   | Run clang-format on sources (use --check for CI)     |
| `lint.sh`     | Run clang-tidy using compile commands                |
| `docs.sh`     | Generate HTML docs                                   |

**Build vs Package:**
- `./scripts/build.sh` — Debug build for development (fast compilation, debug symbols)
- `./scripts/package.sh` — Release build + CPack packaging (optimized, distributable)

### Docker

Docker-related scripts live under `scripts/docker/`:

| Script           | Purpose                                           |
| ---------------- | ------------------------------------------------- |
| `build_image.sh` | Build the `cpp-dev:latest` image                  |
| `run.sh`         | Run the dev container with UID/GID remap          |
| `attach.sh`      | Attach to running container as `ubuntu`           |

---

## Code quality

### Pre-push Hooks

Install hooks once (runs on `git push`, not commit):

```bash
pre-commit install --hook-type pre-push
```

Before each push, pre-commit will:
- Run `clang-format` to check code formatting
- Run `clang-tidy` to analyze code quality

These checks ensure consistent code style across the team.

**VS Code DevContainer users:** Hooks are installed automatically via `postCreateCommand`.

---

## API Documentation (Doxygen)

Generate HTML documentation from code comments:

```bash
./scripts/docs.sh
xdg-open docs/html/index.html
```

---

## Docker and DevContainer

This project uses a **portable Docker image** with runtime UID/GID remapping. The same image works for all users without rebuilding.

Build image

```bash
./scripts/docker/build_image.sh
```

Run interactive container

```bash
./scripts/docker/run.sh
```

Attach to the running container

```bash
./scripts/docker/attach.sh
```

This attaches as user `ubuntu` (with remapped UID/GID). If the container isn't running, the script will fail—start it first with `./scripts/docker/run.sh`.

**Customize attach behavior:**

To attach as root (for system administration):
```bash
docker exec -it -u root cpp-dev-${USER} bash
```

To attach with your host UID/GID directly:
```bash
docker exec -it -u "$(id -u):$(id -g)" cpp-dev-${USER} bash
```

**VS Code DevContainer:**

VS Code users can reopen the workspace in the container. The Dev Container uses the prebuilt `cpp-dev:latest` image and relies on a runtime entrypoint to remap UID/GID (no extra `vsc-…-uid` image is created).

**For detailed information about the DevContainer setup, see [docs/devcontainer-guide.md](docs/devcontainer-guide.md)**

---

## Continuous integration (GitHub Actions)

The CI pipeline runs on every push and pull request:

```yaml
on: [push, pull_request]
runs-on: ubuntu-24.04

steps:
  - Install dependencies (cmake, clang-format)
  - Build project with CMake
  - Run all unit tests with ctest
```

See [.github/workflows/ci.yml](.github/workflows/ci.yml) for the complete configuration.

---

## Unit tests

Unit tests are **enabled by default** using GoogleTest (fetched automatically via CMake FetchContent).

```bash
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
```

To disable tests:
```bash
cmake -S . -B build -DENABLE_UNIT_TESTS=OFF
```
