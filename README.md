# openclaw

Custom image built on top of the official OpenClaw gateway image (`ghcr.io/openclaw/openclaw`). It is meant to run in a homelab where the container lives on a **remote Docker host**: the agent and its skills execute **inside the container filesystem**, not on the machine you SSH from or the host’s OS. Anything a skill invokes by name (shell commands, subprocesses, `PATH` lookups) must therefore be **installed into this image** (or mounted in deliberately). This repo bakes in the CLIs that bundled OpenClaw skills expect so they work the same on a remote engine as they would on a local one.

## What this image adds

The [`Dockerfile`](Dockerfile) extends the upstream gateway image and installs tooling in standard locations (`/usr/local/bin`, global npm prefix `/usr/local`):

| Layer | Purpose |
| --- | --- |
| **Go build stage** (`cgr.dev/chainguard/go:latest-dev`) | Static binaries built with `CGO_ENABLED=0` and copied into the final image: `blogwatcher`, `gifgrep`, `gog`, `goplaces`, `spogo` |
| **apt** | `ca-certificates`, `curl`, `jq`, browser runtime libraries/fonts for `agent-browser`, `pipx`, `ripgrep` for `rg`, `vim-tiny` for `vi`, and **GitHub CLI** (`gh`) from GitHub’s official apt repo |
| **pipx** | **`nano-pdf`** and **`uv`** — Python CLIs installed with `PIPX_BIN_DIR=/usr/local/bin` so executables are on the default `PATH` for the runtime user |
| **npm** | **`agent-browser`**, **`mcporter`**, and **`summarize`** installed globally under `/usr/local`; the image build also runs `agent-browser install` so Chrome is preloaded in-container |

Upstream base tag is parameterized as `OPENCLAW_BASE` (default `ghcr.io/openclaw/openclaw:latest`) so you can pin a digest or version when upgrading.

## Build locally

```bash
docker build -t openclaw-custom:local \
  --build-arg OPENCLAW_BASE=ghcr.io/openclaw/openclaw:latest \
  .
```

On a remote host, push or load this image there and reference it in your compose/stack so the running gateway uses this build instead of plain upstream.

## spogo auth on remote/browser-separated setups

If Chrome runs on a different host, `spogo auth import --browser chrome` cannot read that browser profile directly from inside this container. Also, `spogo auth paste` may fail with `unexpected argument paste` in current builds.

Use a manual cookie file instead:

1. Grab `sp_dc` (required) and `sp_t` (recommended) from `https://open.spotify.com` cookies in your external browser.
2. Write `spogo` config:

```toml
default_profile = "default"

[profile.default]
engine = "connect"
cookie_path = "/home/node/.config/spogo/cookies/default.json"
```

3. Write cookie JSON at `/home/node/.config/spogo/cookies/default.json`:

```json
[
  {
    "name": "sp_dc",
    "value": "YOUR_SP_DC",
    "domain": ".spotify.com",
    "path": "/",
    "secure": true,
    "http_only": true
  },
  {
    "name": "sp_t",
    "value": "YOUR_SP_T",
    "domain": ".spotify.com",
    "path": "/",
    "secure": true,
    "http_only": true
  }
]
```

4. Lock down permissions and verify:

```bash
mkdir -p /home/node/.config/spogo/cookies
chmod 700 /home/node/.config/spogo /home/node/.config/spogo/cookies
chmod 600 /home/node/.config/spogo/cookies/default.json
spogo auth status
```

### Troubleshooting

- `missing sp_t`: add the `sp_t` cookie value from your browser and re-run `spogo auth status`.
- Auth still fails with valid cookies: make sure `domain` is `.spotify.com` and `path` is `/` in `default.json`.
- Worked before, broken now: Spotify session cookies can expire; refresh cookies in your browser and replace values in `default.json`.

## CI

[`.github/workflows/docker-weekly.yml`](.github/workflows/docker-weekly.yml) builds and pushes to GHCR on `main`, on a weekly schedule, and on `workflow_dispatch`, resolving upstream `latest` to a digest for reproducible builds and tagging with the upstream OCI version label when available.
