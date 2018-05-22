FROM build/0common

MAINTAINER RJ Bergeron <rbergero@gmail.com>

# re-configure apt
RUN env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -q -y software-properties-common && apt-get clean all

RUN add-apt-repository -m ppa:notarrjay/fio-dkms && apt-get update && apt-get clean all

ADD apt-keys/hpe.asc /etc/apt/trusted.gpg.d/hpe.asc

RUN echo "deb http://downloads.linux.hpe.com/SDR/downloads/MCP/ubuntu xenial/current non-free" > /etc/apt/sources.list.d/hpe.list && \
    apt-key add /etc/apt/trusted.gpg.d/hpe.asc && \
    apt-get update && apt-get clean all

# install packages
RUN env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -q -y ubuntu-standard \
                 casper lupin-casper discover laptop-detect os-prober \
                 linux-generic dracut-core dbus \
                 lvm2 thin-provisioning-tools cryptsetup mdadm xfsprogs bcache-tools \
                 memtest86+ nwipe smartmontools lm-sensors ethtool smartmontools fio \
                 openssh-server augeas-tools \
                 ssacli hpsmh cloud-init \
                 grub-efi-amd64-bin grub-efi-ia32-bin grub-efi-amd64-signed shim-signed shim syslinux isolinux hfsprogs hfsplus && apt-get clean all && \
                 rm -f /etc/ssh/ssh_host_*

RUN dpkg-divert --rename /usr/sbin/update-grub && ln -s /bin/true /usr/sbin/update-grub && \
    env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get -q -y install tboot && \
    printf 'GRUB_DISABLE_OS_PROBER=true\n' >> /etc/default/grub && \
    rm /usr/sbin/update-grub && dpkg-divert --rename --remove /usr/sbin/update-grub

RUN apt-get update && env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get -q -y install iomemory-vsl-dkms && \
    find /usr/src/iomemory-* /etc/sysconfig/ -type d -exec chmod a+rx {} \; && \
    bash -c 'i=(/usr/src/iomemory-vsl*) && k=(/boot/vmlinuz-*) && k=${k[0]#*-} && \
    dkms add "${i[0]}" && dkms autoinstall -k "${k}"' && apt-get -q -y clean all && \
    rm -f /boot/initrd.*.old-dkms

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

# uefi image here
RUN truncate -s 12M /boot/efiboot.img && mkfs.vfat -F16 /boot/efiboot.img && \
      mmd -i /boot/efiboot.img efi && mmd -i /boot/efiboot.img efi/boot && \
      mcopy -i /boot/efiboot.img /usr/lib/shim/shimx64.efi.signed ::efi/boot/bootx64.efi && \
      mcopy -i /boot/efiboot.img /usr/lib/grub/x86_64-efi-signed/gcdx64.efi.signed ::efi/boot/grubx64.efi && \
      mcopy -i /boot/efiboot.img /usr/lib/grub/i386-efi/gcdia32.efi ::efi/boot/bootia32.efi && \
      mmd -i /boot/efiboot.img efi/boot/i386-efi && mcopy -i /boot/efiboot.img /usr/lib/grub/i386-efi/*.mod ::efi/boot/i386-efi && \
      mkdir -p /EFI/BOOT/i386-efi && cp /usr/lib/grub/i386-efi/*.mod /EFI/BOOT/i386-efi && \
      echo "insmod linux" >> "/EFI/BOOT/grub.cfg" && echo "configfile /boot/grub/grub.cfg" >> "/EFI/BOOT/grub.cfg"

## mac boot madness is just pilfered from fedora ;)
RUN wget -o /boot/macboot.img http://mirrors.kernel.org/fedora/releases/28/Server/x86_64/os/images/macboot.img && rm -f /macboot.img

# when/if we run grub-install
ADD grub.d/* /etc/grub.d/

# tpl files for iso9660 booting
RUN bash -c 'd="" ; c="/isolinux/syslinux.cfg.tpl" ; g="/boot/grub/grub.cfg.tpl" ; for i in /boot/initrd.img* ; do v="${i%-generic*}" ; v="${v#*.img-}" ; { [ ! -z "${d}" ] && d="${v}" ; echo "DEFAULT ${v}" >> "${c}" ; } ; echo "LABEL ${v}" >> "${c}" ; echo " KERNEL vmlinuz-${v}-generic" >> "${c}" ; echo " INITRD initrd.img-${v}-generic" >> "${c}" ; echo " APPEND console=tty0 root=UNSET intel_iommu=on iommu=pt iommu=1 rw network-config=eyJuZXR3b3JrIjp7ImNvbmZpZyI6ImRpc2FibGVkIn19fQ==" >> "${c}" ; echo "menuentry '\''${v}'\'' {" >> "${g}" ; echo "  linux /boot/vmlinuz-${v}-generic console=tty0 root=UNSET intel_iommu=on iommu=pt iommu=1 rw  network-config=eyJuZXR3b3JrIjp7ImNvbmZpZyI6ImRpc2FibGVkIn19fQ==" >> "${g}" ; echo "  initrd /boot/initrd.img-${v}-generic" >> "${g}" ; echo "}" >> "${g}" ; done'

# initrd modules
ADD /iomemory-dracut /usr/lib/dracut/modules.d/10iomemory-md

# reconfigure cloud-init
RUN sed -i -e '/ - locale/d' /etc/cloud/cloud.cfg
ADD /cloud.cfg.d /etc/cloud/cloud.cfg.d

# systemd-networkd for network config please
RUN ln -sf /lib/systemd/system/systemd-networkd.service "/etc/systemd/system/multi-user.target.wants/systemd-networkd.service" && \
    mkdir -p "/etc/systemd/system/sockets.target.wants" && \
    ln -sf /lib/systemd/system/systemd-networkd.socket  "/etc/systemd/system/sockets.target.wants/systemd-networkd.service" && \
    ln -sf /dev/null "/etc/systemd/system/dhcpcd.service" && \
    ln -sf /dev/null "/etc/systemd/system/NetworkManager.service" && \
    ln -sf /dev/null "/etc/systemd/system/networking.service" && \
    ln -sf /dev/null "/etc/systemd/system/NetworkManager-wait-online.service" && \
    rm -f "/etc/systemd/system/dbus-org.freedesktop.NetworkManager.service" && \
    rm -f "/etc/systemd/system/multi-user.target.wants/NetworkManager.service" && \
    rm -f "/etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service" && \
    mkdir -p "/etc/systemd/network"
ADD /systemd-network /etc/systemd/network

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
