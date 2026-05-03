FROM ubuntu:24.04

# install packages required to run the tests
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install --no-install-recommends \
        gcc-aarch64-linux-gnu \
        jq \
        libc6-dev-arm64-cross \
        make \
        qemu-user \
    && rm -rf /var/lib/apt/lists/* \
            /var/cache/apt/archives \
            /usr/share/doc/* \
            /usr/share/man/* \
            /usr/share/info/* \
            /usr/share/locale/* \
            /usr/share/lintian \
            /usr/share/linda \
            /var/log/* \
            /usr/bin/aarch64-linux-gnu-ld.gold \
            /usr/bin/aarch64-linux-gnu-dwp \
    && find /usr/bin -name 'aarch64-linux-gnu-lto-dump-*' -delete \
    && find /usr/libexec/gcc-cross/aarch64-linux-gnu -maxdepth 2 \
            \( -name lto1 -o -name lto-wrapper \) -delete \
    && find /usr/bin -name 'qemu-*' \
            ! -name 'qemu-aarch64' \
            ! -name 'qemu-arm64' \
            -delete \
    && find /usr/lib/gcc-cross/aarch64-linux-gnu -name '*.la' -delete

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
