INSTALL HOWTO
=============

HW Probe 1.4 (April 14, 2018)

This file explains how to install and setup environment for the tool in your computer.

See more info in the [README.md](https://github.com/linuxhw/hw-probe/).


Contents
--------

* [ Run without Installing ](#run-without-installing)
* [ Command line to Run    ](#command-line-to-run)
* [ Install on Ubuntu      ](#install-on-ubuntu)
* [ Install on Debian      ](#install-on-debian)
* [ Install on openSUSE    ](#install-on-opensuse)
* [ Install on Manjaro     ](#install-on-manjaro)
* [ Install on Arch Linux  ](#install-on-arch-linux)
* [ Install on Fedora      ](#install-on-fedora)
* [ Install on CentOS 8    ](#install-on-centos-8)
* [ Install on CentOS 7    ](#install-on-centos-7)
* [ Install on CentOS 6    ](#install-on-centos-6)
* [ Install on OpenVZ 7    ](#install-on-openvz-7)
* [ Install on RHEL 8      ](#install-on-rhel-8)
* [ Install on RHEL 7      ](#install-on-rhel-7)
* [ Install on RHEL 6      ](#install-on-rhel-6)
* [ Install on Gentoo      ](#install-on-gentoo)
* [ Install on Alpine      ](#install-on-alpine)
* [ Install on Puppy       ](#install-on-puppy)
* [ Install from Source    ](#install-from-source)

Run without Installing
----------------------

You can probe your computer by [AppImage](https://github.com/linuxhw/hw-probe/blob/master/README.md#appimage), [Docker](https://github.com/linuxhw/hw-probe#docker), [Snap](https://github.com/linuxhw/hw-probe#snap), [Flatpak](https://github.com/linuxhw/hw-probe#flatpak) or [Live CD](https://github.com/linuxhw/hw-probe#live-cd) without the need to install anything on your host.


Command line to Run
-------------------

    sudo hw-probe -all -upload


Install on Ubuntu
-----------------

On Ubuntu and Ubuntu based Linux distributions (Linux Mint, elementary OS, etc.).

###### Deb package

Download Debian package [hw-probe_1.4-1_all.deb](http://ftp.debian.org/debian/pool/main/h/hw-probe/hw-probe_1.4-1_all.deb) and install:

    sudo add-apt-repository universe
    sudo apt-get update
    sudo apt-get install ./hw-probe_1.4-1_all.deb --no-install-recommends

###### PPA

https://launchpad.net/~mikhailnov/+archive/ubuntu/hw-probe

    sudo add-apt-repository universe
    sudo add-apt-repository ppa:mikhailnov/hw-probe
    sudo apt update
    sudo apt install hw-probe --no-install-recommends

###### Snap

The [Snap package](https://github.com/linuxhw/hw-probe#snap) is also available to install and run easily on Ubuntu without the need to install any Deb packages to your system.


Install on Debian
-----------------

###### Debian Sid

Enable Unstable repository and install:

    echo "deb http://http.us.debian.org/debian unstable main non-free contrib" | sudo tee -a /etc/apt/sources.list
    sudo apt-get update
    sudo apt-get install hw-probe --no-install-recommends

###### Any Debian

Download Deb package [hw-probe_1.4-1_all.deb](http://ftp.debian.org/debian/pool/main/h/hw-probe/hw-probe_1.4-1_all.deb) and install:

    sudo apt-get update
    sudo dpkg -i ./hw-probe_1.4-1_all.deb
    sudo apt install -f --no-install-recommends


Install on openSUSE
-------------------

Setup an OBS repository and install the package:

    sudo zypper addrepo https://download.opensuse.org/repositories/hardware/openSUSE_Leap_15.0/ hardware
    sudo zypper install --no-recommends hw-probe


Install on Manjaro
------------------

For Manjaro 18 and later:

    sudo pacman -Sy hw-probe


Install on Arch Linux
---------------------

On Arch Linux and Arch Linux based Linux distributions (Antergos, ArcoLinux, Chakra, KaOS, etc.):

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


Install on CentOS 8
-------------------

    sudo yum install epel-release
    sudo yum install hw-probe


Install on CentOS 7
-------------------

    sudo yum install epel-release
    sudo yum install hw-probe

###### Old systems

    curl https://raw.githubusercontent.com/linuxhw/hw-probe/master/hw-probe.pl | sudo dd of=/usr/bin/hw-probe
    sudo chmod +x /usr/bin/hw-probe
    sudo yum install -y http://li.nux.ro/download/nux/dextop/el7/x86_64/libx86emu-1.1-2.1.x86_64.rpm
    sudo yum install -y http://li.nux.ro/download/nux/dextop/el7/x86_64/hwinfo-20.2-5.3.x86_64.rpm
    sudo yum install -y curl dmidecode smartmontools hdparm lm_sensors usbutils pciutils mcelog


Install on CentOS 6
-------------------

    sudo yum install epel-release
    sudo yum install hw-probe

###### Old systems

    curl https://raw.githubusercontent.com/linuxhw/hw-probe/master/hw-probe.pl | sudo dd of=/usr/bin/hw-probe
    sudo chmod +x /usr/bin/hw-probe
    sudo yum install -y http://mirror.ghettoforge.org/distributions/gf/el/6/gf/x86_64/libx86emu-1.1-1.gf.el6.x86_64.rpm
    sudo yum install -y http://mirror.ghettoforge.org/distributions/gf/el/6/gf/x86_64/hwinfo-20.2-1.gf.el6.x86_64.rpm
    sudo yum install -y curl dmidecode smartmontools hdparm lm_sensors usbutils pciutils mcelog


Install on OpenVZ 7
-------------------

    sudo yum install epel-release
    sudo yum install hw-probe


Install on RHEL 8
-----------------

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


Install on Gentoo
-----------------

    sudo emerge --ask sys-apps/hw-probe

###### Manual

    sudo emerge --ask sys-apps/hwinfo
    sudo emerge --ask sys-apps/pciutils
    sudo emerge --ask sys-apps/usbutils
    sudo emerge --ask sys-apps/dmidecode
    curl https://raw.githubusercontent.com/linuxhw/hw-probe/master/hw-probe.pl | sudo dd of=/usr/bin/hw-probe
    sudo chmod +x /usr/bin/hw-probe


Install on Alpine
-----------------

    sudo apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing hw-probe


Install on Puppy
----------------

For Puppy 7 and later (XenialPup64, BionicPup64, etc.):

Update local database by Menu > Setup > Puppy Package Manager > Configure > Update database > Update now.
Install `perl-base`, `hwinfo`, `util-linux` and `smartmontools` by Menu > Setup > Puppy Package Manager.

    curl https://raw.githubusercontent.com/linuxhw/hw-probe/master/hw-probe.pl | sudo dd of=/usr/bin/hw-probe
    sudo chmod +x /usr/bin/hw-probe


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

