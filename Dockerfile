# ---------- Build Stage ----------
FROM golang:1.24-bullseye AS builder

# Hardening flags for the Go build
ENV CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=arm64 \
    GOFLAGS="-buildmode=pie -trimpath -ldflags=-s -ldflags=-w"

WORKDIR /app

# Install necessary build tools
RUN apt-get update && apt-get install -y git ca-certificates && apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone cloudflared from Cloudflare's GitHub repository
RUN git clone https://github.com/cloudflare/cloudflared.git && \
    cd cloudflared && \
    git fetch --tags && \
    git checkout $(git describe --tags `git rev-list --tags --max-count=1`)

# Build cloudflared statically with hardening
WORKDIR /app/cloudflared
RUN go build -buildvcs=false -o /cloudflared ./cmd/cloudflared

# ---------- Runtime Stage ----------
FROM debian:bullseye-slim

# Install minimal CA certs and setcap utility
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libcap2-bin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the statically compiled cloudflared binary from the build stage
COPY --from=builder /cloudflared /usr/local/bin/cloudflared

# Create a non-root user to run the container securely
RUN useradd -r -s /usr/sbin/nologin cloudflared

# Switch to the non-root user
USER cloudflared

# The default command for the container
ENTRYPOINT ["cloudflared"]
CMD ["--help"]

