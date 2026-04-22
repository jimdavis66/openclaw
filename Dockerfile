# syntax=docker/dockerfile:1
# Extend the official gateway image with CLIs required by bundled OpenClaw skills.
# Bump OPENCLAW_BASE in compose build args when you upgrade the upstream tag.

ARG OPENCLAW_BASE=ghcr.io/openclaw/openclaw:latest

FROM cgr.dev/chainguard/go:latest-dev AS gobins
ENV GOTOOLCHAIN=auto \
    CGO_ENABLED=0 \
    GOBIN=/tmp/bin
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    mkdir -p "${GOBIN}" \
    && go install github.com/Hyaxia/blogwatcher/cmd/blogwatcher@latest \
    && go install github.com/steipete/gifgrep/cmd/gifgrep@latest \
    && go install github.com/steipete/goplaces/cmd/goplaces@latest \
    && go install github.com/steipete/spogo/cmd/spogo@latest \
    && go install github.com/steipete/gogcli/cmd/gog@latest

FROM ${OPENCLAW_BASE}

USER root

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        jq \
        pipx \
        vim-tiny \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install nano-pdf \
    && rm -rf /var/lib/apt/lists/*

COPY --from=gobins /tmp/bin/blogwatcher /tmp/bin/gifgrep /tmp/bin/gog /tmp/bin/goplaces /tmp/bin/spogo /usr/local/bin/

RUN npm install -g --prefix /usr/local mcporter summarize

USER node
