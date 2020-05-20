INSTALL HOWTO FOR BSD
=====================

HW Probe 1.6 BETA (May 20, 2020)

This file explains how to install and setup environment for the tool in your computer.

Just find the name of your BSD distribution on this page.

See more info in the [README.md](README.md).


Contents
--------

* [ Run without Installing ](#run-without-installing)
* [ Command line to Run    ](#command-line-to-run)
* [ Install                ](#install)
* [ Install on FreeBSD     ](#install-on-freebsd)
* [ Install on OpenBSD     ](#install-on-openbsd)
* [ Install on NetBSD      ](#install-on-netbsd)
* [ Install on DragonFly   ](#install-on-dragonfly)
* [ Install on MidnightBSD ](#install-on-midnightbsd)


Run without Installing
----------------------

From Github:

    curl -s https://raw.githubusercontent.com/linuxhw/hw-probe/master/hw-probe.pl | perl

From upstream (mirror):

    curl -s http://bsd-hardware.info/hw-probe | perl


Install
-------

You need latest code from master currently, it's not packaged for BSD systems yet.

From Github:

    curl -s https://raw.githubusercontent.com/linuxhw/hw-probe/master/hw-probe.pl > /usr/bin/hw-probe
    chmod +x /usr/bin/hw-probe

From upstream (mirror):

    curl -s http://bsd-hardware.info/hw-probe > /usr/bin/hw-probe
    chmod +x /usr/bin/hw-probe

On first run the tool will ask to install missed dependencies. You can install them manually or automatically with the help of the following option:

    hw-probe -install-deps


Command line to Run
-------------------

    hw-probe -all -upload

###### Other

Execute local file:

    perl ./hw-probe -all -upload

Desktop users should enable `sudo` by installing `sudo` package and adding user to `sudoers` file (https://www.freebsd.org/doc/handbook/security-sudo.html) to preserve user environment variables:

    sudo -E hw-probe -all -upload


Install on FreeBSD
------------------

On FreeBSD and derivatives (GhostBSD, NomadBSD, FuryBSD, TrueOS, PC-BSD, FreeNAS, pfSense, Junos OS, etc.).

Get the tool:

    fetch http://bsd-hardware.info/hw-probe

Install dependencies manually:

    pkg install dmidecode smartmontools hwstat lscpu curl perl5

or automatically:

    perl hw-probe -install-deps

Probe your computer:

    perl hw-probe -all -upload

###### Old systems

For old FreeBSD releases < 9.3:

    env PACKAGESITE='http://ftp-archive.freebsd.org/pub/FreeBSD-Archive/ports/<ARCH>/packages-<FREEBSD_RELEASE>-release/Latest/' pkg_add -r dmidecode smartmontools hwstat cpuid curl perl

For older FreeBSD releases < 8.0 you need also `usbutil` package to be installed:

    pkg_add -r usbutil

For older FreeBSD releases < 7.0:

    pkg_add -r p5-Digest-SHA

Oldest supported FreeBSD version is currently 6.4.


Install on OpenBSD
------------------

On OpenBSD and derivatives (AdJ, FuguIta, etc.).

Get the tool:

    ftp http://bsd-hardware.info/hw-probe

Install dependencies manually:

    pkg_add dmidecode smartmontools usbutil lscpu curl

or automatically:

    perl hw-probe -install-deps

Probe your computer:

    perl hw-probe -all -upload

###### Old systems

For old OpenBSD releases < 6.5:

    PKG_PATH=https://ftp.nluug.nl/OpenBSD/<OPENBSD_RELEASE>/packages/<ARCH> pkg_add dmidecode smartmontools usbutil lscpu curl


Install on NetBSD
-----------------

On NetBSD and derivatives (OS108, etc.).

Get the tool:

    ftp http://bsd-hardware.info/hw-probe

Install dependencies manually:

    pkgin install dmidecode smartmontools usbutil curl perl

or automatically:

    perl hw-probe -install-deps

Probe your computer:

    perl hw-probe -all -upload


Install on DragonFly
--------------------

Get the tool:

    fetch http://bsd-hardware.info/hw-probe

Install dependencies manually:

    pkg install dmidecode smartmontools hwstat lscpu curl perl5

or automatically:

    perl hw-probe -install-deps

Probe your computer:

    perl hw-probe -all -upload


Install on MidnightBSD
----------------------

Get the tool:

    fetch http://bsd-hardware.info/hw-probe

Install dependencies manually:

    mport install dmidecode smartmontools cpuid curl perl

or automatically:

    perl hw-probe -install-deps

Probe your computer:

    perl hw-probe -all -upload


Enjoy!
