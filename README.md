HW PROBE 1.3
============

Hardware Probe Tool (HW Probe) — a tool to probe for hardware, check its operability and upload result to the Linux hardware database: https://linux-hardware.org

Contents
--------

1. [ About        ](#about)
2. [ Usage        ](#usage)
3. [ Docker       ](#docker)
4. [ Live ISO     ](#live-iso)
5. [ Install      ](#install)
6. [ Inventory    ](#inventory)
7. [ Offline View ](#offline-view)

About
-----

Probe — is a snapshot of your computer's hardware state and system logs. HW Probe tool returns permanent URL to view the probe of the computer.

Sample probe: https://linux-hardware.org/?probe=b394035f90

Share your probes and logs with Linux developers in order to debug and fix problems on your computer. Simplify inventory of hardware and navigate over the computers in your company.

You can make a probe with the help of a script, Docker image or Linux ISO (see below).

Usage
-----

    sudo hw-probe -all -upload -id DESC

DESC — any description of the probe.

Docker
------

You can easily make a probe on any Linux distribution without installing the tool with the help of the Docker image:

    sudo docker run -it -v /dev:/dev:ro -v /lib/modules:/lib/modules:ro -v /etc/os-release:/etc/os-release:ro -v /var/log:/var/log:ro --privileged --net=host --pid=host linuxhw/hw-probe -all -upload -id DESC

You may need to run 'xhost +local:' before docker run to collect X11 info (xrandr, xinput, etc.).

Live ISO
--------

If the tool is not pre-installed in your system or you have troubles with installing the tool or its dependencies (e.g. hwinfo is not available in the repository) then try this Linux ISO with hw-probe installed: https://mirror.yandex.ru/rosa/rosa2016.1/iso/ROSA.Fresh.R10/

Boot this Linux ISO in Live mode on your computer and make a probe (see USAGE).

Install
-------

    sudo make install prefix=/usr

If you don't want to install anything to your system, then you can probe your computer by Docker image or Live ISO (see below).

###### Install On Debian

On Debian, Ubuntu, Mint and other Debian-based Linux distributions you can install a PPA package:

    sudo add-apt-repository ppa:mikhailnov/hw-probe
    sudo apt update
    sudo apt install hw-probe

###### Requires

* Perl 5
* hwinfo (https://github.com/openSUSE/hwinfo or https://linux-hardware.org/downloads/hwinfo/)
* curl
* dmidecode
* smartmontools (smartctl)
* pciutils (lspci)
* usbutils (lsusb)

###### Suggests

* hdparm
* edid-decode
* sysstat (iostat)
* memtester
* systemd-tools (systemd-analyze)
* ...

See full list of suggested packages in the INSTALL file.

Inventory
---------

    hw-probe -get-group
    sudo hw-probe -all -upload -id DESC -group ID

Offline View
------------

Create your probes collection view for offline use:

    sudo hw-probe -import DIR
