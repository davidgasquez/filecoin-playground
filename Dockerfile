FROM golang:1.20.7 AS builder

RUN apt-get update && \
    apt-get install -y \
    ca-certificates build-essential clang ocl-icd-opencl-dev ocl-icd-libopencl1 jq libhwloc-dev

ARG RUST_VERSION=nightly
ENV XDG_CACHE_HOME="/tmp"

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    FFI_BUILD_FROM_SOURCE=1

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

RUN make clean all && make install

RUN git clone https://github.com/filecoin-project/lassie /tmp/lassie

WORKDIR /tmp/lassie

RUN go build ./cmd/lassie

RUN go install github.com/ipld/go-car/cmd/car@latest

FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install Lotus
COPY --from=builder /tmp/lotus/lotus /usr/bin/lotus
COPY --from=builder /tmp/lotus/lotus-miner /usr/bin/lotus-miner
COPY --from=builder /etc/ssl/certs /etc/ssl/certs
COPY --from=builder /lib/x86_64-linux-gnu/libdl.so.2 /lib/
COPY --from=builder /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/
COPY --from=builder /lib/x86_64-linux-gnu/librt.so.1 /lib/
COPY --from=builder /lib/x86_64-linux-gnu/libutil.so.1 /lib/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libhwloc.so* /lib/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libltdl.so* /lib/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libnuma.so* /lib/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libOpenCL.so* /lib/

# Install Lassie
COPY --from=builder /tmp/lassie/lassie /usr/bin/lassie

# Install go-car
COPY --from=builder /go/bin/car /usr/bin/car

# Install aria2, zstd and make
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends aria2 zstd make
