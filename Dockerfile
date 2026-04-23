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

ARG AGENT_BROWSER_HOME=/home/node

USER root

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        fonts-freefont-ttf \
        fonts-noto-cjk \
        fonts-noto-color-emoji \
        libasound2 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libatspi2.0-0 \
        ca-certificates \
        libcairo-gobject2 \
        libcairo2 \
        libcups2 \
        libdbus-1-3 \
        libdrm2 \
        libfontconfig1 \
        libfreetype6 \
        libgbm1 \
        libgdk-pixbuf-2.0-0 \
        libgtk-3-0 \
        curl \
        jq \
        libnspr4 \
        libnss3 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        pipx \
        ripgrep \
        libx11-6 \
        libx11-xcb1 \
        libxcb-shm0 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxkbcommon0 \
        libxrandr2 \
        libxrender1 \
        libxshmfence1 \
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
    && PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install uv \
    && rm -rf /var/lib/apt/lists/*

COPY --from=gobins /tmp/bin/blogwatcher /tmp/bin/gifgrep /tmp/bin/gog /tmp/bin/goplaces /tmp/bin/spogo /usr/local/bin/

RUN npm install -g --prefix /usr/local agent-browser mcporter summarize \
    && mkdir -p ${AGENT_BROWSER_HOME}/.cache \
    && HOME=${AGENT_BROWSER_HOME} XDG_CACHE_HOME=${AGENT_BROWSER_HOME}/.cache agent-browser install \
    && chown -R node:node ${AGENT_BROWSER_HOME}

USER node
