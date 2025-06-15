FROM debian:bookworm AS builder

# Install packages required to build TinyCC and QEMU
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install --no-install-recommends \
    ca-certificates \
    build-essential \
    libc6-dev-arm64-cross \
    binutils-aarch64-linux-gnu \
    libc6-dev-arm64-cross \
    make \
    python3 \
    python3-venv \
    ninja-build \
    libglib2.0-dev \
    qemu-user \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Build and install TinyCC
RUN wget https://download.savannah.gnu.org/releases/tinycc/tcc-0.9.27.tar.bz2 \
    && tar xf tcc-0.9.27.tar.bz2 \
    && cd tcc-0.9.27 \
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

# Build and install QEMU
RUN wget https://download.qemu.org/qemu-10.0.2.tar.xz \
    && tar xf qemu-10.0.2.tar.xz \
    && cd qemu-10.0.2 \
    && ./configure --prefix=/usr/local --target-list=aarch64-linux-user --enable-strip \
    && make -j $(nproc) \
    && make install

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install --no-install-recommends \
    python3-dev patchelf

SHELL ["/bin/bash", "-c"]
WORKDIR /root
COPY process_results.py /root/process_results.py
RUN python3 -m venv nuitka && source nuitka/bin/activate && pip install nuitka && nuitka --standalone --onefile --output-filename=process_results.py.bin process_results.py

# Build and install GNU assembler
RUN wget https://ftp.gnu.org/gnu/binutils/binutils-2.44.tar.xz \
    && tar xf binutils-2.44.tar.xz \
    && cd binutils-2.44 \
    && ./configure --prefix=/usr/local --target=aarch64-linux-gnu --disable-nls --disable-largefile --without-libiconv-prefix --without-system-zlib --without-zstd \
    && make -j $(nproc) all-gas \
    && make install-gas \
    && strip /usr/local/bin/aarch64-linux-gnu-as

FROM gcr.io/distroless/base-nossl:debug

SHELL ["/busybox/sh", "-c"]

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/local/include /usr/local/include
COPY ./usr/bin /usr/bin

COPY --from=builder /usr/aarch64-linux-gnu /usr/aarch64-linux-gnu

RUN ln -s /busybox/sh /bin/sh
COPY --from=builder /usr/bin/env /usr/bin/env
COPY --from=builder /usr/bin/make /usr/bin/make

#COPY --from=builder /usr/bin/aarch64-linux-gnu-as /usr/bin/aarch64-linux-gnu-as
#COPY --from=builder /lib/x86_64-linux-gnu/libopcodes-2.40-arm64.so /lib/x86_64-linux-gnu/libopcodes-2.40-arm64.so
#COPY --from=builder /lib/x86_64-linux-gnu/libbfd-2.40-arm64.so /lib/x86_64-linux-gnu/libbfd-2.40-arm64.so
#COPY --from=builder /lib/x86_64-linux-gnu/libz.so.1 /lib/x86_64-linux-gnu/libz.so.1
#COPY --from=builder /lib/x86_64-linux-gnu/libzstd.so.1 /lib/x86_64-linux-gnu/libzstd.so.1
#COPY --from=builder /lib/x86_64-linux-gnu/libsframe.so.0 /lib/x86_64-linux-gnu/libsframe.so.0

COPY --from=builder /root/process_results.py.bin /opt/test-runner/process_results.py.bin

WORKDIR /opt/test-runner
COPY bin/run.sh /opt/test-runner/bin/run.sh
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
