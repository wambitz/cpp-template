# C++ Project Template

A modern, production-ready template for C++ development.

| Capability      | Tool / Setup                           | Status |
| --------------- | -------------------------------------- | ------ |
| Build           | CMake ≥ 3.16 (default) · Bazel example | ✔      |
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
./scripts/fetch_googletest.sh        # optional, only if you need tests
cmake -S . -B build                  # -DENABLE_TESTS=OFF to skip tests
cmake --build build -j$(nproc)
./build/main_exec
ctest --test-dir build --output-on-failure   # if tests enabled
```

---

## Project layout

```
.
├── CMakeLists.txt           root build script
├── src/                     production code
│   ├── libstatic/           static-library example
│   ├── libshared/           shared-library example
│   ├── plugin_loader/       runtime loader
│   ├── plugin_impl/         sample plugin
│   └── main/                console application
├── tests/                   unit tests (GoogleTest)
├── external/                third-party code (empty by default)
├── scripts/                 helper scripts
├── docs/                    Doxygen config and output
└── .devcontainer/           VS Code container files
```

---

## Build options

### CMake

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
```

Key flags

| Flag                     | Effect                           |
| ------------------------ | -------------------------------- |
| `-DENABLE_TESTS=OFF`     | Skip GoogleTest and test targets |
| `-DBUILD_SHARED_LIBS=ON` | Build libraries as shared        |

### Bazel

```bash
cd bazel_workspace
bazel build //libmath:math
```

---

## Scripts

| Script                | Purpose                               |
| --------------------- | ------------------------------------- |
| `build.sh`            | Configure and compile (CMake)         |
| `run.sh`              | Launch Docker dev container           |
| `build_image.sh`      | Build the `cpp-dev:latest` image      |
| `format.sh`           | Run clang-format on sources           |
| `lint.sh`             | Run clang-tidy using compile commands |
| `docs.sh`             | Generate HTML docs                    |
| `fetch_googletest.sh` | Clone GoogleTest into `external/`     |

---

## Code quality

Install hooks once:

```bash
pip install --break-system-packages pre-commit
pre-commit install
```

On each commit clang-format rewrites staged files and clang-tidy analyses them.

---

## Documentation

```bash
./scripts/docs.sh
xdg-open docs/html/index.html
```

---

## Docker and DevContainer

Build image

```bash
./scripts/build_image.sh
```

Run interactive container

```bash
./scripts/run.sh
```

VS Code users can reopen the workspace in the container.

---

## Continuous integration (GitHub Actions)

```
on: [push, pull_request]

job: build
runs-on: ubuntu-24.04
steps:
  - uses: actions/checkout@v4
  - run: sudo apt-get update && sudo apt-get install -y cmake clang-format clang-tidy g++ doxygen
  - run: cmake -S . -B build -DENABLE_TESTS=ON
  - run: cmake --build build -j$(nproc)
  - run: ctest --test-dir build --output-on-failure
```

---

## Unit tests

Enable tests by fetching GoogleTest:

```bash
cmake -S . -B build -DENABLE_TESTS=ON
cmake --build build
ctest --test-dir build
```

Disable with `-DENABLE_TESTS=OFF`. This is the default
