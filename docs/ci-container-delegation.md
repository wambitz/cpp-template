# CI and Container Delegation

## How Script Delegation Works

All project scripts (`build.sh`, `test.sh`, `format.sh`, `lint.sh`, etc.) auto-delegate to Docker when run outside the container. The delegation logic in `scripts/docker/exec.sh` checks three conditions in order:

1. **Inside a container** (`/.dockerenv` exists) — run directly, no delegation
2. **CI environment** (`CI=true`) — run directly, tools provided by the runner
3. **Developer host** — delegate to Docker via `docker run --rm`

```
Developer host                    Container / CI runner
--------------                    ---------------------
./scripts/build.sh
  source env.sh
  source docker/exec.sh
  delegate_to_container
    /.dockerenv? No
    CI=true?     No
    docker run --rm ... build.sh  -->  ./scripts/build.sh
    exit $?                              delegate_to_container
                                           /.dockerenv? Yes
                                           return 0
                                         cmake / make / ...
                                      <-- exits
```

## Current CI Approach

The CI workflow installs tools directly on the GitHub Actions runner and skips Docker delegation:

```yaml
# .github/workflows/ci.yml
steps:
  - uses: actions/checkout@v4
  - name: Install deps
    run: >
      sudo apt-get update &&
      sudo apt-get install -y cmake clang-format clang-tidy
  - name: Format check
    run: ./scripts/format.sh --check
  - name: Build
    run: ./scripts/build.sh
  - name: Lint check
    run: ./scripts/lint.sh
  - name: Test
    run: ./scripts/test.sh
```

GitHub Actions sets `CI=true` automatically, so `delegate_to_container` returns immediately and scripts run directly on the runner. This is fast, requires no Docker setup, and works out-of-the-box for anyone who forks the template.

### Why not Docker in CI?

An earlier approach ran some CI steps directly on the host and others via Docker delegation. This caused path mismatches: `compile_commands.json` generated on the host contained runner paths (`/home/runner/work/...`), but `clang-tidy` ran inside a Docker container with different paths (`/workspaces/...`), causing crashes. The current approach avoids this by running everything in the same context.

## Alternative: GHCR Container Image

For production projects that require identical toolchains in CI and local development, you can publish the dev container image to GitHub Container Registry (GHCR) and use it as the CI job container.

GHCR is free for public repositories (unlimited storage and bandwidth).

### Setup

**1. Add a workflow to build and push the image** (`.github/workflows/docker-image.yml`):

```yaml
name: Docker Image
on:
  push:
    branches: [main]
    paths:
      - 'Dockerfile'
      - 'scripts/docker/entrypoint.sh'
      - '.github/workflows/docker-image.yml'
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/cpp-dev

jobs:
  build-and-push:
    runs-on: ubuntu-24.04
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          file: docker/Dockerfile
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
```

**2. Update the CI workflow** to use the published image:

```yaml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-24.04
    container:
      image: ghcr.io/${{ github.repository }}/cpp-dev:latest
    steps:
      - uses: actions/checkout@v4
      - name: Format check
        run: ./scripts/format.sh --check
      - name: Build
        run: ./scripts/build.sh
      - name: Lint check
        run: ./scripts/lint.sh
      - name: Test
        run: ./scripts/test.sh
```

### Why this works without code changes

When GitHub Actions runs a job with `container:`, it creates `/.dockerenv` inside the container. The first check in `delegate_to_container` detects this and skips delegation. The `CI=true` check is never reached, so both guards coexist without conflict.

### Trade-offs

| | apt-get (current) | GHCR container |
|---|---|---|
| CI speed | Fast | Fast (pre-built image) |
| Tool consistency | Runner versions (minor drift possible) | Identical to local dev |
| Fork setup | Zero — works immediately | Must trigger image build first |
| Maintenance | 1 workflow | 2 workflows |

### First-time setup for GHCR

1. Push the `docker-image.yml` workflow to `main`
2. Go to Actions tab and manually trigger "Docker Image" (`workflow_dispatch`)
3. Go to Packages tab and ensure the image visibility matches the repo (public/private)
4. Update `ci.yml` to use `container:` as shown above
5. Remove the `apt-get install` step (tools come from the image)
