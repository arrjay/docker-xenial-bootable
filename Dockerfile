FROM ubuntu:16.04 as common

RUN apt-get update && \
    dpkg-divert --rename /usr/bin/dracut && ln -s /bin/true /usr/bin/dracut && \
    mkdir -p /usr/lib/dkms && \
    dpkg-divert --rename /usr/lib/dkms/dkms_autoinstaller && ln -s /bin/true /usr/lib/dkms/dkms_autoinstaller && \
    env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -q -y \
     linux-image-generic linux-headers-generic dkms && \
    apt-get -q -y clean all && rm -rf /var/lib/apt/lists/* && \
    rm /usr/bin/dracut && dpkg-divert --rename --remove /usr/bin/dracut && \
    rm /usr/lib/dkms/dkms_autoinstaller && dpkg-divert --rename --remove /usr/lib/dkms/dkms_autoinstaller

# build dev here...
FROM common as dev

RUN apt-get update && \
    env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -q -y \
     dpkg-dev debhelper dput devscripts ubuntu-dev-tools equivs && \
    apt-get -q -y clean all && rm -rf /var/lib/apt/lists/*

# go _backwards_ so we can tag dev in 18.06.0.ce...
FROM dev
LABEL stage=dev

MAINTAINER RJ <rbergero@gmail.com>

# now, build the final image.
FROM common
LABEL stage=final

MAINTAINER RJ <rbergero@gmail.com>

# re-configure apt
RUN apt-get update && \
    env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -q -y \
     software-properties-common && \
    apt-get -q -y clean all && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository -m ppa:notarrjay/fio-dkms

ADD apt-keys /etc/apt/trusted.gpg.d

RUN echo "deb http://downloads.linux.hpe.com/SDR/downloads/MCP/ubuntu xenial/current non-free" > /etc/apt/sources.list.d/hpe.list && \
    apt-key add /etc/apt/trusted.gpg.d/hpe.asc

RUN echo "deb http://red-jay.github.io/fio-drivers fio release" > /etc/apt/sources.list.d/fio.list && \
    apt-key add /etc/apt/trusted.gpg.d/fio.asc

# install packages
RUN dpkg-divert --rename /usr/sbin/update-grub && ln -s /bin/true /usr/sbin/update-grub && \
    dpkg-divert --rename /etc/cloud/cloud.cfg.d/90_dpkg.cfg && \
    echo "openssh-server HostKey string /dev/null" | debconf-set-selections && \
    apt-get update && \
    env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -q -y \
                 ubuntu-standard \
                 discover laptop-detect os-prober \
                 linux-generic dracut-core dbus \
                 lvm2 thin-provisioning-tools cryptsetup mdadm xfsprogs bcache-tools \
                 memtest86+ nwipe smartmontools lm-sensors ethtool smartmontools fio \
                 openssh-server sudo augeas-tools \
                 cloud-init \
		 open-vm-tools \
                 tboot \
                 iomemory-vsl-dkms \
		 fio-common fio-preinstall fio-sysvinit fio-util \
                 grub-efi-amd64-bin grub-efi-ia32-bin grub-efi-amd64-signed shim-signed shim grub-pc-bin \
                 syslinux syslinux-utils syslinux-common \
                 isolinux hfsprogs hfsplus && \
    apt-get -q -y clean all && rm -rf /var/lib/apt/lists/* && \
    rm -f /etc/ssh/ssh_host_* && \
    rm -f /etc/dracut.conf.d/iomemory-vsl.conf && \
    sed -i \
      -e 's/splash/video=720x400 consoleblank=0 vt.default_red=7,220,133,181,38,211,42,238,0,203,88,101,131,108,147,253 vt.default_grn=54,50,153,137,139,54,161,232,43,75,110,123,148,113,161,246 vt.default_blu=66,47,0,0,210,130,152,213,54,22,117,131,150,196,161,227 vt.color=0x70 network-config=e2NvbmZpZzogZGlzYWJsZWR9/' \
      /etc/default/grub && \
    printf 'GRUB_DISABLE_OS_PROBER=true\n' >> /etc/default/grub && \
    rm /usr/sbin/update-grub && dpkg-divert --rename --remove /usr/sbin/update-grub && \
    find /usr/src/iomemory-* /etc/sysconfig/ -type d -exec chmod a+rx {} \; && \
    bash -c 'i=(/usr/src/iomemory-vsl*) && k=(/boot/vmlinuz-*) && k=${k[0]#*-} && \
    dkms add "${i[0]}" && dkms autoinstall -k "${k}"' && \
    rm -f /boot/initrd.*.old-dkms && \
    echo RESET HostKey | debconf-communicate openssh-server

# add vconsole config
ADD vconsole.conf /etc/vconsole.conf

# add user
RUN groupadd -g 1024 ejusdem && \
    useradd --uid 1024 --gid 1024 ejusdem && \
    usermod -G sudo ejusdem && \
    mkdir /home/ejusdem && \
    chown 1024:1024 /home/ejusdem

# reconfigure sudo
RUN bash -c 'autosudo=$(mktemp) && \
    printf \#\!/bin/bash\\nsed\ -i\ -e\ \"s@^%%sudo.*@%%sudo\ ALL=\(ALL:ALL\)\ NOPASSWD:\ ALL@\"\ \${2} > "${autosudo}" && \
    chmod +x "${autosudo}" && \
    env EDITOR="${autosudo}" visudo && \
    rm "${autosudo}"'

# generate bootloader files
## isolinux...
RUN mkdir /isolinux && cp /usr/lib/ISOLINUX/isolinux.bin /isolinux/isolinux.bin && \
                       cp /usr/lib/syslinux/modules/bios/*.c32 /isolinux && \
                       cp /usr/lib/ISOLINUX/isohd*.bin /isolinux

# efi-ia32
RUN grub-mkimage -O i386-efi -d /usr/lib/grub/i386-efi -o /usr/lib/grub/i386-efi/gcdia32.efi -p /EFI/BOOT \
     all_video boot btrfs cat chain configfile echo efifwsetup efinet ext2 fat font gfxmenu gfxterm gzio halt hfsplus iso9660 jpeg loadenv lvm mdraid09 mdraid1x minicmd normal part_apple part_msdos part_gpt password_pbkdf2 png reboot search search_fs_uuid search_fs_file search_label sleep syslinuxcfg test tftp regexp video xfs

# efi-x64
RUN mkdir -p /boot/grub/x86_64-efi && cp /usr/lib/grub/x86_64-efi/*.mod /boot/grub/x86_64-efi

# create efi directory for mounts
RUN mkdir -p /boot/efi

# when/if we run grub-install
ADD grub.d/* /etc/grub.d/

# initrd modules
ADD /iomemory-dracut /usr/lib/dracut/modules.d/10iomemory-md

# reconfigure cloud-init
RUN sed -i -e '/ - locale/d' -e '/datasource_list/d' -e 's/name: ubuntu/name: ejusdem/' /etc/cloud/cloud.cfg
ADD /cloud.cfg.d /etc/cloud/cloud.cfg.d

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
    rm -f "/etc/systemd/system/cloud-init.target.wants/cloud-init-local.service" && \
    ln -sf /dev/null "/etc/systemd/system/cloud-init-local.service" && \
    rm -f "/etc/network/interfaces"
ADD /systemd-network /etc/systemd/network
RUN find /etc/systemd/network -type f -exec chmod a+r {} \;

# custom script to dump platform info to a directory for systemd hooks
ADD platform-info/platform-info.service /etc/systemd/system/platform-info.service
ADD platform-info/platform-info.sh      /usr/local/sbin/platform-info.sh
RUN ln -sf /etc/systemd/system/platform-info.service "/etc/systemd/system/multi-user.target.wants/platform-info.service"

# disable hpsmhd, mdadm, smartd on virtual hosts
ADD hpsmhd.service /etc/systemd/system/hpsmhd.service
RUN ln -sf /etc/systemd/system/hpsmhd.service "/etc/systemd/system/multi-user.target.wants/hpsmhd.service"

ADD mdadm.service /etc/systemd/system/mdadm.service
RUN ln -sf /etc/systemd/system/mdadm.service "/etc/systemd/system/multi-user.target.wants/mdadm.service"

RUN mkdir -p /etc/systemd/system/smartd.service.d
ADD smartd.service.d /etc/systemd/system/smartd.service.d

# service to start console if we find a hvc0 console *shrug*
ADD hvc0-console.service /etc/systemd/system/hvc0-console.service

# image installation scripts
ADD /scripts /scripts
