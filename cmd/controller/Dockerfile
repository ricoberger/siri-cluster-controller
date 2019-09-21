FROM alpine:latest

ARG REVISION
ARG VERSION

LABEL maintainer="Rico Berger"
LABEL git.ref=$REVISION
LABEL git.version=$VERSION
LABEL git.url="https://github.com/ricoberger/siri-cluster-controller"

RUN apk add --no-cache --update curl ca-certificates
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kubectl
RUN chmod +x kubectl && mv kubectl /bin/kubectl
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD curl --fail http://localhost:8080/_health || exit 1

RUN addgroup -g 1000 siri && \
    adduser -D -u 1000 -G siri siri
USER siri

COPY ./bin/siri-cluster-controller-linux-amd64  /bin/siri-cluster-controller
EXPOSE 8080

ENTRYPOINT  [ "/bin/siri-cluster-controller" ]
