FROM ubuntu:16.04

RUN apt-get update && \
    dpkg-divert --rename /usr/bin/dracut && ln -s /bin/true /usr/bin/dracut && \
    env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -q -y dracut linux-image-generic linux-headers-generic dkms && \
    apt-get -q -y clean all && rm -rf /var/lib/apt/lists/* && \
    rm /usr/bin/dracut && dpkg-divert --rename --remove /usr/bin/dracut
