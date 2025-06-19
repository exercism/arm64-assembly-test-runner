FROM alpine

RUN apk update && apk upgrade \
    && apk --no-cache add curl bash make qemu-aarch64 \
    && apk cache clean

ADD gcc-5.3.0-toolchain.tar.gz /

RUN apk update && apk upgrade \
    && apk --no-cache add python3 \
    && apk cache clean

RUN ln -s /opt/cross/aarch64-linux-musl /usr/aarch64-linux-gnu

RUN cd /opt/cross/aarch64-linux-musl/lib && rm ld-musl-aarch64.so.1 && ln -s libc.so ld-musl-aarch64.so.1

WORKDIR /opt/test-runner
COPY process_results.py .
COPY bin /opt/test-runner/bin

ENV PATH="$PATH:/opt/cross/bin"
ENV AS=aarch64-linux-musl-as
ENV CC=aarch64-linux-musl-gcc

ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
