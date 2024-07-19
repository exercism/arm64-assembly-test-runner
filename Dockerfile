FROM arm64v8/alpine:3.20.1

# install packages required to run the tests
RUN apk add --no-cache jq coreutils gcc libc-dev make python3

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
