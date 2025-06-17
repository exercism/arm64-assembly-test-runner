FROM debian:bookworm AS builder

ARG TCC_MIRROR="https://download.savannah.gnu.org/releases/tinycc"
ARG TCC_VERSION="0.9.27"

ARG QEMU_MIRROR="https://download.qemu.org"
ARG QEMU_VERSION="10.0.2"

ARG BINUTILS_MIRROR="https://ftp.gnu.org/gnu/binutils"
ARG BINUTILS_VERSION="2.44"

# Install packages required to build TinyCC, GNU assembler, and QEMU
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install --no-install-recommends \
    binutils-aarch64-linux-gnu \
    build-essential \
    ca-certificates \
    libc6-dev-arm64-cross \
    libglib2.0-dev \
    ninja-build \
    python3 \
    python3-venv \
    qemu-user \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Build and install TinyCC
COPY tcc-reloc-condbr19.patch tcc-reloc-condbr19.patch
RUN wget ${TCC_MIRROR}/tcc-${TCC_VERSION}.tar.bz2 \
    && tar xf tcc-${TCC_VERSION}.tar.bz2 \
    && cd tcc-${TCC_VERSION} \
    && patch --strip=1 < ../tcc-reloc-condbr19.patch \
    && ./configure \
    --prefix=/usr/local \
    --cpu=aarch64 \
    --sysroot=/usr/aarch64-linux-gnu \
    --triplet=aarch64-linux-gnu \
    --sysincludepaths=/usr/local/lib/tcc/include:/usr/aarch64-linux-gnu/include:/usr/aarch64-linux-gnu/include/linux \
    --libpaths=/usr/aarch64-linux-gnu/lib \
    --crtprefix=/usr/aarch64-linux-gnu/lib \
    && make -j $(nproc) \
    && make install

# Build and install GNU assembler for aarch64
RUN wget ${BINUTILS_MIRROR}/binutils-${BINUTILS_VERSION}.tar.xz \
    && tar xf binutils-${BINUTILS_VERSION}.tar.xz \
    && cd binutils-${BINUTILS_VERSION} \
    && ./configure \
    --prefix=/usr/local \
    --target=aarch64-linux-gnu \
    --disable-nls \
    --disable-largefile \
    --without-libiconv-prefix \
    --without-system-zlib \
    --without-zstd \
    && make -j $(nproc) all-ld all-gas \
    && make install-ld install-gas \
    && strip /usr/local/bin/aarch64-linux-gnu-as

# Build and install minimal QEMU only supporting aarch64
RUN wget ${QEMU_MIRROR}/qemu-${QEMU_VERSION}.tar.xz \
    && tar xf qemu-${QEMU_VERSION}.tar.xz \
    && cd qemu-${QEMU_VERSION} \
    && ./configure --prefix=/usr/local --target-list=aarch64-linux-user --enable-strip \
    && make -j $(nproc) \
    && make install

# Base this image on the :debug variant so that it contains busybox
FROM gcr.io/distroless/python3-debian12:debug

SHELL ["/busybox/sh", "-c"]

# Copy binaries and libs built in the first stage
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib /usr/local/lib

# Copy wrapper scripts
COPY ./usr/bin /usr/bin

# Copy include files and libraries for cross compilation (from libc6-dev-arm64-cross)
COPY --from=builder /usr/aarch64-linux-gnu /usr/aarch64-linux-gnu

# Our scripts expect /bin/sh to be available
RUN ln -s /busybox/sh /bin/sh

# Some more required tools we just copy over from the build stage
COPY --from=builder /usr/bin/env /usr/bin/env
COPY --from=builder /usr/bin/make /usr/bin/make

# Libraries  by /usr/local/bin/qemu-aarch64
COPY --from=builder /lib/x86_64-linux-gnu/libglib-2.0.so.0 /lib/x86_64-linux-gnu/libglib-2.0.so.0
COPY --from=builder /lib/x86_64-linux-gnu/libgmodule-2.0.so.0 /lib/x86_64-linux-gnu/libgmodule-2.0.so.0
COPY --from=builder /lib/x86_64-linux-gnu/libpcre2-8.so.0 /lib/x86_64-linux-gnu/libpcre2-8.so.0

WORKDIR /opt/test-runner
COPY bin/run.sh /opt/test-runner/bin/run.sh
COPY process_results.py /opt/test-runner/process_results.py

ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
