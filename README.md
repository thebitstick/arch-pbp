# Pinebook Pro Arch image script

This is a simple script that will generate a minimal bootable Arch Linux ARM image for the Pinebook Pro. It is set up as a single ext4 partition and only has the minimum packages needed to boot the Pinebook Pro and connect to Wi-Fi. The image could either be used as-is, or written to an SD card to use to set up an Arch system yourself on the eMMC.

See the releases page for a prebuilt image.

>**Note**: I have not tried writing this image to eMMC as I would not be able to recover it if something went wrong. Do that at your own risk and be sure you can fix it if something goes wrong.

By default there is only a root user with no password.

The Pinebook Pro-specific packages are taken from [Brian Salcedo](https://github.com/salcedo)'s repository [here](https://simulated.earth/archlinux/pinebookpro/aarch64/). The PKGBUILDs used can be found [here](https://github.com/salcedo/pinebookpro-PKGBUILDs).

## Dependencies
This script has only been tested on an Arch x86\_64 system.

```
multipath-tools e2fsprogs parted arch-install-scripts
```

No extra dependencies should be needed on aarch64, but for other architectures you'll also need some way to run aarch64 binaries, such as `qemu-user-static-bin` + `binfmt-qemu-static` from the AUR.

## Installation
1. Download the [latest release](https://github.com/nadiaholmquist/arch-pbp/releases) of the prebuilt image, or generate the image yourself.
2. `unxz alarm-2020-04-02.img.xz` or whatever your generated xz archive is called.
3. `dd if=alarm-2020-04-02.img of=/dev/YOUR_USB_OR_SD_CARD` or whatever your generated img is called.
4. After booting the media, connect to the Internet by either using wired Ethernet, or by using `wifi-menu` to connect to Wi-Fi.
5. `systemctl enable dhcpcd`
6. Finish setup by initializing Pacman keys to download packages
```bash
$ pacman-key --init
$ pacman-key --populate archlinuxarm
```
