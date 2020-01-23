#!/bin/bash

set -eu

cleanup() {
	umount root || :
	kpartx -d $image || :
}

trap cleanup ERR

if [[ $UID -ne 0 ]]; then
	echo "This script must be run as root."
	exit
fi

image=alarm-$(date --iso-8601).img

tarball=ArchLinuxARM-aarch64-latest.tar.gz
url=http://os.archlinuxarm.org/os/$tarball

if [[ ! -f $tarball ]]; then
	wget $url
fi

# Just in case
umount root || :
kpartx -d $image || :

rm -f $image
fallocate -l 2G $image

parted $image -- mktable msdos
parted $image -- mkpart primary ext4 16MiB -0M
parted $image -- set 1 boot on

loopdev=$(kpartx $image | cut -d" " -f1)
kpartx -a $image

mkdir -p root

mkfs.ext4 /dev/mapper/$loopdev
mount /dev/mapper/$loopdev root
bsdtar -xpvf $tarball -C root/

lineno=$(($(grep -Fn "[aur]" root/etc/pacman.conf | cut -d: -f1)+2))
cat <(head -n $lineno root/etc/pacman.conf) - \
	<(tail -n +$lineno root/etc/pacman.conf) << EOF > root/etc/pacman.conf.new
[pinebookpro]
SigLevel = Optional TrustAll
Server = https://simulated.earth/archlinux/pinebookpro/aarch64/
EOF

rm root/etc/pacman.conf
mv root/etc/pacman.conf{.new,}

arch-chroot root pacman-key --init
arch-chroot root pacman-key --populate archlinuxarm
arch-chroot root pacman -R linux-aarch64 --noconfirm
arch-chroot root pacman -Syu linux-pinebookpro pinebookpro-firmware \
	pinebookpro-post-install netctl wpa_supplicant dhcpcd dialog \
	pinebookpro-uboot --noconfirm

rootuuid=$(blkid /dev/mapper/$loopdev | cut -d\" -f2)
mkdir root/boot/extlinux
cat << EOF > root/boot/extlinux/extlinux.conf
LABEL Arch Linux ARM
KERNEL /boot/Image
FDT /boot/dtbs/rockchip/rk3399-pinebook-pro.dtb
APPEND initrd=/boot/initramfs-linux.img console=tty1 rootwait root=UUID=${rootuuid} rw
EOF

dd if=root/boot/idbloader.img of=$image seek=64 conv=notrunc
dd if=root/boot/u-boot.itb of=$image seek=16384 conv=notrunc

cleanup
