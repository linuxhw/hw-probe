Contents
--------

* [ HW PROBE 1.5 ](#hw-probe-15)
* [ HW PROBE 1.4 ](#hw-probe-14)
* [ HW PROBE 1.3 ](#hw-probe-13)
* [ HW PROBE 1.2 ](#hw-probe-12)
* [ HW PROBE 1.1 ](#hw-probe-11)
* [ HW PROBE 1.0 ](#hw-probe-10)


HW PROBE 1.5
------------

Released this on Jan 15, 2020 (200fbb5).

In this release we significantly improved anonymization of probes, added quick run-time tests for several devices and implemented more detailed identification of hardware devices on board.

**Summary:** significantly better anonymization of probes, support for MegaRAID and Adaptec RAID, simple run-time tests for memory/HDD/CPU, enabling/disabling of particular probes, better identification of devices/statuses, importing probes by inventory ID, identification of hardware/OS properties, hardware monitoring (Beta), support for universal packages.

### New Features
* Add LHWM options (Linux Hardware Monitoring) - COMING SOON!
* Support for MegaRAID (collect SMART attributes of all connected drives)
* Options to enable/disable logs in addition to current log level
* Added simple tests for memory, HDD and CPU
* Measure speed of all drives by default if `-check-hdd` option is specified
* Use `sudo -E` to preserve environment variables
* Improve anonymization of logs
* Hash all UUIDs
* Do not save uploaded data locally by default
* Clarify privacy policy
* Add `-limit-check-hdd` option to limit number of drives to check
* Add `-minimal`/`-maximal` options to easily change logging level
* Add `-confirm-upload-of-hashed-ids` alias for `-upload` option
* Import probes by inventory ID
* Require Email to generate inventory ID
* Display platform devices (for phones, routers, etc.)
* Display MMC drives
* Display real number of equal devices on board
* Probe for MegaRAID (by `storcli`, `megacli` and `megactl`)
* Probe for Adaptec RAID (by `arcconf`)
* Probe for `/lib/firmware` in the maximal log-level mode
* Collect `df -Th`
* Collect `hddtemp`
* Collect `bundle-list` on Clear Linux OS
* Collect packages list on Slackware and Solus
* Collect DE name, display server and system language
* Collect `systemd-analyze` summary
* Collect `nvme smart-log`
* Collect EDID if `edid-decode` is not installed
* Collect output of `opensc-tool` for chipcards
* Collect `Xorg.0.log` in XWayland (latest Ubuntu)
* Collect `/var/log/gpu-manager.log`
* Collect `/etc/system-release` if available
* Collect `/etc/lsb-release` if available
* Identify filesystem
* Identify monitor(s) by X11 log if proprietary driver is used
* Identify DE and display server
* Identify kind of network controllers
* Identify monitor ratio by resolution if physical size is missed
* Identify pixel density of a monitor
* Identify microarch and microcode of CPU
* Identify video memory size
* Identify total space and used space
* Identify screen area and ratio
* Identify subvendor and submodel
* Identify status of a battery
* Identify boot mode (EFI or BIOS)
* Identify nomodeset
* Identify total and used RAM
* Identify dual boot
* Identify CPU op-modes
* Identify OpenVZ, Pop!_OS and KDE neon distributions
* Identify MX Linux properly
* Identify RAM vendor by JEDEC id
* Identify RAM vendor by model prefix
* Identify SecureBoot by `dmesg`
* Identify form-factor by hard drive model
* Identify status of network devices properly
* Identify status for more device types
* Improve identifying of RAM modules, hard drives, monitors, batteries, scanners, DVB cards and fingerprint readers
* Improve identifying of computer type and form-factor
* Improve identifying of SoC vendor and model
* Improve identifying of hard drives
* Improve identifying of monitors
* Improve identifying of RAM modules
* Count NICs and monitors
* Count sockets, cores and threads
* Get missed hard drive size from `lsblk`
* Guess drive kind if missed
* Support for more Synaptics fingerprint readers
* Recursively apply status of device to low-level devices
* Detect status of devices: graphics cards, wifi cards, ethernet cards, bluetooth cards, sound cards, modems, storage controllers, monitors and batteries
* Detect status for more devices: chipcards, fingerprint readers, card readers, dvb cards, web cameras and tv cards
* Allow to run from `STDIN` and w/o any options
* `sudo` is not required for importing of probes anymore
* Extend list of invalid MAC addresses
* Improve output of -show option
* Added -show-devices option
* Access tokens are obsolete
* Print devices list in JSON
* Show probe log by a new option
* Add -save option to make offline probes
* Send probe by `libwww-perl` in case of curl failure

### Bug Fixes
* Fix analysis of Adaptec RAID
* Fix identifying of hardware ID (ignore USB network controllers)
* Fix identifying of graphics drivers
* Fix identifying of SecureBoot
* Fix identifying of video card status
* Fix identifying of processor model
* Fix identifying of unknown RAM modules
* Fix identifying of operability status for desktop graphics cards and USB wireless cards
* Fix identifying of monitor resolution
* Fix identifying of OS name
* Fix identifying of product name
* Fix identifying of device drivers in use
* Fix identifying of vendor/model for desktops and servers
* Detect status of graphics cards properly if Xorg log is not available
* Fix status of bridge devices
* Fix status of network cards in case of multiple ethernet interfaces
* Fix status of secondary graphics cards
* Fix status of graphics cards on Gentoo
* Fix counting of duplicated devices on board
* Fix collecting of `Xorg.0.log`, `xorg.conf` and `xorg.conf.d` configs
* Fix EDID parser
* Fix motherboard naming
* Fix naming of unknown memory modules
* Fix IDs of unknown memory modules and batteries
* Do not display batteries of peripheral devices
* Remove `avahi`, `lsinitrd`, `pstree` and `top` from maximal log level
* Probe for `fstab` in the default log level on ROSA Linux
* Fix error handling in the `-fix` option
* Do not try to run `smartctl` on cdroms
* Move `fstab` log from the default logging level to maximal
* Move `modinfo` to the maximal log level
* Move `alsactl` to maximal logging level
* Move `sensors`, `cpuid`, `cpuinfo` and `lscpu` to minimal set of logs
* Move `findmnt` and `mount` to maximal set of logs
* Do not collect `pstree` and `numactl` by default
* Move `sensors`, `meminfo`, `cpuid` and `cpuinfo` probes up
* Hide inet6 addr in `ifconfig` and `ip` outputs
* Hide lvm volume groups in `boot.log`, `lsblk` and `dev`
* Hide paths in `grub` config
* Hide comments in `fstab`
* Hide local paths in `df`, `lsblk`, `findmnt`, `mount`, `fstab` and `boot.log`
* Hide IPs in `dmesg`, `df`, `findmnt`, `mount` and `fstab`
* Hide labels in `lsblk` output
* Hide hostname in `dmesg` output
* Hide all serial strings in the output of `hwinfo` and `usb-devices`
* Skip hiding of commonly used terms
* Security fixes in `dmesg`, `xorg.log`, `dev`, `systemctl`, `systemd-analyze`, `fdisk` and `lsblk` logs
* Decorate occasional hostname in `boot.log`
* Decorate LABEL in `fstab`
* Fix incompatibility with `Perl 5.8`
* Fix incomplete `lspci`/`lsusb` reports
* Fix probes offline view
* Move `hwinfo --framebuffer` probe to maximal log level
* Remove `hwinfo --zip` probe
* Do not remove small `lsblk` and `efibootmgr` logs
* Fix minimal logging level
* Remove spec chars from `boot.log`
* Truncate large `boot.log` (F29, Ubuntu 18)
* Drop `curl --http1.0` option
* Compress probes by `xz -9`
* Run `mcelog` on `x86*` only
* Clear `modinfo` output
* Compacting of `modinfo` log
* Truncate large logs
* Properly detect `hwaddr`
* Clear empty logs
* Use `IO::Interface` if `ip` and `ifconfig` commands are not available
* Use `POSIX::uname` if `uname` command is not available
* Do not use `POSIX` module
* Do not dump `lspci`/`lsusb` errors
* Remove spec chars from device names
* Rename `-get-inventory-id` option to `-generate-inventory`
* Fix `glxgears` test
* Fix collected packages list on Arch Linux
* Order the list of installed RPM packages

### Other

* Add install instructions for Alpine, Arch Linux, blackPanther OS, CentOS 6/7/8, Debian, Fedora, Manjaro, openSUSE, OpenVZ 7, Puppy Linux and RHEL 6/7/8.
* Improve install instructions for Ubuntu, Manjaro, Gentoo and Puppy
* Update `Dockerfile`
* Support for old tgz compressed probes
* Protect `dmesg` log
* Remove error messages from `dmidecode` log
* Support for the new Perl `inxi`
* Added `-high-compress` option for better compression of archive
* Added `-hwinfo-path` option
* Code review by H.Merijn Brand - Tux


HW PROBE 1.4
------------

Released this on Apr 14, 2018 (3a59093).

Most significant change in this release is the anonymization of probes on the client-side. Previously "private data" (like IPs, MACs, serials, hostname, username, etc.) was removed on the server-side. But now you do not have to worry how server will handle your "private data", since it's not uploaded at all. You can now upload probes from any computers and servers w/o the risk of security leak.

**Summary:** improved privacy, faster probing, probe USB drives, probe MegaRAID, probe via sudo, improved detection of hardware, Deb package.

### New Features
1. Remove private information from probe (hostname, IPs, MACs, serials, etc.) on the client side
2. Up to 3 times faster probing of hardware
3. Allow to run the tool via `sudo`
4. Improved detection of LCD monitors, motherboards and drives
5. Collect SMART info from drives connected by USB
6. Initial support for probing drives in MegaRAID
7. Collect info about MMC controllers
8. Get EDID hex dump from `xrandr` output
9. Added Debian/Ubuntu package
10. Collecting logs in C locale
11. Added `-identify-monitor` and `-fix-edid` private options
12. Probe for `mcelog`, `slabtop`, `cpuid` and `/proc/scsi`
13. Added probe of packages list on Arch by pacman
14. Improved `lsblk` and `iostat` probes
15. Print warning if X11-related logs are not collected
16. Renamed `-group` option to `-inventory-id`
17. Renamed `-get-group` option to `-get-inventory-id`
18. Update Docker image to Alpine 3.7
19. Require `perl-Digest-SHA`
20. Change license to LGPL-2.1+

### Bug Fixes
1. Fixed `glxgears` test
2. Do not read monitor vendor names from `pnp.ids` file
3. Remove empty logs from probes
4. Fixed detection of HWid
5. Fixed notebook model names
6. Do not probe for `blkid` (use `lsblk` instead)
7. Do not probe for `mount` (use `findmnt` instead)


HW PROBE 1.3
------------

Released this on Dec 3, 2017 (d192aee).

### New Features
1. Docker image for HW Probe to run anywhere
2. Detecting NVMe drives
3. Create offline collections of probes with `-import` option
4. Collecting logs in C.UTF-8 locale
5. Added probes: vulkaninfo, iostat, vainfo, uptime, memtester, cpuinfo, i2cdetect, numactl and lsinitrd
6. Made `-dump-acpi` and `-decode-acpi` public options
7. Improved support for Alpine Linux

### Bug Fixes
1. Fixed detection of computer vendor/model
2. Fixed detection of HWid
3. Fixed collecting of X11 logs
4. Fixed xdpyinfo probe


HW PROBE 1.2
------------

Released this on Mar 9, 2017 (c5f178b).

1. Use `ip addr` command to detect hwaddr if `ifconfig` command is not available
2. Fixed `hdparm` and `smartctl` logs


HW PROBE 1.1
------------

Released this on Sep 28, 2016 (144b0b7).

1. Use secure HTTPS connection to upload probes
2. Detect release of a Linux distribution
3. Detect real Mac-address
4. Carefully detect devices on board


HW PROBE 1.0
------------

Released this on Nov 29, 2015 (4db41d1).

This is a first public release of the tool, that was used internally for testing hardware compatibility of Linux distributions since 2014.

