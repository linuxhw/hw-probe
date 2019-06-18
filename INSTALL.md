INSTALL HOWTO
=============

HW Probe 1.4 (April 14, 2018)

This file explains how to install and setup environment for the tool in your computer.

See more info in the [README.md](https://github.com/linuxhw/hw-probe/).


Contents
--------

* [ Run without Installing ](#run-without-installing)
* [ Install from Source    ](#install-from-source)
* [ Install on Ubuntu      ](#install-on-ubuntu)
* [ Install on Debian      ](#install-on-debian)
* [ Install on openSUSE    ](#install-on-opensuse)
* [ Install on Manjaro     ](#install-on-manjaro)
* [ Install on Arch Linux  ](#install-on-arch-linux)
* [ Install on Fedora      ](#install-on-fedora)
* [ Install on CentOS 7    ](#install-on-centos-7)
* [ Install on CentOS 6    ](#install-on-centos-6)
* [ Install on RHEL 7      ](#install-on-rhel-7)
* [ Install on RHEL 6      ](#install-on-rhel-6)
* [ Build Debian package   ](#build-debian-package)


Run without Installing
----------------------

You can probe your computer by [AppImage](https://github.com/linuxhw/hw-probe#appimage), [Docker](https://github.com/linuxhw/hw-probe#docker), [Snap](https://github.com/linuxhw/hw-probe#snap), [Flatpak](https://github.com/linuxhw/hw-probe#flatpak) or [Live CD](https://github.com/linuxhw/hw-probe#live-cd) without the need to install anything on your host.


Install from Source
-------------------

This command will install the `hw-probe` program in the `PREFIX/bin` system directory:

    sudo make install prefix=PREFIX [/usr, /usr/local, ...]

To uninstall:

    sudo make uninstall prefix=PREFIX

###### Requires

* Perl 5
* perl-Digest-SHA
* perl-Data-Dumper
* hwinfo (https://github.com/openSUSE/hwinfo or https://pkgs.org/download/hwinfo)
* curl
* dmidecode
* smartmontools (smartctl)
* pciutils (lspci)
* usbutils (lsusb)
* edid-decode

###### Recommends

* libwww-perl (to use instead of curl)
* mcelog
* hdparm
* systemd-tools (systemd-analyze)
* acpica-tools
* mesa-demos
* memtester
* sysstat (iostat)
* cpuid
* rfkill
* xinput
* vainfo
* inxi
* vulkan-utils
* i2c-tools
* opensc

###### Suggests

* hplip (hp-probe)
* sane-backends (sane-find-scanner)
* pnputils (lspnp)


Install on Ubuntu
-----------------

PPA: https://launchpad.net/~mikhailnov/+archive/ubuntu/hw-probe

On Ubuntu and Ubuntu based Linux distributions (Linux Mint, elementary OS, etc.) you can install a PPA package:

    sudo add-apt-repository universe
    sudo add-apt-repository ppa:mikhailnov/hw-probe
    sudo apt update
    sudo apt install hw-probe --no-install-recommends

###### Snap

The [Snap package](https://github.com/linuxhw/hw-probe#snap) is also available to install and run easily on Ubuntu without the need to install any Deb packages to your system.


Install on Debian
-----------------

Download DEB package [hw-probe_1.4-2_all.deb](https://github.com/linuxhw/hw-probe/releases/download/1.4/hw-probe_1.4-2_all.deb) and install:

    sudo dpkg -i ./hw-probe_1.4-2_all.deb
    sudo apt install -f --no-install-recommends


Install on openSUSE
-------------------

Setup an OBS repository and install the package:

    sudo zypper addrepo https://download.opensuse.org/repositories/hardware/openSUSE_Leap_15.0/ hardware
    sudo zypper install --no-recommends hw-probe


Install on Manjaro
------------------

For Manjaro 18 and later:

    sudo pacman -S hw-probe


Install on Arch Linux
---------------------

On Arch Linux and Arch Linux based Linux distributions (Manjaro, Antergos, etc.):

###### From AUR

    git clone https://aur.archlinux.org/hw-probe.git
    cd hw-probe
    makepkg -sri

###### Binary Package

Download package [hw-probe-1.4-1.ArchLinux-any.pkg.tar.xz](https://github.com/linuxhw/hw-probe/releases/download/1.4/hw-probe-1.4-1.ArchLinux-any.pkg.tar.xz) and install by pacman:

    pacman -U ./hw-probe-1.4-1.ArchLinux-any.pkg.tar.xz


Install on Fedora
-----------------

For Fedora 28 and later:

    sudo dnf install hw-probe


Install on CentOS 7
-------------------

    sudo yum install epel-release
    sudo yum install hw-probe


Install on CentOS 6
-------------------

    sudo yum install epel-release
    sudo yum install hw-probe


Install on RHEL 7
-----------------

    sudo yum install epel-release
    sudo yum install hw-probe


Install on RHEL 6
-----------------

    sudo yum install epel-release
    sudo yum install hw-probe


Build Debian package
--------------------

Build and install the latest version of hw-probe as a Deb (Debian/Ubuntu/Mint) package:

###### Quick way

    sudo apt install build-essential
    dpkg-buildpackage -us -uc -tc
    sudo apt install ../hw-probe_*.deb

###### Neat way

Install build scripts:

    sudo apt install devscripts
     
You may want to manually update the version of hw-probe in `debian/changelog`, just edit it in any text editor, save and run `git add .`. Note that you have to stage all changes in git by running e.g. `git add .` or `git commit -a`, because it is `3.0 (git)` in `debian/source/format` and `dpkg-buildpackage` will want to have all changes staged or commited in git before building the deb package.

Install build dependencies as a dummy package `hw-probe-build-deps`, which will denpend from other build dependencies:

    sudo mk-build-deps -r --install debian/control
     
Now build the package:

    dpkg-buildpackage -us -uc -tc -i
     
And install it (note, that it will be located one directory level up than the current directory):

    sudo apt install ../hw-probe_*.deb
     
Remove build scripts and build dependencies:

    sudo apt autoremove hw-probe-build-deps devscripts

###### Uninstall

Remove hw-probe and dependencies:

    sudo apt autoremove hw-probe

