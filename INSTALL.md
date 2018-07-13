INSTALL HOWTO
=============

HW Probe 1.4 (April 14, 2018)

This file explains how to install and setup environment for the tool in your computer.

See more info in the [README.md](https://github.com/linuxhw/hw-probe/).

Contents
--------

1. [ Requirements for Linux  ](#requirements-for-linux)
2. [ Install from Source     ](#install-from-source)
3. [ Install on Ubuntu       ](#install-on-ubuntu)
4. [ Install on Debian       ](#install-on-debian)
5. [ Install on Debian (Easy)](#install-on-debian-easy)
6. [ Install on CentOS 7     ](#install-on-centos-7)
7. [ Install on CentOS 6     ](#install-on-centos-6)
8. [ Build Debian package    ](#build-debian-package)


Requirements for Linux
----------------------

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

* mcelog
* hdparm
* systemd-tools (systemd-analyze)
* acpica-tools
* mesa-demos
* vulkan-utils
* memtester
* vulkan-utils
* rfkill
* sysstat (iostat)
* cpuid
* xinput
* vainfo
* inxi
* i2c-tools

###### Suggests

* hplip (hp-probe)
* sane-backends (sane-find-scanner)
* pnputils (lspnp)


Install from Source
-------------------

This command will install the `hw-probe` program in the `PREFIX/bin` system directory:

    sudo make install prefix=PREFIX [/usr, /usr/local, ...]

###### Remove

    sudo make uninstall prefix=PREFIX


Install on Ubuntu
-----------------

PPA: https://launchpad.net/~mikhailnov/+archive/ubuntu/hw-probe

On Ubuntu-based Linux distributions (Ubuntu, Linux Mint, Elementary OS, etc.) you can install a PPA package:

    sudo add-apt-repository universe
    sudo add-apt-repository ppa:mikhailnov/hw-probe
    sudo apt update
    sudo apt install hw-probe --no-install-recommends


Install on Debian
-----------------

Setup a PPA repository and install the package:

    su
    apt install dirmngr
    echo "deb http://ppa.launchpad.net/mikhailnov/hw-probe/ubuntu bionic main" | tee /etc/apt/sources.list.d/mikhailnov-ubuntu-hw-probe-bionic.list
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys FE3AE55CF74041EAA3F0AD10D5B19A73A8ECB754
    echo -e "Package: * \nPin: release o=LP-PPA-mikhailnov-hw-probe \nPin-Priority: 1" | tee /etc/preferences.d/mikhailnov-ubuntu-hw-probe-ppa
    apt update
    apt install hw-probe --no-install-recommends


Install on Debian (Easy)
------------------------

Install dependencies:

    su
    apt install libdigest-sha-perl curl hwinfo dmidecode pciutils usbutils smartmontools edid-decode \
    util-linux lsb-release lm-sensors mcelog wireless-tools x11-utils

Make a probe:

    su
    curl -s https://raw.githubusercontent.com/linuxhw/hw-probe/master/hw-probe.pl | perl - -all -upload


Install on CentOS 7
-------------------

Install dependencies:

    sudo yum install perl-Digest-SHA curl dmidecode pciutils usbutils smartmontools \
    lm_sensors mcelog xorg-x11-utils xorg-x11-server-utils

Install `hwinfo` and `libx86emu`:

    sudo yum install http://li.nux.ro/download/nux/dextop/el7/x86_64/hwinfo-20.2-5.3.x86_64.rpm \
    http://li.nux.ro/download/nux/dextop/el7/x86_64/libx86emu-1.1-2.1.x86_64.rpm

Make a probe:

    curl -s https://raw.githubusercontent.com/linuxhw/hw-probe/master/hw-probe.pl | sudo perl - -all -upload


Install on CentOS 6
-------------------

Install dependencies:

    sudo yum install perl-Digest-SHA curl dmidecode pciutils usbutils smartmontools \
    lm_sensors mcelog xorg-x11-utils xorg-x11-server-utils

Install `hwinfo` and `libx86emu`:

    sudo yum install http://mirror.ghettoforge.org/distributions/gf/el/6/gf/x86_64/hwinfo-20.2-1.gf.el6.x86_64.rpm \
    http://mirror.ghettoforge.org/distributions/gf/el/6/gf/x86_64/libx86emu-1.1-1.gf.el6.x86_64.rpm

Make a probe:

    curl -s https://raw.githubusercontent.com/linuxhw/hw-probe/master/hw-probe.pl | sudo perl - -all -upload


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
     
You may want to manually update the version of hw-probe in `debian/changelog`, just edit it in any text editor and save. Install build dependencies as a dummy package `hw-probe-build-deps`, which will denpend from other build dependencies:

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

