INSTALL HOWTO
=============

HW Probe 1.4 (April 14, 2018)

This file explains how to install and setup environment for the tool in your computer.

See more info in the [README.md](https://github.com/linuxhw/hw-probe/blob/master/README.md).

Contents
--------

1. [ Requirements for Linux ](#requirements-for-linux)
2. [ Configure and Install  ](#configure-and-install)
3. [ Ubuntu PPA             ](#ubuntu-ppa)
4. [ Build Debian package   ](#build-debian-package)


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


Configure and Install
---------------------

This command will install a hw-probe program in the `PREFIX/bin` system directory:

    sudo make install prefix=PREFIX [/usr, /usr/local, ...]

###### Remove

    sudo make uninstall prefix=PREFIX


Ubuntu PPA
----------

PPA: https://launchpad.net/~mikhailnov/+archive/ubuntu/hw-probe

###### Install on Ubuntu

On Ubuntu-based Linux distributions (Ubuntu, Linux Mint, Elementary OS, etc.) you can install a PPA package:

    sudo add-apt-repository universe
    sudo add-apt-repository ppa:mikhailnov/hw-probe
    sudo apt update
    sudo apt install hw-probe --no-install-recommends

###### Install on Debian

    su
    apt install dirmngr
    echo "deb http://ppa.launchpad.net/mikhailnov/hw-probe/ubuntu bionic main" | tee /etc/apt/sources.list.d/mikhailnov-ubuntu-hw-probe-bionic.list
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys FE3AE55CF74041EAA3F0AD10D5B19A73A8ECB754
    echo -e "Package: * \nPin: release o=LP-PPA-mikhailnov-hw-probe \nPin-Priority: 1" | tee /etc/preferences.d/mikhailnov-ubuntu-hw-probe-ppa
    apt update
    apt install hw-probe --no-install-recommends

###### Install on Debian (Easy)

Install dependencies:

    su
    apt install libdigest-sha-perl curl hwinfo dmidecode pciutils usbutils smartmontools edid-decode \
    util-linux lsb-release lm-sensors mcelog wireless-tools x11-utils

Then probe your computer by:

    su
    curl -s https://raw.githubusercontent.com/linuxhw/hw-probe/master/hw-probe.pl | perl - -all -upload


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

