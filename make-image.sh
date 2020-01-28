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

pacstrap -GMC pacman.conf root/ base linux-pinebookpro \
	pinebookpro-firmware pinebookpro-post-install uboot-pinebookpro \
	netctl wpa_supplicant dhcpcd dialog --noconfirm

lineno=$(($(grep -Fn "[aur]" root/etc/pacman.conf | cut -d: -f1)+2))
cat <(head -n $lineno root/etc/pacman.conf) pinebookpro.conf \
	<(tail -n +$lineno root/etc/pacman.conf) > root/etc/pacman.conf.new

rm root/etc/pacman.conf
mv root/etc/pacman.conf{.new,}

rootuuid=$(blkid /dev/mapper/$loopdev | cut -d\" -f2)
mkdir root/boot/extlinux
sed "s/<UUID>/${rootuuid}/" extlinux.conf > root/boot/extlinux/extlinux.conf

dd if=root/boot/idbloader.img of=$image seek=64 conv=notrunc
dd if=root/boot/u-boot.itb of=$image seek=16384 conv=notrunc

cleanup
