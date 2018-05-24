FROM ubuntu:xenial

RUN apt-get update && \
    env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -q -y linux-image-generic linux-headers-generic dkms && \
    apt-get -q -y clean all && rm -rf /var/lib/apt/lists/*
