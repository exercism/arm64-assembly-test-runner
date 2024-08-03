FROM alpine:3.20.1

# Enable the edge repository and install necessary packages
RUN echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
    apk add --no-cache \
    qemu qemu-system-x86_64 qemu-system-aarch64 qemu-user-static \
    binutils-aarch64-linux-gnu@edge \
    gcc-aarch64-linux-gnu@edge \
    make

# Register QEMU with binfmt
RUN docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
