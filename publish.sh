#!/usr/bin/env bash

ts=$(date +%s)

for img in $(docker images "build/*" --format "{{.Repository}}:{{.Tag}}") ; do
  dest="${img#build/}"
  dest="${dest%:latest}"
  case "${dest}" in [0-9]*) continue ;; esac
  docker tag "${img}" "${DOCKER_SINK}:${dest}"
  docker tag "${img}" "${DOCKER_SINK}:${dest}.${ts}"
  docker push "${DOCKER_SINK}:${dest}"
  docker push "${DOCKER_SINK}:${dest}.${ts}"
done

