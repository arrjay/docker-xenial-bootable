#!/usr/bin/env bash

set -ex

[ "${DOCKER_SINK}" ] && {
  [ -z "$NOPUSH" ] && docker pull "${DOCKER_SINK}/ubuntu:16.04"
  docker tag  "${DOCKER_SINK}/ubuntu:16.04" "ubuntu:16.04"
}

set -u

for d in dockerfiles/*/Dockerfile ; do
  image=${d#dockerfiles/}
  image=${image%/Dockerfile}
  docker build -t "build/${image}" -f "${d}" .
done
