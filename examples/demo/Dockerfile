# Stage: 1
FROM ghcr.io/gleam-lang/gleam:v1.16.0-erlang AS builder

WORKDIR /app

# Copy manifest files for dependency caching
COPY gleam.toml manifest.toml ./
COPY src/ src/
COPY priv/ priv/

# Download dependencies
RUN gleam deps download

# Copy source code and build
RUN gleam build && gleam export erlang-shipment

# Stage 2
FROM ghcr.io/pnpm/pnpm:latest as builder-ui

RUN pnpm runtime set node 24 -g

WORKDIR /app

COPY package.json tsconfig.json vite.config.ts pnpm-lock.yaml ./
COPY priv/ priv
RUN pnpm install --frozen-lockfile && pnpm build

# Stage 3
FROM erlang:28-alpine

WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache libstdc++ openssl ncurses-libs

# Copy the Erlang release from builder
COPY --from=builder /app/build/erlang-shipment /app
COPY --from=builder-ui /app/priv/static /app/demo/priv/static

RUN cp /app/demo/priv/static/.vite/manifest.json /app/demo/priv/static/manifest.json && \
  rm -Rf /app/demo/priv/app && \
  adduser -D -H gleamuser

USER gleamuser

EXPOSE 4000

CMD ["/app/entrypoint.sh", "run"]
