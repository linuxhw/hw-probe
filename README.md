HW PROBE 1.6 BETA
=================

Hardware Probe Tool (hw-probe) — a tool to probe for hardware, check operability and find drivers with the help of Linux hardware database: https://linux-hardware.org

For BSD users: https://bsd-hardware.info


Contents
--------

* [ About        ](#about)
* [ Install      ](#install)
* [ Usage        ](#usage)
* [ Review       ](#review)
* [ AppImage     ](#appimage)
* [ Docker       ](#docker)
* [ Live CD/USB  ](#live-cd)
* [ Snap         ](#snap)
* [ Flatpak      ](#flatpak)
* [ Periodic run ](#periodic-run)
* [ Inventory    ](#inventory)
* [ Offline view ](#offline-view)
* [ ACPI dump    ](#acpi-dump)
* [ Operability  ](#operability)
* [ Disable logs ](#disable-logs)
* [ Privacy      ](#privacy)
* [ License      ](#license)

About
-----

Probe — is a snapshot of your computer's hardware state and logs. The tool checks operability of devices by analysis of logs and returns a permanent url to view the probe of the computer.

Share your probes and logs with Linux/BSD developers in order to debug and fix problems on your computer. Simplify inventory of hardware in your company. Please read more in [our blog](https://github.com/linuxhw/Blog/blob/master/Linux_Hardware_Blog.pdf).

If some of your computer devices doesn't work due to a missed driver then the tool will suggest a proper Linux kernel version according to the LKDDb or third-party drivers.

Sample probe: https://linux-hardware.org/?probe=b394035f90

You can create a probe of your computer with the help of [AppImage](#appimage), [Docker](#docker), [Snap](#snap), [Flatpak](#flatpak), [Live CD/USB](#live-cd) or RPM/Deb package.

By creating probes you contribute to the "HDD/SSD Desktop-Class Reliability Test" study: https://github.com/linuxhw/SMART


Install
-------

You can probe your computer by [AppImage](#appimage), [Docker](#docker), [Snap](#snap), [Flatpak](#flatpak) or [Live CD/USB](#live-cd).

Also you can install a native package (RPM, Deb, Pkg, etc.) for your Linux distribution or install from source. See install instructions in the [INSTALL.md](INSTALL.md) file.

See install instructions for BSD in the [INSTALL.BSD.md](INSTALL.BSD.md) file.


Usage
-----

Create a probe:

    sudo -E hw-probe -all -upload


Review
------

You can adjust device statuses in your probe and leave comments. Look for big green REVIEW button on the probe page.


AppImage
--------

The portable app that runs anywhere, no need to install anything. Just download [hw-probe-1.5-149-x86_64.AppImage](https://github.com/linuxhw/hw-probe/releases/download/1.5/hw-probe-1.5-149-x86_64.AppImage) and run the following command in terminal to probe your computer:

    chmod +x ./hw-probe-1.5-149-x86_64.AppImage
    sudo -E ./hw-probe-1.5-149-x86_64.AppImage -all -upload

You may need to install `fuse-libs` or `libfuse2` package if it is not pre-installed in your Linux distribution to run appimages. Also try [old AppImage](https://github.com/linuxhw/hw-probe/releases/download/1.4/hw-probe-1.4-135-x86_64.AppImage) if you have troubles to run the latest image (e.g. on ancient Linux versions).

###### Supported systems

The app runs on all 64-bit Linux distributions with `Glibc >= 2.14` including:

* Ubuntu 12.04 and newer
* Linux Mint 13 and newer
* Debian 8 and newer
* openSUSE 12.0 and newer
* Manjaro 0.8 and newer
* MX Linux 14 and newer
* ROSA Linux R1 and newer
* elementary OS 0.2 and newer
* Fedora 15 and newer (need to add `fuse-libs` package on Fedora 15, 16 and 17)
* RHEL 7 and newer
* CentOS 7 and newer
* Solus 3 and newer
* Puppy Linux 6.0 and newer (Tahr64, XenialPup64, BionicPup64, etc.)
* Clear Linux of any version
* Arch Linux of any version
* EndeavourOS 2019 and newer
* Pop!_OS 17 and newer
* Mageia 2 and newer
* Alt Linux 7 and newer
* Gentoo 12 and newer
* Sabayon 13 and newer
* Slackware 14.2 and newer
* OpenMandriva 3.0 and newer


Docker
------

You can easily create a probe on any Linux distribution without installing the tool with the help of the Docker image:

    sudo -E docker run -it \
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

If the tool is not pre-installed in your system or you have troubles with installing the tool or its dependencies (e.g. hwinfo is not available in the repository) then try one of the following Live images with hw-probe pre-installed: [Debian](https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/), [OpenMandriva](https://sourceforge.net/projects/openmandriva/files/release/), [ArcoLinux](https://sourceforge.net/projects/arcolinux-community-editions/files/).

Write the image to CD or USB drive, boot from it on your computer and create a probe (see [Usage](#usage)).


Snap
----

Install the universal Linux package:

    sudo snap install hw-probe

The `hw-probe` command should become available on the command line after installation. If not, try:

    export PATH=$PATH:/snap/bin

Connect `block-devices` interface to check SMART attributes of drives:

    sudo snap connect hw-probe:block-devices :block-devices

Now you can create computer probes:

    sudo -E hw-probe -all -upload

Note: You need a Snap runtime (`snapd` package) and `/snap` symlink to `/var/lib/snapd/snap` (by `sudo ln -s /var/lib/snapd/snap /snap`) in your system to install and run snaps (pre-installed on Ubuntu 16.04 and newer).

###### Snap Store

The app is available in the Snap Store: https://snapcraft.io/hw-probe

This is a strict snap that runs in a sandbox with limited functionality. Please enable `Access to disk block devices` in `Permissions` in order to check SMART attributes of your drives.

###### Supported systems

See list of supported Linux distributions and installation instructions here: https://snapcraft.io/docs/installing-snapd

The list of supported Linux distributions includes:

* Ubuntu 14.04 and newer
* Debian 9 and newer
* Fedora 26 and newer
* Solus 3 and newer
* Zorin 12.3 and newer


Flatpak
-------

Add a remote:

    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

Install universal package:

    flatpak install flathub org.linux_hardware.hw-probe

Now you can create computer probes:

    flatpak run org.linux_hardware.hw-probe -all -upload

Run it as root if you want to check your hard drives health.

###### App Center

Find the `Hardware Probe` application in your App Center (GNOME Software), install it and click on the desktop icon to create a probe. Enable Flatpak plugin (`gnome-software-plugin-flatpak` package for Debian/Ubuntu) and install https://dl.flathub.org/repo/flathub.flatpakrepo if needed.

Note: The 'Launch' button doesn't display the probe window currently due to [bug 552](https://gitlab.gnome.org/GNOME/gnome-software/issues/552) in GNOME Software, but the probe is still created silently in the background process. Use desktop icon instead to launch the hardware probe properly or see probe log in `$HOME/.var/app/org.linux_hardware.hw-probe/data/HW_PROBE/LOG`.

###### Flathub

The app is available in the Flathub: https://flathub.org/apps/details/org.linux_hardware.hw-probe

###### Supported systems

Out of the box:

* Endless OS 3 and newer
* Linux Mint 18.3 and newer
* Fedora 27 and newer
* CentOS 7.6 GNOME and newer
* Pop!_OS 20.04 and newer

Need to setup Flatpak (https://flatpak.org/setup/):

* elementary OS 5 and newer
* Pop!_OS 18.04 and newer
* Solus 3 and newer
* Clear Linux of any version
* Mageia 6 and newer
* openSUSE Leap 15 and newer
* RHEL 7.6 and newer
* Arch Linux
* Chrome OS


Periodic run
------------

If your distribuition is running under systemd and you want to generate and upload hw-probe report periodically, please install:

    cp -a periodic/hw-probe.{service,timer} $(systemdsystemunitdir)/

Normally systemd units dir is located at `/usr/lib/systemd/system`. You may want to get systemd unit dir by running `pkg-config --variable=systemdsystemunitdir systemd`

Enable hw-probe.timer by running:

    systemctl enable --now hw-probe.timer

This timer will execute one time per month a hw-probe.service that will generate and upload report to the database.

User may edit hw-probe.timer and change OnCalendar value to execute hw-probe report on different time period (yearly, semiannually, quarterly, etc.). Values lower than month are STRONGLY not recommended.

Inventory
---------

Since hw-probe 1.5.

Request inventory ID:

    hw-probe -generate-inventory -email YOUR@EMAIL

Mark your probes by this ID:

    sudo -E hw-probe -all -upload -i ID

Find your computers by the inventory ID on this page: https://linux-hardware.org/?view=computers

The Email is needed to get notifications if hardware failures are detected on your computer in future probes.


Offline view
------------

Since hw-probe 1.5.

Save your probes HTML view to a directory DIR for offline use:

    hw-probe -import ./DIR -inventory-id ID


ACPI dump
---------

Dump and decode ACPI table:

    sudo -E hw-probe -all -upload -dump-acpi -decode-acpi

NOTE: `acpica-tools` package should be installed


Operability
-----------

The tool checks operability of devices on board by analysis of collected log files.

| Status   | Meaning |
|----------|---------|
| works    | Driver is found and operates properly (passed static or dynamic tests) |
| limited  | Works, but with limited functionality |
| detected | Device is detected, driver is found, but not tested yet |
| failed   | Driver is not found or device is broken |
| malfunc  | Error operation of the device or driver |

You can perform additional operability sanity tests by the following command:

    sudo -E hw-probe -all -check -upload

The following tests are executed:

* graphics test by `glxgears` for both integrated and discrete graphics cards (requires `mesa-demos` package to be installed)
* drive read speed test by `hdparm` for all HDDs and SSDs
* CPU performance test by `dd` and `md5sum`
* RAM memory test by `memtester`

Execution time is about 1 min for average modern desktop hardware. You can execute particular tests using appropriate options: `-check-graphics`, `-check-hdd`, `-check-cpu` and `-check-memory`.


Disable logs
------------

You can disable collecting of unwanted logs by the `-disable A,B,C,...` option.

For example, to disable collecting of `xdpyinfo` and `xorg.conf` run:

    sudo -E hw-probe -all -upload -disable xdpyinfo,xorg.conf


Privacy
-------

Private information (including the username, machine's hostname, IP addresses, MAC addresses, UUIDs and serial numbers) is NOT uploaded to the database.

The tool uploads 32-byte prefix of salted SHA512 hash of MAC addresses and serial numbers to properly identify unique computers and hard drives. UUIDs are decorated in the same way, but formatted like regular UUIDs in order to save readability of logs. All the data is uploaded securely via HTTPS.


License
-------

This work is dual-licensed under LGPL 2.1 (or any later version) and BSD-4-Clause.
You can choose between one of them if you use this work.

`SPDX-License-Identifier: LGPL-2.1-or-later OR BSD-4-Clause`


Enjoy!
