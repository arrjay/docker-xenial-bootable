#!/usr/bin/env bash

set -ex

[ "${DOCKER_SINK}" ] && {
  docker pull "${DOCKER_SINK}/ubuntu:18.04"
  docker tag  "${DOCKER_SINK}/ubuntu:18.04" "ubuntu:18.04"
}

set -u

for d in dockerfiles/*/Dockerfile ; do
  image=${d#dockerfiles/}
  image=${image%/Dockerfile}
  docker build -t "build/${image}" -f "${d}" .
done
