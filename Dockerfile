FROM alpine:3.20.1

# Install necessary packages
RUN apk add --no-cache \
    qemu qemu-img qemu-system-x86_64 qemu-system-aarch64 qemu-user-static \
    binutils-aarch64-linux-gnu \
    gcc-aarch64-linux-gnu \
    make

# Register QEMU with binfmt
RUN docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
