FROM golang:1.18 AS builder

RUN apt-get update && apt-get install -y ca-certificates build-essential clang ocl-icd-opencl-dev ocl-icd-libopencl1 jq libhwloc-dev

ARG RUST_VERSION=nightly
ENV XDG_CACHE_HOME="/tmp"

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN wget "https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init"; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

RUN git clone https://github.com/filecoin-project/lotus /tmp/lotus

WORKDIR /tmp/lotus

RUN export CGO_ENABLED=1 && make lotus

FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install Lotus
COPY --from=builder /tmp/lotus/lotus /usr/bin/lotus
COPY --from=builder /etc/ssl/certs /etc/ssl/certs
COPY --from=builder /lib/x86_64-linux-gnu/libdl.so.2 /lib/
COPY --from=builder /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/
COPY --from=builder /lib/x86_64-linux-gnu/librt.so.1 /lib/
COPY --from=builder /lib/x86_64-linux-gnu/libutil.so.1 /lib/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libhwloc.so* /lib/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libltdl.so* /lib/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libnuma.so* /lib/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libOpenCL.so* /lib/

# Install aria2, zstd and make
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends aria2 zstd make

RUN mkdir -p /workspaces/lotus-playground/.lotus
ENV LOTUS_PATH=/workspaces/lotus-playground/.lotus
