FROM debian:buster-slim as builder
# Due to inconsistencies in how projects name their architectures
RUN dpkg --print-architecture > /tmp/debarch && \
    cat /tmp/debarch | sed 's/arm64/aarch64/g' > /tmp/s6_arch && \
    cat /tmp/debarch | sed 's/arm64/aarch64/g' | sed 's/amd64/x86_64/g' | sed 's/armhf/armv7/g' > /tmp/templar_arch && \
    cat /tmp/debarch | grep 'armhf' | sed 's/armhf/eabihf/g' > /tmp/templar_suffix

# Dependency versions
ARG S6_VERSION="2.0.0.1"
ARG TEMPLAR_VERSION="0.4.0"

# Tools needed for the builder stage
RUN apt-get update && \
    apt-get install -yy curl xz-utils wget && \
    mkdir -p /dist

# Using wget instead of curl due to a curl bug on linux/arm, not able to validate certifates properly
# Send S6 Overlay to target directory
RUN wget "https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-$(cat /tmp/s6_arch).tar.gz" -O - | \
    tar xz -C /dist

# Send Templar to target directory
RUN wget "https://github.com/proctorlabs/templar/releases/download/v${TEMPLAR_VERSION}/templar-$(cat /tmp/templar_arch)-unknown-linux-gnu$(cat /tmp/templar_suffix).tar.xz" -O - | \
    tar xJ -C /dist/usr/bin && \
    chmod +x "/dist/usr/bin/templar"

COPY rootfs/ /dist/

FROM debian:buster-slim
COPY --from=builder /dist/ /
