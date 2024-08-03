FROM alpine:3.20.1

# Enable the edge repository and install necessary packages
RUN echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
    apk add --no-cache \
    qemu qemu-system-x86_64 qemu-system-aarch64 qemu-user-static \
    binutils-aarch64-linux-gnu@edge \
    gcc-aarch64-linux-gnu@edge \
    make


# Register QEMU with binfmt_misc
RUN mkdir -p /proc/sys/fs/binfmt_misc && \
    mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc && \
    echo ':qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff:/usr/bin/qemu-aarch64:' > /proc/sys/fs/binfmt_misc/register

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
