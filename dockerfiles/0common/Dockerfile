FROM ubuntu:16.04

RUN apt-get update && \
    env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -q -y dracut linux-image-generic linux-headers-generic dkms && \
    apt-get -q -y clean all && rm -rf /var/lib/apt/lists/*
