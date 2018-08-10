FROM build/0common

MAINTAINER Compute Tools <id-computetools-team@palantir.com>

# install packages
RUN dpkg-divert --rename /usr/sbin/update-grub && ln -s /bin/true /usr/sbin/update-grub && \
    dpkg-divert --rename /etc/cloud/cloud.cfg.d/90_dpkg.cfg && \
    echo "openssh-server HostKey string /dev/null" | debconf-set-selections && \
    apt-get update && \
    env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -q -y \
                 discover laptop-detect os-prober \
                 linux-generic dbus \
                 lvm2 thin-provisioning-tools cryptsetup xfsprogs \
                 openssh-server augeas-tools \
                 cloud-init \
		 nvme-cli \
		 open-vm-tools \
                 grub-pc-bin grub-efi-amd64-bin grub-efi-amd64-signed shim-signed shim && \
    sed -i -e 's/crc32c//' /etc/dracut.conf.d/10-debian.conf && \
    apt-get -q -y clean all && rm -rf /var/lib/apt/lists/* && \
    rm -f /etc/ssh/ssh_host_* && \
    printf 'GRUB_DISABLE_OS_PROBER=true\n' >> /etc/default/grub && \
    rm /usr/sbin/update-grub && dpkg-divert --rename --remove /usr/sbin/update-grub && \
    echo RESET HostKey | debconf-communicate openssh-server

# add dracut and modprobe config for additional drivers
ADD modprobe.d/* /etc/modprobe.d/
ADD dracut.conf.d/* /etc/dracut.conf.d/

# add udev config for stabilized madness
ADD udev-rules.d/* /etc/udev/rules.d/

# reconfigure cloud-init the files to replace os-shipped and add things...
ADD cloud.cfg.d/* /etc/cloud/cloud.cfg.d/
# but this sed line should stop locale reconfiguration. because these images are not really for humans.
# we also shot datasource enumeration in oooold cloud init. eh.
RUN sed -i -e '/ - locale/d' \
     -e '/datasource_list/d' \
     -e '/ - apt-pipelining/d' \
     -e '/ - apt-configure/d' \
    /etc/cloud/cloud.cfg

# NO REALLY CLOUD-INIT STOPPIT. let's configure what we can for grub here, sure.
# we also remove ubuntu's dippy splash, but keep quiet.
# this will likely need reconsideration in vmware.
RUN bash -c 'set -eux ; \
     c="$(augtool print /files/etc/default/grub/GRUB_CMDLINE_LINUX_DEFAULT)" ; \
     c="${c#* = }" ; \
     c="${c/splash/}" ; \
     c="${c:0:-3} nomodeset net.ifnames=0 network-config=e2NvbmZpZzogZGlzYWJsZWR9${c: -3}" ; \
     augtool -s set /files/etc/default/grub/GRUB_CMDLINE_LINUX_DEFAULT "${c}"'&& \
    rm -f /etc/systemd/system/cloud-init.target.wants/cloud-init-local.service && \
    ln -s /dev/null /etc/systemd/system/cloud-init-local.service

# generate bootloader files
# efi-x64
RUN mkdir -p /boot/grub/x86_64-efi && cp /usr/lib/grub/x86_64-efi/*.mod /boot/grub/x86_64-efi

# create efi directory for mounts
RUN mkdir -p /boot/efi

# when/if we run grub-install
ADD grub.d/* /etc/grub.d/

# systemd-networkd for network config please
RUN ln -sf /lib/systemd/system/systemd-networkd.service "/etc/systemd/system/multi-user.target.wants/systemd-networkd.service" && \
    ln -sf /lib/systemd/system/systemd-resolved.service "/etc/systemd/system/multi-user.target.wants/systemd-resolved.service" && \
    mkdir -p "/etc/systemd/system/sockets.target.wants" && \
    ln -sf /lib/systemd/system/systemd-networkd.socket  "/etc/systemd/system/sockets.target.wants/systemd-networkd.service" && \
    ln -sf /dev/null "/etc/systemd/system/dhcpcd.service" && \
    ln -sf /dev/null "/etc/systemd/system/NetworkManager.service" && \
    ln -sf /dev/null "/etc/systemd/system/networking.service" && \
    ln -sf /dev/null "/etc/systemd/system/NetworkManager-wait-online.service" && \
    rm -f "/etc/systemd/system/dbus-org.freedesktop.NetworkManager.service" && \
    rm -f "/etc/systemd/system/multi-user.target.wants/NetworkManager.service" && \
    rm -f "/etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service" && \
    mkdir -p "/etc/systemd/network" && \
    rm -f "/etc/network/interfaces"
ADD /systemd-network /etc/systemd/network
RUN find /etc/systemd/network -type f -exec chmod a+r {} \;

# custom script to dump platform info to a directory for systemd hooks
ADD platform-info/platform-info.service /etc/systemd/system/platform-info.service
ADD platform-info/platform-info.sh      /usr/local/sbin/platform-info.sh
RUN ln -sf /etc/systemd/system/platform-info.service "/etc/systemd/system/multi-user.target.wants/platform-info.service"

# service to start console if we find a hvc0 console *shrug*
ADD hvc0-console.service /etc/systemd/system/hvc0-console.service

# image installation scripts
ADD /scripts /scripts
