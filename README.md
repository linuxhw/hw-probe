HW PROBE 1.4
============

Hardware Probe Tool (HW Probe) — a tool to probe for hardware, check its operability and upload result to the Linux hardware database: https://linux-hardware.org


Contents
--------

* [ About        ](#about)
* [ Install      ](#install)
* [ Usage        ](#usage)
* [ AppImage     ](#appimage)
* [ Docker       ](#docker)
* [ Live CD      ](#live-cd)
* [ Snap         ](#snap)
* [ Flatpak      ](#flatpak)
* [ Inventory    ](#inventory)
* [ Offline view ](#offline-view)
* [ ACPI dump    ](#acpi-dump)
* [ Operability  ](#operability)
* [ Disable logs ](#disable-logs)
* [ Privacy      ](#privacy)


About
-----

Probe — is a snapshot of your computer's hardware state and system logs. HW Probe tool returns a permanent URL to view the probe of the computer.

Sample probe: https://linux-hardware.org/?probe=b394035f90

Share your probes and logs with Linux developers in order to debug and fix problems on your computer. Simplify inventory of hardware in your company.

You can make a probe of your computer with the help of [AppImage](#appimage), [Docker](#docker), [Snap](#snap), [Flatpak](#flatpak), [Live CD](#live-cd) or RPM/DEB package.

By creating probes you contribute to the "HDD/SSD Real-Life Reliability Test" study: https://github.com/linuxhw/SMART


Install
-------

You can probe your computer by [AppImage](#appimage), [Docker](#docker), [Snap](#snap), [Flatpak](#flatpak) or [Live CD](#live-cd).

Also you can install native RPM/DEB package for your Linux distribution or install from source. See all install instructions in the [INSTALL.md](https://github.com/linuxhw/hw-probe/blob/master/INSTALL.md) file.


Usage
-----

Make a probe:

    sudo hw-probe -all -upload


AppImage
--------

The portable app that runs anywhere, no need to install anything. Just download [hw-probe-1.4-129-x86_64.AppImage](https://github.com/linuxhw/hw-probe/releases/download/1.4/hw-probe-1.4-129-x86_64.AppImage) and run the following command in terminal to probe your computer:

    chmod +x ./hw-probe-1.4-129-x86_64.AppImage
    sudo ./hw-probe-1.4-129-x86_64.AppImage -all -upload

###### Supported systems

The app runs on all Linux distributions with `Glibc >= 2.14` including:

* Ubuntu 12.04 and later
* Linux Mint 13 and later
* Debian 8 and later
* openSUSE 12.0 and later
* Manjaro 0.8 and later
* ROSA Linux R1 and later
* elementary OS 0.2 and later
* Fedora 15 and later (need to add `fuse-libs` package to host on Fedora 15, 16 and 17)
* RHEL 7 and later
* CentOS 7 and later
* Mageia 2 and later
* Alt Linux 7 and later
* Gentoo 12 and later
* Sabayon 13 and later
* Slackware 14.2 and later


Docker
------

You can easily make a probe on any Linux distribution without installing the tool with the help of the Docker image:

    sudo docker run -it \
    -v /dev:/dev:ro \
    -v /lib/modules:/lib/modules:ro \
    -v /etc/os-release:/etc/os-release:ro \
    -v /var/log:/var/log:ro \
    --privileged --net=host --pid=host \
    linuxhw/hw-probe -all -upload

You may need to run `xhost +local:` before docker run to collect X11 info (xrandr, xinput, etc.).

Docker hub repository: https://hub.docker.com/r/linuxhw/hw-probe/


Live CD
-------

If the tool is not pre-installed in your system or you have troubles with installing the tool or its dependencies (e.g. hwinfo is not available in the repository) then try this Linux CD with hw-probe installed: https://mirror.yandex.ru/rosa/rosa2016.1/iso/ROSA.Fresh.R10/

Boot this Linux CD on your computer and make a probe (see [Usage](#usage)).


Snap
----

Install the universal Linux package:

    sudo snap install hw-probe --classic

The `hw-probe` command should become available on the command line after installation. If not, try:

    export PATH=$PATH:/snap/bin

Now you can create computer probes:

    sudo hw-probe -all -upload

NOTE: You need a Snap runtime (`snapd` package) and `/snap` symlink to `/var/lib/snapd/snap` (by `sudo ln -s /var/lib/snapd/snap /snap`) in your system to install and run snaps (pre-installed on Ubuntu 16.04 and later).

###### Snap Store

The app is available in the Snap Store: https://snapcraft.io/hw-probe

This is a strict snap that runs in a sandbox with limited functionality. It's better to use classic snap (see above) to collect more info about the computer.

Install app from Store:

    sudo snap install hw-probe

Connect system interfaces:

    for i in hardware-observe mount-observe network-observe \
    system-observe upower-observe log-observe raw-usb \
    physical-memory-observe opengl;do sudo snap connect hw-probe:$i :$i; done

Now you can create computer probes:

    sudo hw-probe -all -upload

###### Supported systems

* Ubuntu 14.04 and later
* Debian 9 and later
* Fedora 26 and later


Flatpak
-------

Add a remote:

    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

Install universal package:

    flatpak install flathub org.linux_hardware.hw-probe

Now you can create computer probes:

    flatpak run org.linux_hardware.hw-probe -all -upload

###### App Center

Find the `Hardware Probe` application in your App Center, install it and click on the desktop icon to make a probe. Enable Flatpak plugin if needed (`gnome-software-plugin-flatpak` package for Debian/Ubuntu).

Note: The 'Launch' button doesn't display the probe window currently due to [bug 552](https://gitlab.gnome.org/GNOME/gnome-software/issues/552) in GNOME Software, but the probe is still created silently in the background process. Use desktop icon instead to launch the hardware probe properly or see probe log in `$HOME/.var/app/org.linux_hardware.hw-probe/data/HW_PROBE/LOG`.

###### Flathub

The app is available in the Flathub: https://flathub.org/apps/details/org.linux_hardware.hw-probe


Inventory
---------

Request inventory ID:

    hw-probe -get-inventory-id

Mark your probes by this ID:

    sudo hw-probe -all -upload -inventory-id ID

Find your computers by the inventory ID on this page: https://linux-hardware.org/?view=computers


Offline view
------------

Save your probes HTML view to a directory for offline use:

    sudo hw-probe -import DIR


ACPI dump
---------

Dump and decode ACPI table:

    sudo hw-probe -all -upload -dump-acpi -decode-acpi

NOTE: `acpica-tools` package should be installed


Operability
-----------

The tool checks operability of devices on board by analysis of collected log files. You can perform additional operability sanity tests by the following command:

    sudo hw-probe -all -check -upload

The following tests are executed:

* graphics test by `glxgears` (for both integrated and discrete graphics cards, requires `mesa-demos` package to be installed)
* drive read speed test by `hdparm` (for all HDDs and SSDs)
* CPU performance test by `dd` and `md5sum`
* RAM memory test by `memtester`

Execution time is about 1 min for average modern desktop hardware.


Disable logs
------------

You can disable collecting of unwanted logs by the `-disable A,B,C,...` option.

For example, to disable collecting of `lsblk` and `xorg.conf` run:

    sudo hw-probe -all -upload -disable lsblk,xorg.conf


Privacy
-------

Private information (including the username, machine's hostname, IP addresses, MAC addresses and serial numbers) is NOT uploaded to the database.

The tool uploads SHA512 hash of MAC addresses and serial numbers to properly identify unique computers and hard drives. All the data is uploaded securely via HTTPS.


Enjoy!
