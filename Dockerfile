# syntax=docker/dockerfile:1
ARG GO_VERSION=1.18

# Base stage
FROM debian:bullseye-slim as base

ARG APP_DIR=/src
ARG UID=1000
ARG GID=1000

RUN groupadd -g ${GID} -r app && useradd -u ${UID} -r -g app app

ENV APP_DIR ${APP_DIR}
WORKDIR $APP_DIR

RUN chown ${UID}:${GID} ${APP_DIR}

# This is required to install the other dependencies
RUN apt-get update && apt-get install -y tini gnupg curl apt-transport-https \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/*.log /var/cache/debconf/*-old

# Build stage
FROM golang:${GO_VERSION}-bullseye as build

WORKDIR /tmp/app
COPY go.mod .
COPY go.sum .
RUN go mod download
COPY . .
#RUN CGO_ENABLED=0 go test -v
RUN go build .

# Release stage
FROM base as release

ARG APP_VERSION
ENV APP_VERSION ${APP_VERSION}

ENV PORT 8080
EXPOSE ${PORT}

COPY --from=build --chown=app:app /tmp/app/backblaze-exporter .

USER app

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["./backblaze-exporter"]
