FROM build/0common

MAINTAINER Compute Tools <id-computetools-team@palantir.com>

RUN apt-get update && \
    env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -q -y dpkg-dev debhelper dput devscripts ubuntu-dev-tools && \
    apt-get -q -y clean all && rm -rf /var/lib/apt/lists/*
