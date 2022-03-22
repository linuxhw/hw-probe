INSTALL HOWTO
=============

HW Probe 1.6.3 (Mar 22, 2022)

This file explains how to install and setup environment for the tool in your computer.

Just find the name of your Linux distribution or BSD variant on this page.

See more info in the [README.md](README.md).


Contents
--------

* [ Run without Installing  ](#run-without-installing)
* [ Command line to Run     ](#command-line-to-run)
* [ Install on Ubuntu       ](#install-on-ubuntu)
* [ Install on Debian       ](#install-on-debian)
* [ Install on BSD          ](#install-on-bsd)
* [ Install on Fedora       ](#install-on-fedora)
* [ Install on Manjaro      ](#install-on-manjaro)
* [ Install on Arch Linux   ](#install-on-arch-linux)
* [ Install on CentOS       ](#install-on-centos)
* [ Install on Alpine       ](#install-on-alpine)
* [ Install on ArcoLinux    ](#install-on-arcolinux)
* [ Install on blackPanther ](#install-on-blackpanther)
* [ Install on Chrome OS    ](#install-on-chrome-os)
* [ Install on Clear Linux  ](#install-on-clear-linux)
* [ Install on ClearOS      ](#install-on-clearos)
* [ Install on EasyOS       ](#install-on-easyos)
* [ Install on Endless      ](#install-on-endless)
* [ Install on Gentoo       ](#install-on-gentoo)
* [ Install on Hefftor      ](#install-on-hefftor)
* [ Install on Mageia       ](#install-on-mageia)
* [ Install on NixOS        ](#install-on-nixos)
* [ Install on OpenMandriva ](#install-on-openmandriva)
* [ Install on openSUSE     ](#install-on-opensuse)
* [ Install on OpenVZ       ](#install-on-openvz)
* [ Install on Oracle Linux ](#install-on-oracle-linux)
* [ Install on PCLinuxOS    ](#install-on-pclinuxos)
* [ Install on Puppy        ](#install-on-puppy)
* [ Install on QTS          ](#install-on-qts)
* [ Install on RHEL         ](#install-on-rhel)
* [ Install on ROSA         ](#install-on-rosa)
* [ Install on Slackware    ](#install-on-slackware)
* [ Install on Solus        ](#install-on-solus)
* [ Install on Void Linux   ](#install-on-void-linux)
* [ Install from Source     ](#install-from-source)


Run without Installing
----------------------

You can probe your computer by [AppImage](README.md#appimage), [Docker](README.md#docker), [Snap](README.md#snap), [Flatpak](README.md#flatpak) or [Live CD/USB](README.md#live-cd) without the need to install anything on your host.


Command line to Run
-------------------

    sudo -E hw-probe -all -upload


Install on Ubuntu
-----------------

On Ubuntu and Ubuntu based Linux distributions (Kubuntu, Lubuntu, Xubuntu, Linux Mint, Zorin, Pop!_OS, elementary OS, KDE neon, Peppermint, Linuxfx, Linux Lite, HamoniKR, WindowsFX, Trisquel, Makulu Linux, GalliumOS, etc.).

###### Ubuntu package

The package is available in Ubuntu 20.04 or newer and its derivatives (https://packages.ubuntu.com/focal/hw-probe):

    sudo add-apt-repository universe
    sudo apt-get update
    sudo apt-get install hw-probe --no-install-recommends

For older Ubuntu versions try package from Ubuntu 20.04: [hw-probe_1.5-1_all.deb](http://mirrors.kernel.org/ubuntu/pool/universe/h/hw-probe/hw-probe_1.5-1_all.deb)

###### Upstream package

Download Debian package [hw-probe_1.5-1_all.deb](https://github.com/linuxhw/hw-probe/releases/download/1.5/hw-probe_1.5-1_all.deb) and install:

    sudo add-apt-repository universe
    sudo apt-get update
    sudo apt-get install ./hw-probe_1.5-1_all.deb --no-install-recommends

###### Snap

The [Snap package](README.md#snap) is also available to install and run easily on Ubuntu without the need to install any Deb packages to your system.


Install on Debian
-----------------

On Debian and Debian based Linux distributions (Kali, LMDE, MX Linux, antiX, Devuan, PureOS, Parrot, Pardus, deepin, BunsenLabs, SolydXK, SparkyLinux, Q4OS, Tails, Raspbian, BigLinux, siduction, Nitrux, Kaisen, etc.).

Enable sudo by https://wiki.debian.org/sudo if not enabled.

###### Debian package

The package is available in Debian 11 Bullseye or newer and its derivatives (https://packages.debian.org/bullseye/hw-probe):

    sudo apt install hw-probe --no-install-recommends

###### Unstable package

    sudo apt-get install debian-archive-keyring
    sudo sh -c 'echo deb http://deb.debian.org/debian unstable main > /etc/apt/sources.list.d/debian-sid.list'
    sudo apt-get update
    sudo apt-get install --no-install-recommends hw-probe
    sudo rm -f /etc/apt/sources.list.d/debian-sid.list
    sudo apt-get update

###### Upstream package

Download Deb package [hw-probe_1.5-1_all.deb](https://github.com/linuxhw/hw-probe/releases/download/1.5/hw-probe_1.5-1_all.deb) and install:

    sudo apt-get update
    sudo dpkg -i ./hw-probe_1.5-1_all.deb
    sudo apt-get install -f --no-install-recommends


Install on BSD
--------------

On FreeBSD and derivatives (GhostBSD, NomadBSD, FuryBSD, TrueOS, PC-BSD, HardenedBSD, FreeNAS, TrueNAS, pfSense, OPNsense, XigmaNAS, DesktopBSD, ArisbluBSD, helloSystem, etc.), OpenBSD and derivatives (AdJ, FuguIta, etc.), NetBSD and derivatives (OS108, etc.), DragonFly and MidnightBSD.

See [INSTALL.BSD.md](INSTALL.BSD.md).


Install on Fedora
-----------------

On Fedora 28 and newer:

    sudo dnf install hw-probe


Install on Manjaro
------------------

On Manjaro 18 or newer and derivatives (Mabox, etc.):

    sudo pacman -S hw-probe

Try `sudo pacman -Syu` if pacman can't find the package.


Install on Arch Linux
---------------------

On Arch Linux and derivatives (Artix, EndeavourOS, RebornOS, Garuda, KaOS, Archman, Bluestar, LaxerOS, etc.):

###### From AUR

When using Live CD/USB you need to add `cow_spacesize=512M` boot option to have enough space.

Install edid-decode dependency:

    pacman -Syu git binutils fakeroot make gcc
    git clone https://aur.archlinux.org/edid-decode-git.git
    cd edid-decode-git
    makepkg -sri

Install hardware probe:

    git clone https://aur.archlinux.org/hw-probe.git
    cd hw-probe
    makepkg -sri

###### Upstream package

Download package [hw-probe-1.5-ArchLinux-any.pkg.tar.xz](https://github.com/linuxhw/hw-probe/releases/download/1.5/hw-probe-1.5-ArchLinux-any.pkg.tar.xz) and install by pacman:

    sudo pacman -U ./hw-probe-1.5-ArchLinux-any.pkg.tar.xz


Install on CentOS
-----------------

On CentOS 8, CentOS 7 and CentOS 6:

    sudo yum install epel-release
    sudo yum install hw-probe

###### Old systems

If installation from EPEL is not possible.

On early CentOS 7 installations:

    curl https://raw.githubusercontent.com/linuxhw/hw-probe/master/hw-probe.pl | sudo dd of=/usr/bin/hw-probe
    sudo chmod +x /usr/bin/hw-probe
    sudo yum install -y http://li.nux.ro/download/nux/dextop/el7/x86_64/libx86emu-1.1-2.1.x86_64.rpm
    sudo yum install -y http://li.nux.ro/download/nux/dextop/el7/x86_64/hwinfo-20.2-5.3.x86_64.rpm
    sudo yum install -y curl dmidecode smartmontools hdparm lm_sensors usbutils pciutils mcelog

On early CentOS 6 installations:

    curl https://raw.githubusercontent.com/linuxhw/hw-probe/master/hw-probe.pl | sudo dd of=/usr/bin/hw-probe
    sudo chmod +x /usr/bin/hw-probe
    sudo yum install -y http://mirror.ghettoforge.org/distributions/gf/el/6/gf/x86_64/libx86emu-1.1-1.gf.el6.x86_64.rpm
    sudo yum install -y http://mirror.ghettoforge.org/distributions/gf/el/6/gf/x86_64/hwinfo-20.2-1.gf.el6.x86_64.rpm
    sudo yum install -y curl dmidecode smartmontools hdparm lm_sensors usbutils pciutils mcelog


Install on Alpine
-----------------

    sudo apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing hw-probe


Install on ArcoLinux
---------------------

Pre-installed on ArcoLinux v20.11.9 and newer.


Install on blackPanther
-----------------------

On blackPanther OS 16.2 and newer:

    installing hw-probe

This command will install all the dependencies as well.


Install on Chrome OS
--------------------

Open settings, turn on support for Linux and open the Linux Terminal. Now use [AppImage](README.md#appimage) or install the [Flatpak](README.md#flatpak).


Install on Clear Linux
----------------------

See https://clearlinux.org/software/flathub/hardware-probe

    sudo swupd bundle-add desktop
    flatpak install flathub org.linux_hardware.hw-probe
    flatpak run org.linux_hardware.hw-probe -all -upload


Install on ClearOS
------------------

    sudo yum-config-manager --enable clearos-centos
    sudo yum-config-manager --enable clearos-epel
    sudo yum install hw-probe


Install on EasyOS
-----------------

Update local database by Menu > Setup > PETget Package Manager > Configure package manager > Update now.
Install `perl-base`, `libhd`, `hwinfo`, `util-linux` and `smartmontools` by Menu > Setup > PETget Package Manager.

Open the console:

    curl https://raw.githubusercontent.com/linuxhw/hw-probe/master/hw-probe.pl | dd of=/usr/bin/hw-probe
    chmod +x /usr/bin/hw-probe


Install on Endless
------------------

Search for "Hardware Probe" program in the App Center.

See https://flathub.org/apps/details/org.linux_hardware.hw-probe


Install on Gentoo
-----------------

On Gentoo and Gentoo based Linux distributions (CloudReady, Calculate, Funtoo, Redcore, LiGurOS, etc.):

    sudo emerge --ask sys-apps/hw-probe

###### Bobwya repository

With [app-eselect/eselect-repository](https://wiki.gentoo.org/wiki/Eselect/Repository) installed:

    sudo eselect repository enable bobwya
    sudo emerge --ask sys-apps/hw-probe

###### Manual

    sudo emerge --ask sys-apps/hwinfo
    sudo emerge --ask sys-apps/pciutils
    sudo emerge --ask sys-apps/usbutils
    sudo emerge --ask sys-apps/dmidecode
    curl https://raw.githubusercontent.com/linuxhw/hw-probe/master/hw-probe.pl | sudo dd of=/usr/bin/hw-probe
    sudo chmod +x /usr/bin/hw-probe


Install on Hefftor
------------------

For Hefftor 2021-01 and newer:

    sudo pacman -Syu hw-probe


Install on Mageia
-----------------

###### Upstream package

For Mageia 5 and newer:

    su
    urpmi https://github.com/linuxhw/hw-probe/releases/download/1.5/hw-probe-1.5-Mageia5.noarch.rpm edid-decode


Install on NixOS
----------------

Use [Docker](README.md#docker) or [Flatpak](README.md#flatpak).


Install on OpenMandriva
-----------------------

Pre-installed on OpenMandriva Lx 4.0 and newer.


Install on openSUSE
-------------------

Select and install an RPM package for your openSUSE distribution and derivatives (GeckoLinux, etc.): https://software.opensuse.org/package/hw-probe

openSUSE Leap 15.1:

    sudo zypper addrepo https://download.opensuse.org/repositories/hardware/openSUSE_Leap_15.1/ hardware
    sudo zypper install hw-probe

openSUSE Tumbleweed:

    sudo zypper addrepo https://download.opensuse.org/repositories/hardware/openSUSE_Tumbleweed/ hardware
    sudo zypper install hw-probe


Install on OpenVZ
-----------------

On OpenVZ 8 and OpenVZ 7:

    sudo yum install epel-release
    sudo yum install hw-probe


Install on Oracle Linux
-----------------------

On Oracle Linux 7:

    sudo yum-config-manager --add-repo=http://download.fedoraproject.org/pub/epel/7/x86_64/
    sudo yum install epel-release
    sudo yum install hw-probe

On Oracle Linux 8 use [AppImage](README.md#appimage).


Install on PCLinuxOS
--------------------

Use [AppImage](README.md#appimage).


Install on Puppy
----------------

The package is available in Puppy 9 and newer (FossaPup64, etc.):

* Open Menu > Setup > Puppy Package Manager
* Update local package database by Configure > Update database > Update now
* Find hw-probe package and install

On Puppy 7 XenialPup64 and Puppy 8 BionicPup64:

Update local package database by Menu > Setup > Puppy Package Manager > Configure > Update database > Update now.
Install `perl-base`, `hwinfo`, `util-linux` and `smartmontools` by Menu > Setup > Puppy Package Manager.

    curl https://raw.githubusercontent.com/linuxhw/hw-probe/master/hw-probe.pl | sudo dd of=/usr/bin/hw-probe
    sudo chmod +x /usr/bin/hw-probe


Install on QTS
--------------

Use [Docker](README.md#docker).


Install on RHCOS
----------------

Use [Docker](README.md#docker).


Install on RHEL
---------------

On RHEL 6-8 and RHEL based Linux distributions (CentOS, AlmaLinux, Rocky Linux, Scientific Linux, Springdale Linux, etc.):

    sudo yum install epel-release
    sudo yum install hw-probe


Install on ROSA
---------------

Pre-installed on ROSA Fresh R4 and newer.


Install on Sabayon
------------------

Use [AppImage](README.md#appimage).


Install on Slackware
--------------------

On Slackware and Slackware based Linux distributions (Porteus, etc.).

Use [AppImage](README.md#appimage), [Docker](README.md#docker) or [Flatpak](README.md#flatpak).


Install on Solus
----------------

Use [AppImage](README.md#appimage) or [Flatpak](README.md#flatpak).


Install on Void Linux
---------------------

Use [AppImage](README.md#appimage) or [Flatpak](README.md#flatpak).


Install on VzLinux
------------------

On VzLinux 8:

    sudo dnf install epel-release
    sudo dnf install hw-probe


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
* drm_info
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

Enjoy!
