Summary:    Check operability of computer hardware and find drivers
Name:       hw-probe
Version:    1.5
Release:    1
Group:      Development/Other
BuildArch:  noarch
License:    LGPLv2.1+
URL:        https://github.com/linuxhw/hw-probe
Source0:    hw-probe-%{version}.tar.gz
Requires:   perl
Requires:   perl-libwww-perl
Requires:   curl
Requires:   hwinfo
Requires:   dmidecode
Requires:   pciutils
Requires:   usbutils
Requires:   smartmontools
Requires:   hdparm
Requires:   sysstat
Requires:   util-linux
%ifarch %ix86 x86_64
Requires:   mcelog
%endif
%if 0%{?suse_version} || 0%{?sle_version}
Requires:   sensors
Requires:   lsb-release
Requires:   Mesa-demo-x
Requires:   acpica
%endif
%if 0%{?fedora}
Requires:   lm_sensors
Requires:   redhat-lsb-core
Requires:   mesa-demos
Requires:   acpica-tools
%endif

%define debug_package %{nil}

%description
A tool to check operability of computer hardware and upload result
to the Linux hardware database.

Probe — is a snapshot of your computer hardware state and system
logs. The tool checks operability of devices by analysis of logs
and returns a permanent url to view the probe of the computer.

The tool is intended to simplify collecting of logs necessary for
investigating hardware related problems. Just run one simple
command in the console to check your hardware and collect all the
system logs at once:

    sudo -E hw-probe -all -upload

By creating probes you contribute to the HDD/SSD Desktop-Class
Reliability Test study: https://github.com/linuxhw/SMART

%prep
%setup -q -n hw-probe-%{version}
chmod 0644 README.md

%build
# Nothing to build yet

%install
mkdir -p %{buildroot}%{_prefix}
make install prefix=%{_prefix} DESTDIR=%{buildroot}

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc README.md
%{_bindir}/%{name}
