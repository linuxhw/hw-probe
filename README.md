HW PROBE 1.4
============

Hardware Probe Tool (HW Probe) — a tool to probe for hardware, check its operability and upload result to the Linux hardware database: https://linux-hardware.org

Contents
--------

1.  [ About        ](#about)
2.  [ Install      ](#install)
3.  [ Usage        ](#usage)
4.  [ Docker       ](#docker)
5.  [ Live ISO     ](#live-iso)
6.  [ Inventory    ](#inventory)
7.  [ Offline view ](#offline-view)
8.  [ ACPI dump    ](#acpi-dump)
9.  [ Operability  ](#operability)
10. [ Privacy      ](#privacy)


About
-----

Probe — is a snapshot of your computer's hardware state and system logs. HW Probe tool returns permanent URL to view the probe of the computer.

Sample probe: https://linux-hardware.org/?probe=b394035f90

Share your probes and logs with Linux developers in order to debug and fix problems on your computer. Simplify inventory of hardware in your company.

You can make a probe with the help of a script, Docker image or Linux ISO (see below).

By creating probes you contribute to the "HDD/SSD Real-Life Reliability Test" study: https://github.com/linuxhw/SMART


Install
-------

From source:

    sudo make install prefix=/usr

If you don't want to install anything to your system, then you can probe your computer by Docker image or Live ISO (see below).

See more install instructions in the [INSTALL.md](https://github.com/linuxhw/hw-probe/blob/master/INSTALL.md) file.

###### Install on Ubuntu

On Ubuntu-based Linux distributions (Ubuntu, Linux Mint, Elementary OS, etc.) you can install a PPA package:

    sudo add-apt-repository universe
    sudo add-apt-repository ppa:mikhailnov/hw-probe
    sudo apt update
    sudo apt install hw-probe --no-install-recommends

###### Requires

* Perl 5
* perl-Digest-SHA
* perl-Data-Dumper
* hwinfo (https://github.com/openSUSE/hwinfo or https://pkgs.org/download/hwinfo)
* curl
* dmidecode
* smartmontools
* pciutils
* usbutils
* edid-decode

###### Recommends

* mcelog
* hdparm
* systemd-tools
* acpica-tools
* mesa-demos
* memtester
* ... (see [INSTALL.md](https://github.com/linuxhw/hw-probe/blob/master/INSTALL.md))


Usage
-----

Make a probe:

    sudo hw-probe -all -upload -id "DESC"

DESC — any description of the probe.


Docker
------

You can easily make a probe on any Linux distribution without installing the tool with the help of the Docker image:

    sudo docker run -it \
    -v /dev:/dev:ro \
    -v /lib/modules:/lib/modules:ro \
    -v /etc/os-release:/etc/os-release:ro \
    -v /var/log:/var/log:ro \
    --privileged --net=host --pid=host \
    linuxhw/hw-probe -all -upload -id DESC

You may need to run `xhost +local:` before docker run to collect X11 info (xrandr, xinput, etc.).

Docker hub repository: https://hub.docker.com/r/linuxhw/hw-probe/


Live ISO
--------

If the tool is not pre-installed in your system or you have troubles with installing the tool or its dependencies (e.g. hwinfo is not available in the repository) then try this Linux ISO with hw-probe installed: https://mirror.yandex.ru/rosa/rosa2016.1/iso/ROSA.Fresh.R10/

Boot this Linux ISO in Live mode on your computer and make a probe (see USAGE).


Inventory
---------

Request inventory ID:

    hw-probe -get-inventory-id

Mark your probes by this ID:

    sudo hw-probe -all -upload -id DESC -inventory-id ID

Find your computers by the inventory ID on this page: https://linux-hardware.org/?view=computers


Offline view
------------

Create your probes collection view for offline use:

    sudo hw-probe -import DIR


ACPI dump
---------

Dump and decode ACPI table:

    sudo hw-probe -all -upload -dump-acpi -decode-acpi

NOTE: "acpica-tools" package should be installed


Operability
-----------

The tool checks operability of devices on board by analysis of collected log files. You can perform additional operability sanity tests by the following command:

    sudo hw-probe -all -check -upload

The following tests are executed:

* graphics test by `glxgears` (for both integrated and discrete graphics cards)
* drive read speed test by `hdparm` (for all HDDs and SSDs)
* CPU performance test by `dd` and `md5sum`
* RAM memory test by `memtester`

Execution time is about 1 min for average modern desktop hardware.


Privacy
-------

Private information (including the username, machine's hostname, IP addresses, MAC addresses and serial numbers) is NOT uploaded to the database.

The tool uploads SHA512 hash of MAC addresses and serial numbers to properly identify unique computers and hard drives. All the data is uploaded securely via HTTPS.


Enjoy!
