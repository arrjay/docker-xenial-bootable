#!/usr/bin/env bash

set -ex

[ "${DOCKER_SINK}" ] && {
  [ -z "$NOPUSH" ] && docker pull "${DOCKER_SINK}/ubuntu:16.04"
  docker tag  "${DOCKER_SINK}/ubuntu:16.04" "ubuntu:16.04"
}

set -u

docker build -t "build/latest" .

devimg=$(docker images --filter "label=stage=dev" --format "{{.CreatedAt}}\t{{.ID}}"|sort -nr|head -n1|cut -f2)
docker tag "${devimg}" "build/dev"
