FROM lukemathwalker/cargo-chef:latest-rust-1.72.0 as chef
WORKDIR /app
RUN apt update && apt install lld clang -y

FROM chef as planner
COPY . .
# get a lock file
RUN cargo chef prepare --recipe-path recipe.json

FROM chef as builder
# build our dependencies if they stay the same they will be cached. 
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

COPY . .
# use cached query data
ENV SQLX_OFFLINE true
# release for speed
RUN cargo build --release --bin zero2prod

FROM debian:bookworm-slim AS runtime
WORKDIR /app
# Install OpenSSL - it is dynamically linked by some of our dependencies
# Install ca-certificates - it is needed to verify TLS certificates
# when establishing HTTPS connections
RUN apt-get update -y \
        && apt-get install -y --no-install-recommends openssl ca-certificates \
        # clean
        && apt-get autoremove -y \
        && apt-get clean -y \
        && rm -rf /var/lib/apt/lists/*
# copy the compiled binary from the builder stage
COPY --from=builder /app/target/release/zero2prod zero2prod
COPY configuration configuration
ENV APP_ENVIRONMENT production
# when we run the container, we want to run the binary
ENTRYPOINT ["./zero2prod"]

