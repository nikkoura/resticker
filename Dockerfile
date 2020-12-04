#
# Builder image
#
FROM golang:1.15.6 AS cron-builder

ARG GO_CRON_VERSION=0.0.8
ARG GO_CRON_SHA256=7cd08752aa62ac744fc79def3e184f397447bd35c9aa9d6cbff0176aa3debcb5
ARG GO_CRON_REPO=github.com/RandomSegFault

RUN curl -sL -o go-cron.tar.gz https://${GO_CRON_REPO}/go-cron/archive/v${GO_CRON_VERSION}.tar.gz \
 && echo "${GO_CRON_SHA256}  go-cron.tar.gz" | sha256sum -c - \
 && tar xzf go-cron.tar.gz \
 && mkdir -p $GOPATH/src/${GO_CRON_REPO}/ \
 && mv go-cron-${GO_CRON_VERSION} ${GOPATH}/src/${GO_CRON_REPO}/go-cron \
 && cd ${GOPATH}/src/${GO_CRON_REPO}/go-cron \
 && go get \
 && go build -ldflags "-linkmode external -extldflags -static" ./bin/go-cron.go \
 && mv go-cron /usr/local/bin/go-cron

FROM golang:1.15.6 AS restic-builder

ARG RESTIC_VERSION=0.9.5
ARG RESTIC_SHA256=e22208e946ede07f56ef60c1c89de817b453967663ce4867628dff77761bd429

RUN curl -sL -o restic.tar.gz https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic-${RESTIC_VERSION}.tar.gz \
 && echo "${RESTIC_SHA256}  restic.tar.gz" | sha256sum -c - \
 && tar xzf restic.tar.gz \
 && cd restic-${RESTIC_VERSION} \
 && go run build.go \
 && mv restic /usr/local/bin/restic

#
# Final image
#
FROM alpine:3.10

RUN apk add --update --no-cache ca-certificates fuse nfs-utils openssh tzdata bash
RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community/ docker-cli

ENV RESTIC_REPOSITORY /mnt/restic

COPY --from=cron-builder /usr/local/bin/* /usr/local/bin/
COPY --from=restic-builder /usr/local/bin/* /usr/local/bin/
COPY backup /usr/local/bin/
COPY entrypoint /

ENTRYPOINT ["/entrypoint"]
