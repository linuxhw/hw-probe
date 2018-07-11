INSTALL HOWTO
=============

HW Probe 1.4 (April 14, 2018)

This file explains how to install and setup environment for the tool in your computer.

Contents
--------

1. [ Requirements for Linux ](#requirements-for-linux)
2. [ Configure and Install  ](#configure-and-install)
3. [ Ubuntu PPA             ](#ubuntu-ppa)
4. [ Build Debian package   ](#build-debian-package)
5. [ Usage                  ](#usage)
6. [ Live ISO               ](#live-iso)
7. [ Docker                 ](#docker)
8. [ Privacy                ](#privacy)


Requirements for Linux
----------------------

* Perl 5
* perl-Digest-SHA
* perl-Data-Dumper
* hwinfo
* curl
* dmidecode
* smartmontools
* pciutils
* usbutils
* edid-decode

###### Recommends

* hdparm
* sysstat
* systemd-tools
* acpica
* mesa-demos
* vulkan-utils
* memtester
* rfkill
* xinput
* vainfo
* mcelog
* cpuid
* inxi
* i2c-tools

###### Suggests

* hplip
* numactl
* pnputils


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


Usage
-----

Make a probe and upload result to the DB (`DESC` — any description of the probe):

    sudo hw-probe -all -upload -id "DESC"


Live ISO
--------

The Live ISO with hw-probe installed: https://mirror.yandex.ru/rosa/rosa2016.1/iso/ROSA.Fresh.R10/

Boot this Linux ISO in Live mode on your computer and make a probe (see Usage).


Docker
------

You can easily make a probe on any Linux distribution without installing the tool with the help of the Docker image:

    sudo docker pull linuxhw/hw-probe
    sudo docker run -it \
    -v /dev:/dev:ro \
    -v /lib/modules:/lib/modules:ro \
    -v /etc/os-release:/etc/os-release:ro \
    -v /var/log:/var/log:ro \
    --privileged --net=host --pid=host \
    linuxhw/hw-probe -all -upload -id DESC

You may need to run `xhost +local:` before docker run to collect X11 info (xrandr, xinput, etc.).


Privacy
-------

Private information (including the username, machine's hostname, IP addresses, MAC addresses and serial numbers) is NOT uploaded to the database.

The tool uploads SHA512 hash of MAC addresses and serial numbers to properly identify unique computers and hard drives. All the data is uploaded securely via HTTPS.


Enjoy!
