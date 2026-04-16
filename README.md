# openclaw

Custom image built on top of the official OpenClaw gateway image (`ghcr.io/openclaw/openclaw`). It is meant to run in a homelab where the container lives on a **remote Docker host**: the agent and its skills execute **inside the container filesystem**, not on the machine you SSH from or the host’s OS. Anything a skill invokes by name (shell commands, subprocesses, `PATH` lookups) must therefore be **installed into this image** (or mounted in deliberately). This repo bakes in the CLIs that bundled OpenClaw skills expect so they work the same on a remote engine as they would on a local one.

## What this image adds

The [`Dockerfile`](Dockerfile) extends the upstream gateway image and installs tooling in standard locations (`/usr/local/bin`, global npm prefix `/usr/local`):

| Layer | Purpose |
| --- | --- |
| **Go build stage** (`cgr.dev/chainguard/go:latest-dev`) | Static binaries built with `CGO_ENABLED=0` and copied into the final image: `blogwatcher`, `gog` |
| **apt** | `ca-certificates`, `curl`, `pipx`, and **GitHub CLI** (`gh`) from GitHub’s official apt repo |
| **pipx** | **`nano-pdf`** — Python CLI installed with `PIPX_BIN_DIR=/usr/local/bin` so executables are on the default `PATH` for the runtime user |
| **npm** | **`mcporter`** installed globally under `/usr/local` |

Upstream base tag is parameterized as `OPENCLAW_BASE` (default `ghcr.io/openclaw/openclaw:latest`) so you can pin a digest or version when upgrading.

## Build locally

```bash
docker build -t openclaw-custom:local \
  --build-arg OPENCLAW_BASE=ghcr.io/openclaw/openclaw:latest \
  .
```

On a remote host, push or load this image there and reference it in your compose/stack so the running gateway uses this build instead of plain upstream.

## CI

[`.github/workflows/docker-weekly.yml`](.github/workflows/docker-weekly.yml) builds and pushes to GHCR on `main`, on a weekly schedule, and on `workflow_dispatch`, resolving upstream `latest` to a digest for reproducible builds and tagging with the upstream OCI version label when available.
