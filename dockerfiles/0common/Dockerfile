FROM ubuntu:18.04

RUN apt-get update && \
    dpkg-divert --rename /usr/bin/dracut && ln -s /bin/true /usr/bin/dracut && \
    mkdir -p /usr/lib/dkms && \
    dpkg-divert --rename /usr/lib/dkms/dkms_autoinstaller && ln -s /bin/true /usr/lib/dkms/dkms_autoinstaller && \
    env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -q -y dracut linux-image-generic linux-headers-generic dkms && \
    apt-get -q -y clean all && rm -rf /var/lib/apt/lists/* && \
    rm /usr/bin/dracut && dpkg-divert --rename --remove /usr/bin/dracut && \
    rm /usr/lib/dkms/dkms_autoinstaller && dpkg-divert --rename --remove /usr/lib/dkms/dkms_autoinstaller
