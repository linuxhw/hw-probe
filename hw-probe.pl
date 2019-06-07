#!/usr/bin/perl
#########################################################################
# Hardware Probe Tool 1.4
# A tool to probe for hardware and upload result to the Linux Hardware DB
#
# WWW: https://linux-hardware.org
#
# Copyright (C) 2014-2019 Andrey Ponomarenko's Linux Hardware Project
#
# Written by Andrey Ponomarenko
# LinkedIn: https://www.linkedin.com/in/andreyponomarenko
#
# PLATFORMS
# =========
#  Linux (Fedora, Ubuntu, Debian, Mint, Arch,
#         Gentoo, ROSA, Mandriva, Alpine ...)
#
# REQUIRES
# ========
#  Perl 5
#  perl-Digest-SHA
#  perl-Data-Dumper
#  hwinfo (https://github.com/openSUSE/hwinfo or https://pkgs.org/download/hwinfo)
#  curl
#  dmidecode
#  smartmontools (smartctl)
#  pciutils (lspci)
#  usbutils (lsusb)
#  edid-decode
#
# RECOMMENDS
# ==========
#  libwww-perl (if curl is missed)
#  mcelog
#  hdparm
#  systemd-tools (systemd-analyze)
#  acpica-tools
#  mesa-demos
#  vulkan-utils
#  memtester
#  rfkill
#  sysstat (iostat)
#  cpuid
#  xinput
#  vainfo
#  inxi
#  i2c-tools
#  opensc
#
# SUGGESTS
# ========
#  hplip (hp-probe)
#  sane-backends (sane-find-scanner)
#  pnputils (lspnp)
#  avahi
#  numactl
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301 USA
#########################################################################
use Getopt::Long;
Getopt::Long::Configure ("posix_default", "no_ignore_case");
use File::Path qw(mkpath rmtree);
use File::Temp qw(tempdir);
use File::Copy qw(copy move);
use File::Basename qw(basename dirname);
use Cwd qw(abs_path cwd);

my $TOOL_VERSION = "1.4";
my $CmdName = basename($0);

my $URL = "https://linux-hardware.org";
my $GITHUB = "https://github.com/linuxhw/hw-probe";

my $LOCALE = "C";
my $ORIG_DIR = cwd();

my $TMP_DIR = tempdir(CLEANUP=>1);

my $ShortUsage = "Hardware Probe Tool $TOOL_VERSION
A tool to probe for hardware and upload result to the Linux hardware DB
License: GNU LGPL 2.1+

Usage: sudo $CmdName [options]
Example: sudo $CmdName -all -upload\n\n";

my $SNAP_DESKTOP = (defined $ENV{"BAMF_DESKTOP_FILE_HINT"});
my $FLATPAK_DESKTOP = (grep { $_ eq "-flatpak" } @ARGV);

if($#ARGV==0 and grep { $ARGV[0] eq $_ } ("-snap", "-flatpak"))
{ # Run by desktop file
    print "Executing hw-probe -all -upload\n\n";
    system("hw-probe ".$ARGV[0]." -all -upload");
    if($SNAP_DESKTOP or $FLATPAK_DESKTOP)
    { # Desktop
        sleep(60);
    }
    exit(0);
}

if($#ARGV==-1)
{
    print $ShortUsage;
    exit(1);
}

my %Opt;

GetOptions("h|help!" => \$Opt{"Help"},
  "v|version!" => \$Opt{"ShowVersion"},
  "dumpversion!" => \$Opt{"DumpVersion"},
# Main options
  "all!" => \$Opt{"All"},
  "probe!" => \$Opt{"Probe"},
  "logs!" => \$Opt{"Logs"},
  "log-level=s" => \$Opt{"LogLevel"},
  "minimal|mini|min!" => \$Opt{"Minimal"},
  "maximal|maxi|max!" => \$Opt{"Maximal"},
  "enable=s" => \$Opt{"Enable"},
  "disable=s" => \$Opt{"Disable"},
  "printers!" => \$Opt{"Printers"},
  "scanners!" => \$Opt{"Scanners"},
  "check!" => \$Opt{"Check"},
  "check-graphics!" => \$Opt{"CheckGraphics"},
  "check-hdd!" => \$Opt{"CheckHdd"},
  "limit-check-hdd=s" => \$Opt{"LimitCheckHdd"},
  "check-memory!" => \$Opt{"CheckMemory"},
  "check-cpu!" => \$Opt{"CheckCpu"},
  "id|name=s" => \$Opt{"PC_Name"},
  "upload!" => \$Opt{"Upload"},
  "hwinfo-path=s" => \$Opt{"HWInfoPath"},
# Other
  "src|source=s" => \$Opt{"Source"},
  "save=s" => \$Opt{"Save"},
  "fix=s" => \$Opt{"FixProbe"},
  "show-devices!" => \$Opt{"ShowDevices"},
  "show!" => \$Opt{"Show"},
  "compact!" => \$Opt{"Compact"},
  "verbose!" => \$Opt{"Verbose"},
  "pci-ids=s" => \$Opt{"PciIDs"},
  "usb-ids=s" => \$Opt{"UsbIDs"},
  "sdio-ids=s" => \$Opt{"SdioIDs"},
  "pnp-ids=s" => \$Opt{"PnpIDs"},
  "list!" => \$Opt{"ListProbes"},
  "clean!" => \$Opt{"Clean"},
  "debug|d!" => \$Opt{"Debug"},
  "dump-acpi!" => \$Opt{"DumpACPI"},
  "decode-acpi!" => \$Opt{"DecodeACPI"},
  "import=s" => \$Opt{"ImportProbes"},
  "inventory-id|group|g=s" => \$Opt{"Group"},
  "generate-inventory-id|get-inventory-id|get-group!" => \$Opt{"GetGroup"},
# Private
  "docker!" => \$Opt{"Docker"},
  "appimage!" => \$Opt{"AppImage"},
  "snap!" => \$Opt{"Snap"},
  "flatpak!" => \$Opt{"Flatpak"},
  "low-compress!" => \$Opt{"LowCompress"},
  "high-compress!" => \$Opt{"HighCompress"},
  "identify-drive=s" => \$Opt{"IdentifyDrive"},
  "identify-monitor=s" => \$Opt{"IdentifyMonitor"},
  "decode-acpi-from=s" => \$Opt{"DecodeACPI_From"},
  "decode-acpi-to=s" => \$Opt{"DecodeACPI_To"},
  "fix-edid!" => \$Opt{"FixEdid"},
  "rm-log=s" => \$Opt{"RmLog"},
  "truncate-log=s" => \$Opt{"TruncateLog"},
  "key=s" => \$Opt{"Key"}
) or die "\n".$ShortUsage;

my $PROBE_DIR = "/root/HW_PROBE";

if($Opt{"Snap"}) {
    $PROBE_DIR = $ENV{"SNAP_USER_COMMON"}."/HW_PROBE";
}
elsif($Opt{"Flatpak"})
{
    $TMP_DIR = "/var".$TMP_DIR;
    mkpath($TMP_DIR);
    
    $PROBE_DIR = $ENV{"XDG_DATA_HOME"}."/HW_PROBE";
}

my $DATA_DIR = $PROBE_DIR."/LATEST/hw.info";
my $LOG_DIR = $DATA_DIR."/logs";
my $TEST_DIR = $DATA_DIR."/tests";
my $PROBE_LOG = $PROBE_DIR."/LOG";

my $HelpMessage="
NAME:
  Hardware Probe Tool ($CmdName)
  A tool to probe for hardware and upload result to the Linux hardware DB

DESCRIPTION:
  Hardware Probe Tool (HW Probe) is a tool to probe for hardware,
  check its operability and upload result to the Linux hardware DB.
  
  By creating probes you contribute to the \"HDD/SSD Real-Life Reliability
  Test\" study: https://github.com/linuxhw/SMART

  This tool is free software: you can redistribute it and/or modify it
  under the terms of the GNU LGPL 2.1+.

USAGE:
  sudo $CmdName [options]

EXAMPLE:
  sudo $CmdName -all -upload

PRIVACY:
  Private information (including the username, machine's hostname, IP addresses,
  MAC addresses and serial numbers) is NOT uploaded to the database.
  
  The tool uploads salted SHA512 hash of MAC addresses and serial numbers to
  properly identify unique computers and hard drives. All the data is uploaded
  securely via HTTPS.

INFORMATION OPTIONS:
  -h|-help
      Print this help.
  
  -v|-version
      Print version info.

  -dumpversion
      Print the tool version ($TOOL_VERSION) and don't do anything else.

GENERAL OPTIONS:
  -all
      Enable all probes.
  
  -probe
      Probe for hardware. Collect only
      hardware related logs.
  
  -logs
      Collect system logs.
  
  -log-level N
      Set the logging level to N.
      Available values:
      
        - minimal
        - default
        - maximal
  
  -minimal|-min
      Collect minimal number of logs. Equal to --log-level=min.
  
  -maximal|-max
      Collect maximal number of logs. Equal to --log-level=max.
  
  -enable LIST
      Comma separated list of logs to enable in addition to
      current log level.
  
  -disable LIST
      Comma separated list of logs to disable in current
      log level. Some logs cannot be disabled. For example,
      you can disable collecting of 'fstab', but you cannot
      disable logging of 'smartctl'.
  
  -printers
      Probe for printers.
  
  -scanners
      Probe for scanners.
  
  -check
      Check devices operability.
  
  -id|-name DESC
      Any description of the probe.
  
  -upload
      Upload result to the Linux hardware DB. You will get a
      permanent URL to view the probe.
  
  -hwinfo-path PATH
      Path to a local hwinfo binary.

INVENTORY OPTIONS:
  -inventory-id ID
      Mark the probe by inventory ID. You can generate it
      by the -generate-inventory-id option.
  
  -generate-inventory-id
      Generate new inventory ID.

OTHER OPTIONS:
  -save DIR
      Save probe package to DIR. This is useful if you are offline
      and need to upload a probe later (with the help of -src option).
  
  -src|-source PATH
      A probe to upload.
  
  -fix PATH
      Update list of devices and host info
      in the probe using probe data.
  
  -show-devices
      Show devices list.
  
  -show
      Show host info and devices list.
  
  -verbose
      Use with -show option to show type and status of the device.
  
  -pci-ids  PATH
  -usb-ids  PATH
  -sdio-ids PATH
  -pnp-ids  PATH
      Path to {pci,usb,sdio,pnp}.ids file to read missed device names.
  
  -list
      List executed probes (for debugging).
  
  -clean
      Remove the probe data after the probe is uploaded.
  
  -debug|-d
      The probe is for debugging purposes only.
  
  -dump-acpi
      Probe for ACPI table.
  
  -decode-acpi
      Decode ACPI table.
  
  -import DIR
      Import probes from the database to DIR for offline use.
      
      If you are using Snap or Flatpak package, then DIR will be created
      in the sandbox data directory.

DATA LOCATION:
  Probes are saved in the $PROBE_DIR directory.

";

# Hardware
my %HW;
my %HW_Count;
my %KernMod;
my %WorkMod;
my %WLanInterface;
my %PermanentAddr;

my %HDD;
my %HDD_Info;
my %MMC;
my %MMC_Info;

my $Board_ID;
my $CPU_ID;
my %ComponentID;
my %Monitor_ID;

my %DeviceIDByNum;
my %DeviceNumByID;
my %DriveNumByFile;
my %DeviceAttached;
my %GraphicsCards;
my %GraphicsCards_All;
my %UsedNetworkDev;

my $MIN_BAT_CAPACITY = 30;

my @G_DRIVERS_INTEL = ("i915", "i915_bpo", "gma500_gfx");
my @G_DRIVERS = ("nvidia", "nouveau", "radeon", "amdgpu", "fglrx", @G_DRIVERS_INTEL);

my %DriverVendor = (
    "i915"    => "8086",
    "nouveau" => "10de",
    "nvidia"  => "10de",
    "radeon"  => "1002",
    "amdgpu"  => "1002",
    "fglrx"   => "1002"
);

foreach (@G_DRIVERS_INTEL) {
    $DriverVendor{$_} = "8086";
}

my $PCI_DISK_BUS = "nvme";

# System
my %Sys;

# Settings
my $Admin = ($>==0);

# Fixing
my $FixProbe_Pkg;
my $FixProbe_Logs;
my $FixProbe_Tests;

# PCI and USB IDs
my %PciInfo;
my %PciInfo_D;
my %PciClass;

my %PciVendor = (
    "8086" => "Intel",
    "17aa" => "Lenovo",
    "14a4" => "Lite-On",
    "1987" => "Phison",
    "144d" => "Samsung",
    "1b4b" => "SanDisk",
    "126f" => "Silicon Motion",
    "1c5c" => "SK hynix",
    "1179" => "Toshiba"
);

my %UsbInfo;
my %UsbVendor;
my %UsbClass;

# JEDEC IDS
my %VendorJedec = (
    "A Force"   => ["7F7F7F7F7F7F7F02"],
    "ADATA"     => ["04CB", "7F7F7F7FCB000000"],
    "Aeneon"    => ["7F7F7F7F7F570000"],
    "Apacer"    => ["017A", "7F7A", "7A01"],
    "ASint"     => ["06C1", "7F7F7F7F7F7FC100"],
    "Avant"     => ["7F7F7F7F7FF70000"],
    "Centon"    => ["7F7F7F1900000000"],
    "Corsair"   => ["029E", "9E02", "7F7F9E0000000000"],
    "Crucial"   => ["059B", "859B", "9B85", "9B05", "0D9B", "09B8", "7F7F7F7F7F9B0000", "7F7F7F7F7F9BFFFF", "0000000000009B85", "859<"],
    "Elpida"    => ["00FE", "01FE", "02FE", "FE02", "7F7FFE0000000000", "0000000000FE7F7F"],
    "EUDAR"     => ["847C"],
    "EVGA"      => ["08D9"],
    "Foxline"   => ["88F2"],
    "G-Alantic" => ["08F7"],
    "G.Skill"   => ["04CD", "7F7F7F7FCD000000", "04=>"],
    "Golden Empire" => ["7F7F7F1300000000"],
    "Goldenmars" => ["7F7F7F7F7F620000"],
    "GOODRAM"   => ["075D", "7F7F7F7F7F7F7F5D"],
    "Infineon"  => ["C100", "C10"],
    "Innodisk"  => ["86F1"],
    "Hexon"     => ["7F7F7F7F7FDC0000"],
    "High Bridge" => ["07E9"],
    "Kingmax"   => ["7F7F7F2500000000", "7F7F7F2500000000"],
    "Kingston"  => ["0198", "7F98", "9804", "F789", "9806", "9805"],
    "KingTiger" => ["7F7F7F7F7F7F7F10"],
    "Kllisre"   => ["89C2"],
    "Kreton"    => ["85E3", "7F7F7F7F7FE30000"],
    "MCI Computer" => ["7F7F640000000000"],
    "Micron"    => ["002C", "802C", "857F", "2C00", "C200", "2CFF", "2C80", "2C0", "C20", "2C", "08D0", "009C162C0000", "FFFFFFFFFFFFFF2C", "0000000000002C80"],
    "Mougol"    => ["4B0"],
    "Nanya"     => ["830B", "030B", "0B83", "0B0D", "7F7F7F0B00000000", "F7F7F7B000000000"],
    "Netlist"   => ["7F7F7F1600000000"],
    "OCZ"       => ["84B0", "7F7F7F7FB0000000"],
    "Patriot"   => ["8502", "7F7F7F7F7F020000"],
    "PNY"       => ["01BA", "7FBA"],
    "pqi"       => ["853E", "7F7F7F7F7F3E0000"],
    "Qimonda"   => ["7F7F7F7F7F510000", "5145", "F7F7F7F7F7150000", "80C1"],
    "Ramaxel"   => ["7F7F7F7F43000000", "04430000802C", "7F7F7F7F7F000000", "000000437F7F7F7F"],
    "Samsung"   => ["00CE", "80CE", "00EC", "CE00", "CE80", "0CE", "EC0", "CE0", "000000000000CE80", "CE80", "CE30"],
    "SanMax"    => ["86E9"],
    "Silicon Power" => ["86D3", "7F7F7F7F7F7FD300"],
    "SiS"       => ["7F7F7F7F7F7FA800"],
    "SK hynix"  => ["00AD", "DA00", "6F2B", "80AD", "AD00", "ADFF", "AD01", "AD80", "000000000000AD80", "00000000000000AD", "AD0", "DA0", "0AD8", "009C35230000"],
    "Smart"     => ["7F94"],
    "Swissbit"  => ["7F7F7FDA00000000"],
    "TakeMS"    => ["7F7F7F5800000000", "7F7F7F58FFFFFFFF"],
    "Team"      => ["04EF", "EF04", "7F7F7F7FEF000000"],
    "Teikon"    => ["079E"],
    "Transcend" => ["014F", "7F4F"],
    "TwinMOS"   => ["866B", "066B"]
);

my %JedecVendor;
foreach my $V (sort keys(%VendorJedec))
{
    foreach (sort @{$VendorJedec{$V}}) {
        $JedecVendor{$_} = $V;
    }
}

my %VendorRam = (
    "A Force"  => ["1GX64V", "256X64M", "25664Y"],
    "ADATA"    => ["AD7", "AM1U", "EL7YG", "HYOPE"],
    "AMD"      => ["AE32G", "AE34G", "AP34G", "AE38G", "AP38G", "R33", "R53", "R73", "R74", "R93"],
    "Atermiter"=> ["Atermiter"],
    "ATP"      => ["AQ12M"],
    "Axiom"    => ["51264Y"],
    "Apacer"   => ["76.", "78."],
    "Apotop"   => ["U3A"],
    "ASint"    => ["B1YJ", "B2YJ", "B3KJ", "C1RE", "SSA", "SSY", "SSZ", "SLA", "SLZ"],
    "Avant"    => ["F6456"],
    "BiNFUL"   => ["BINFUL"],
    "Corsair"  => ["CMK", "CMR", "CMS", "CMU", "CMV"],
    "Crucial"  => ["BLS", "BLT", "BLE", "CT256", "CT512", "CT1024", "CT4G", "CT8G", "CT16G", "RM256", "RM512", "ST256", "ST512", "ZC256", "RM1024"],
    "CSX"      => ["V01L", "V01D"],
    "Dexcom"   => ["L23 06/11 DEXCOM"],
    "Dynet"    => ["DNHMAU"],
    "Exceleram"=> ["E301", "E408"],
    "EVGA"     => ["08G-D3"],
    "Foxline"  => ["FL1", "FL2"],
    "G.Skill"  => ["F3-", "F4-"],
    "GeIL"     => ["CL9-9", "CL9-10", "CL10-10", "CL10-11", "CL11-11", "CL11-12"], # Golden Empire
    "Goldkey"  => ["GKE", "GKH", "BKH"],
    "Goldenmars" => ["GMT"],
    "GOODRAM"  => ["GR400", "GR667", "GR800", "GR1", "GR2", "GY1", "IR2400"],
    "Hexon"    => ["HEXON"],
    "High Bridge" => ["HB3SU"],
    "Kembona"  => ["KBN"],
    "Ketech"   => ["KETECH"],
    "Kingmax"  => ["FLF", "FLG"],
    "Kingston" => ["KHX", "ACR", "ASU", "D3L16", "KN2M", "SNY", "TSB"],
    "KingTiger"=> ["KingTiger000000000"],
    "Kllisre"  => ["KRE-", "Kllisre"],
    "KomputerBay" => ["KB_8G", "KB8G"],
    "Kreton"   => ["51634x"],
    "Markvision" => ["MARKVISION"],
    "MDT"      => ["MDT"],
    "Memox"    => ["LN-SD"],
    "MemoWise" => ["MW0"],
    "Micron"   => ["16JSF", "8JSF", "8JTF"],
    "Mushkin"  => ["991769", "992017", "991529", "991558", "991713", "992070"],
    "Nanya"    => ["NT1", "NT2", "NT4", "NT8", "M2F", "M2S"],
    "Netlist"  => ["NL8"],
    "Novatech" => ["N3S"],
    "OCZ"      => ["OCZ"],
    "Panasonic"=> ["CFW5W"],
    "Patriot"  => ["PSD", "1600EL", "1600LL", "1866EL", "186C0", "2000EL", "2133 CL11 Series", "2666 C15 Series", "2666 C16 Series", "2800 C16 Series", "3200 C16 Series"],
    "PNY"      => ["64C0M", "4GBH"],
    "PSC"      => ["AS8F8G73D-DJ2"],
    "Qimonda"  => ["64T1280", "64T64", "64T12"],
    "Qumo"     => ["QUM"],
    "Ramaxel"  => ["RMT", "RMN", "RMR"],
    "Ramos"    => ["EMB", "EWB", "RMB"],
    "Reboto"   => ["Reboto"],
    "Saikano"  => ["Saikano"],
    "Samsung"  => ["M378B", "M393B", "M4 70T", "M471"],
    "SGS/Thomson" => ["SD-D2", "SD-D3"],
    "SHARETRONIC" => ["SHARETRONIC"],
    "Silicon Power" => ["DBLT", "DBST", "DCLT", "SP00", "ESRD"],
    "SK hynix" => ["HMT", "4GBPC1333512", "4GBPC", "HMP", "HYMP", "MMXIV", "MPP"],
    "Smart"    => ["SH564"],
    "Super Talent" => ["SUPERTALENT02"],
    "Swissbit" => ["SEU"],
    "TakeMS"   => ["TMS"],
    "Team"     => ["Team-Eli", "Team--El", "TEAM", "Dark", "Vulcan"],
    "Teikon"   => ["TML", "TMT"],
    "Tigo"     => ["Tigo"],
    "Transcend"=> ["JM1", "JM2", "JM667", "JM800", "TS64", "TS128", "TS256"],
    "TwinMOS"  => ["9DEEB", "9DHTB", "9DETB", "8DP25KK", "8DE25KK", "7D-23KK"],
    "Unifosa"  => ["GU3", "GU5", "GU6", "HU5", "HU6"],
    "Unknown"  => ["GRPFD"],
    "V-Color"  => ["VCOLOR"],
    "Veineda"  => ["M08GD16P"],
    "Visipro"  => ["T4G86U1"],
    "Walton Chaintech" => ["AU4G"]
);

my %RamVendor;
foreach my $V (sort keys(%VendorRam))
{
    foreach (sort @{$VendorRam{$V}}) {
        $RamVendor{$_} = $V;
    }
}

my %DiskVendor = (
    "ACJ"       => "KingSpec",
    "ACS"       => "KingSpec",
    "AXM"       => "ADATA",
    "C3-60G"    => "SenDisk",
    "CF Card"   => "SanDisk",
    "CHA"       => "KingSpec",
    "CHN25SATA" => "Zheino",
    "CT"        => "Crucial",
    "D2C"       => "OCZ",
    "D2R"       => "OCZ",
    "DB40"      => "SanDisk",
    "DEN"       => "OCZ",
    "FASTDISK"  => "FASTDISK",
    "FB0"       => "HP",
    "FLD"       => "Foxline",
    "G2242"     => "BIWIN",
    "G3 Series" => "Myung",
    "GB0"       => "HP",
    "GB1000EA"  => "HP",
    "Gen2A400"  => "Anobit",
    "GKH84"     => "Goldkey",
    "GOODRAM"   => "GOODRAM",
    "HDS"       => "Hitachi",
    "HDT"       => "Hitachi",
    "HUA"       => "Hitachi",
    "HFS"       => "SK hynix",
    "HT"        => "Hitachi",
    "IC25"      => "IBM/Hitachi",
    "IC35"      => "IBM/Hitachi",
    "IM2S"      => "ADATA",
    "InM2"      => "Indilinx",
    "IR_SSDPR"  => "GOODRAM",
    "IR-SSDPR"  => "GOODRAM",
    "M4-CT"     => "Crucial",
    "MB1000"    => "HP",
    "MB2000G"   => "HP",
    "MBG4"      => "Samsung",
    "MD0"       => "Magnetic Data",
    "MD"        => "MicroData",
    "MKN"       => "Mushkin",
    "MTF"       => "Micron",
    "MZM"       => "Samsung",
    "OOS500G"   => "Seagate",
    "OOS1000G"  => "Seagate",
    "OOS2000G"  => "Seagate",
    "PH2"       => "LITEON",
    "PH6-CE"    => "Plextor",
    "Q200 EX"   => "Toshiba",
    "Q-180"     => "KingSpec",
    "Q-360"     => "KingSpec",
    "R3S"       => "AMD",
    "R5S"       => "AMD",
    "RDM"       => "Ramaxel",
    "RTMMB"     => "China",
    "S10T"      => "Chiprex",
    "S8M"       => "Chiprex",
    "S9M"       => "Chiprex",
    "SG9"       => "Samsung",
    "SPK"       => "KingSpec",
    "SSD2SC\\d+" => "PNY",
    "SSDPAMM"   => "Intel",
    "SSDPR_CX"  => "GOODRAM",
    "SSDSA2S"   => "Intel",
    "ST"        => "Seagate",
    "SU04G"     => "SanDisk",
    "SU08G"     => "SanDisk",
    "TE2"       => "SanDisk",
    "TEAML5"    => "Team",
    "TP00"      => "China",
    "TS"        => "Transcend",
    "USDU1"     => "Transcend",
    "VB0"       => "HP",
    "VK0"       => "HP",
    "WD"        => "WDC",
    "WL"        => "WD MediaMax",
    "XUNZHE"    => "XUNZHE",
    "ZALMAN"    => "ZALMAN"
);

# http://standards-oui.ieee.org/oui.txt
my %IeeeOui = (
    "0014ee" => "WDC",
    "000c50" => "Seagate",
    "0004cf" => "Seagate",
    "00080d" => "Toshiba",
    "000039" => "Toshiba",
    "001b44" => "SanDisk",
    "000cca" => "HGST",
    "0024e9" => "Samsung",
    "002538" => "Samsung",
    "0026b7" => "Kingston",
    "00000e" => "Fujitsu",
    "5cd2e4" => "Intel",
    "002303" => "Lite-On",
    "6479a7" => "Phison",
    "ace42e" => "SK hynix"
);

my %SerialVendor = (
    "WD" => "WDC",
    "OCZ" => "OCZ",
    "PNY" => "PNY"
);

my %FirmwareVendor = (
    "MZ4O" => "Toshiba"
);

my $DEFAULT_VENDOR = "China";

my %DistSuffix = (
    "res7" => "rels-7",
    "res6" => "rels-6",
    "vl7"  => "virtuozzo-7",
    "vl6"  => "virtuozzo-6"
);

my %ChassisType = (
    1  => "Other",
    2  => "Unknown",
    3  => "Desktop",
    4  => "Low Profile Desktop",
    5  => "Pizza Box",
    6  => "Mini Tower",
    7  => "Tower",
    8  => "Portable",
    9  => "Laptop",
    10 => "Notebook",
    11 => "Hand Held",
    12 => "Docking Station",
    13 => "All In One",
    14 => "Sub Notebook",
    15 => "Space-saving",
    16 => "Lunch Box",
    17 => "Main Server Chassis",
    18 => "Expansion Chassis",
    19 => "Sub Chassis",
    20 => "Bus Expansion Chassis",
    21 => "Peripheral Chassis",
    22 => "RAID Chassis",
    23 => "Rack Mount Chassis",
    24 => "Sealed-case PC",
    25 => "Multi-system",
    26 => "CompactPCI",
    27 => "AdvancedTCA",
    28 => "Blade",
    29 => "Blade Enclosing",
    30 => "Tablet",
    31 => "Convertible",
    32 => "Detachable",
    33 => "IoT Gateway",
    34 => "Embedded PC",
    35 => "Mini PC",
    36 => "Stick PC"
);

my $DESKTOP_TYPE = "desktop|nettop|all in one|lunch box|space\-saving|mini|tower|server|rack|blade";
my $MOBILE_TYPE  = "notebook|laptop|portable|tablet|convertible|detachable|docking";
my $SERVER_TYPE  = "server|rack|blade";

my $HID_BATTERY = "wacom|wiimote|hidpp_|controller_|hid\-";

# SDIO IDs
my %SdioInfo;
my %SdioVendor;

# PCI and USB IDs (Additional)
my %AddPciInfo;
my %AddPciInfo_D;
my %AddUsbInfo;

# SDIO IDs (Additional)
my %AddSdioInfo;
my %AddSdioVendor;

# PNP IDs
my %PnpVendor;

my %SdioType = (
    "01" => "uart",
    "02" => "bluetooth",
    "03" => "bluetooth",
    "04" => "gps",
    "05" => "camera",
    "06" => "phs",
    "07" => "network",
    "08" => "ata",
    "09" => "bluetooth"
);

# Fix monitor vendor
my %MonVendor = (
    "ACH" => "Achieva Shimian", # QHD270
    "ACI" => "Ancor Communications", # ASUS
    "ACR" => "Acer",
    "ADI" => "ADI",
    "AIC" => "Arnos Instruments", # AG Neovo
    "AMR" => "JVC",
    "AMT" => "AMT International",
    "AMW" => "AMW",
    "AOC" => "AOC",
    "AOP" => "AOpen",
    "APP" => "Apple Computer",
    "ASB" => "Prestigio", # ASBIS
    "ATV" => "Ativa",
    "AUO" => "AU Optronics",
    "AUS" => "ASUS",
    "BBK" => "BBK",
    "BBY" => "Insignia",
    "BEK" => "Beko",
    "BNQ" => "BenQ",
    "BOE" => "BOE",
    "BTC" => "RS",
    "CMI" => "InnoLux Display",
    "CMN" => "Chimei Innolux",
    "CMO" => "Chi Mei Optoelectronics",
    "CND" => "CND",
    "COR" => "CPT", # Chunghwa Picture Tubes
    "CPT" => "CPT",
    "CPQ" => "Compaq Computer",
    "CTL" => "CTL",
    "CTX" => "CTX",
    "DEL" => "Dell",
    "DNS" => "DNS",
    "DON" => "DENON",
    "DVM" => "RoverScan",
    "DWE" => "Daewoo",
    "EIZ" => "Eizo",
    "ELA" => "ELSA",
    "ELE" => "Element",
    "ELO" => "Elo Touch",
    "EMA" => "eMachines",
    "ENC" => "Eizo",
    "ENV" => "Envision Peripherals",
    "EPI" => "Envision",
    "FUS" => "Fujitsu Siemens",
    "GRU" => "Grundig",
    "GSM" => "Goldstar",
    "GTW" => "Gateway",
    "GWD" => "GreenWood",
    "GWY" => "Gateway",
    "HAI" => "Haier",
    "HAR" => "Haier",
    "HCM" => "HCL",
    "HEC" => "Hitachi",
    "HED" => "Hedy",
    "HII" => "Higer",
    "HIQ" => "Hyundai ImageQuest",
    "HIT" => "Hitachi",
    "HKC" => "HKC",
    "HRE" => "Haier",
    "HSD" => "HannStar",
    "HSG" => "Hannspree",
    "HSL" => "Hansol",
    "HSP" => "HannStar",
    "HTC" => "Hitachi",
    "HWP" => "HP",
    "HPN" => "HP",
    "HUG" => "Hugon",
    "IBM" => "IBM",
    "IGM" => "Videoseven",
    "INL" => "InnoLux Display",
    "IQT" => "Hyundai ImageQuest",
    "IVM" => "Iiyama",
    "IVO" => "InfoVision",
    "JDI" => "JDI", # Japan Display Inc.
    "JEN" => "Jean",
    "JVC" => "JVC",
    "KOA" => "Konka",
    "KTC" => "KTC",
    "LCA" => "Lacie",
    "LCD" => "Toshiba",
    "LCS" => "Lenovo",
    "LEN" => "Lenovo",
    "LGD" => "LG Display",
    "LGP" => "LG Philips",
    "LNX" => "Lanix",
    "LPL" => "LG Philips",
    "LTN" => "Lite-On",
    "LRN" => "Doffler",
    "MAX" => "Belinea",
    "MEA" => "Medion",
    "MEC" => "Medion Akoya",
    "MED" => "Medion",
    "MEI" => "Panasonic",
    "MEL" => "Mitsubishi",
    "MSC" => "Syscom",
    "MSI" => "MSI",
    "MS_" => "Sony",
    "MST" => "MStar",
    "MTC" => "Mitac",
    "MZI" => "Digital Vision",
    "NCI" => "NECCI",
    "NCP" => "PANDA", # Nanjing CEC Panda
    "NEC" => "NEC",
    "NON" => "Positivo",
    "NVD" => "Nvidia",
    "NVT" => "Novatek",
    "OCM" => "oCOSMO",
    "ONK" => "Onkyo",
    "ONN" => "ONN",
    "ORN" => "Orion",
    "PEA" => "Pegatron",
    "PHL" => "Philips",
    "PIO" => "Pioneer",
    "PKB" => "Packard Bell",
    "PKR" => "Parker",
    "PKV" => "Thomson",
    "PLN" => "Planar",
    "PNR" => "Planar",
    "POS" => "Positivo",
    "PRE" => "Prestigio",
    "PTS" => "Plain Tree Systems",
    "QBL" => "QBell",
    "QDS" => "Quanta Display",
    "QMX" => "Gericom",
    "QWA" => "Lenovo",
    "ROL" => "Rolsen",
    "RUB" => "Rubin",
    "SAM" => "Samsung",
    "SAN" => "Sanyo",
    "SCE" => "Sun",
    "SDC" => "Samsung",
    "SEC" => "Samsung", # Seiko Epson
    "SEK" => "Seiki",
    "SEM" => "Samsung",
    "SHP" => "Sharp",
    "SNY" => "Sony",
    "SPT" => "Sceptre Tech",
    "STC" => "Sampo",
    "STK" => "S2-Tek",
    "STN" => "Samsung",
    "SUN" => "Sun",
    "SYN" => "Olevia",
    "SZM" => "Mitac",
    "TAR" => "Targa Visionary",
    "TCL" => "TCL",
    "TEU" => "Relisys",
    "TLX" => "Tianma XM",
    "TNJ" => "Toppoly",
    "TOP" => "TopView",
    "TOS" => "Toshiba",
    "TPV" => "Top Victory",
    "TSB" => "Toshiba",
    "UMC" => "UMC",
    "UPS" => "UpStar",
    "VBX" => "VirtualBox",
    "VES" => "Vestel Elektronik",
    "VIZ" => "Vizio",
    "VSC" => "ViewSonic",
    "WDE" => "Westinghouse",
    "WDT" => "Westinghouse",
    "WET" => "Westinghouse",
    "WOR" => "COMPAL",
    "YAK" => "Yakumo",
    "ZRN" => "Zoran",
    "_YM" => "Samsung"
);

my @UnknownMonVendor = (
    "AAA",
    "ADP",
    "AGO",
    "AMT",
    "ARS", # Prestigio?
    "AVO",
    "AQU",
    "BBY",
    "BGT",
    "CDR",
    "CHD",
    "CHE",
    "CHI",
    "CHR",
    "CTV",
    "CVT",
    "CYX",
    "DCL",
    "DDL",
    "DGI",
    "DPL",
    "DTV",
    "EXP",
    "FNI",
    "FRT",
    "GDH",
    "GER",
    "GLE",
    "GVT",
    "JRY",
    "JXJ",
    "HCG",
    "HHT",
    "HSI",
    "HYO",
    "IFS",
    "IPS", # Songren?
    "IOD",
    "ITE",
    "KDC",
    "KET",
    "KNK",
    "KTC",
    "LLP",
    "LLL",
    "LSC",
    "LTM",
    "MIT",
    "MOT", # MotoAttach?
    "MTD",
    "NEX",
    "NOD",
    "NTS",
    "NXG",
    "ONB",
    "PAR",
    "PKV",
    "PNP",
    "PPP",
    "PTF",
    "PVS",
    "RCA",
    "ROW",
    "RRR",
    "RTD",
    "RTK",
    "RX_",
    "SAC",
    "SIS",
    "SKK",
    "SKY",
    "SMC",
    "STD",
    "SYK",
    "TVT",
    "UME",
    "UTV",
    "VIE",
    "VID",
    "VMO",
    "VST",
    "WIN",
    "WST",
    "WYT",
    "DVI",
    "XXX",
    "XYY",
    "___"
);

# Repair vendor of some motherboards and mmc devices
# It is needed for catalog of public reports on github
my %VendorModels = (
    "ASRock" => [
        "4CoreDual-VSTA",
        "4CoreDual-SATA2",
        "4Core1600-GLAN",
        "4Core1600-D800",
        "4CoreN73PV-HD720p",
        "775XFire-RAID",
        "775XFire-RAID",
        "775VM800",
        "775Twins-HDTV",
        "775i945GZ",
        "775i65PE",
        "775i48",
        "939Dual-SATA2",
        "939NF6G-VSTA",
        "945GCM-S",
        "ALiveDual-eSATA2",
        "ALiveNF4G-DVI",
        "ALiveNF6P-VSTA",
        "ALiveNF6G-GLAN",
        "ALiveNF7G-HDready",
        "ALiveSATA2-GLAN",
        "AM2NF6G-VSTA",
        "G31M-S",
        "K8NF4G-SATA2",
        "K8Upgrade-NF3",
        "P4VM900-SATA2",
        "P4VM890",
        "P4Dual-915GL",
        "P4i48",
        "P4i65G",
        "P4i65GV",
        "P4VM8",
        "Wolfdale1333-GLAN",
        "Wolfdale1333-D667",
        "775Dual-VSTA",
        "775Dual-880Pro",
        "A780GXE/128M"
    ],
    "ECS" => [
        "848P-A7",
        "965PLT-A",
        "H110M4-C2H",
        "K8M800-M2",
        "nForce4-A939",
        "nForce4-A754",
        "nForce",
        "nVidia-nForce",
        "RS480-M"
    ],
    "ASUSTek Computer" => [
        "C51MCP51",
        "P5GD1-TMX/S",
        "RC410-SB450"
    ],
    "MSI" => [
        "MS-7210",
        "MS-7030",
        "MS-7025",
        "MS-7210 100"
    ],
    "SiS Technology" => [
        "SiS-661",
        "SiS-649",
        "SiS-648FX",
        "SiS-650GX"
    ],
    "Samsung" => [
        "AWMB3R",
        "CJNB4R",
        "MAG2GC",
        "MCG8GA",
        "MCG8GC"
    ],
    "SanDisk" => [
        "DF4032",
        "DF4064",
        "DF4128",
        "SDW64G",
        "SL32G"
    ],
    "SK hynix" => [
        "HBG4a",
        "HBG4e",
        "HCG8e"
    ],
    "OEM" => [
        "EIRD-SAM"
    ]
);

my %VendorByModel;
foreach my $V (sort keys(%VendorModels))
{
    foreach (sort @{$VendorModels{$V}}) {
        $VendorByModel{$_} = $V;
    }
}

my %PciClassType = (
    "01"    => "storage",
    "02"    => "network",
    "03"    => "graphics card",
    "04"    => "multimedia",
    "04-00" => "video",
    "04-01" => "sound",
    "04-03" => "sound",
    "05"    => "memory controller",
    "05-00" => "ram memory",
    "06"    => "bridge",
    "07"    => "communication controller",
    "07-03" => "modem",
    "08"    => "system peripheral",
    "08-05" => "sd host controller",
    "09"    => "input",
    "0a"    => "docking station",
    "0b"    => "processor",
    "0b-40" => "co-processor",
    "0c"    => "serial bus controller",
    "0c-00" => "firewire controller",
    "0c-03" => "usb controller",
    "0c-02" => "ssa",
    "0c-05" => "smbus",
    "0c-06" => "infiniband",
    "0c-09" => "canbus",
    "0d"    => "wireless controller",
    "0d-00" => "irda",
    "0d-11" => "bluetooth",
    "0e"    => "intelligent controller",
    "0f"    => "communications controller",
    "10"    => "encryption controller",
    "11"    => "signal processing",
    "12"    => "processing accelerators"
);

my %UsbClassType = (
    "01" => "audio",
    "02" => "network",
    "02-02" => "modem",
    "03" => "human interface",
    "03-01-01" => "keyboard",
    "03-01-02" => "mouse",
    "05" => "physical interface",
    "06" => "imaging",
    "07" => "printer",
    "08" => "storage",
    "08-06-50" => "disk",
    "09" => "hub",
    "0a" => "cdc data",
    "0b" => "smartcard",
    "0c" => "content security",
    "0e" => "video",
    "dc" => "diagnostic",
    "e0" => "wireless",
    "e0-01-01" => "bluetooth",
    "ef" => "miscellaneous",
    "58" => "xbox"
);

my %BatType = (
    "lithium-ion" => "Li-ion",
    "LiIon" => "Li-ion",
    "lithium-polymer" => "Li-poly"
);

my @WrongAddr = (
    # MAC/clientHash(MAC)
    "00-00-00-00-00-00",
    "9B615E889BC3EDDF63600C8DAA6D56CC",
    "FF-FF-FF-FF-FF-FF",
    "2F847FFB96ED2B0B7C2AB39815DC6545",
    # Huawei modem
    "0C-5B-8F-27-9A-64",
    "F8AFE52EC893B5F610764246CE0EC5DD",
    # Qualcomm Atheros AR8151
    "00-20-07-01-16-06",
    "2698F3BD50B6E7317C050EABCBFCDD61",
    # Realtek RTL8111/8168/8411
    "00-0B-0E-0F-00-ED",
    "B65E4A84BDF8C8FAF775D824E93895E5",
    "ED-0B-00-00-E0-00",
    "C8725A03752162516AC1D2736D4BCA7D",
    # NVIDIA Ethernet Controller
    "04-4B-80-80-80-03",
    "390043493F55307CC32EBD5A69443418",
    "04-4B-80-80-80-04",
    "5CEE6D893998E9F34E1452DFD0AD4127",
    "04-4B-80-80-80-F0",
    "3EEAB05124DE1FB83AD0BEAD31CE981E",
    # Others
    "00-DD-00-00-00-00",
    "631A71585F7CE74AE0C6E575DD1F4B31",
    "88-88-88-88-87-88",
    "FD0368E31788DE08AEC3C0F414D65552",
    "00-00-00-00-00-05",
    "4291656957E4CF9952D94E3DEF386CBF",
    "00-FF-00-00-00-00",
    "779F2E940C240A44289BB71F86A99BE5",
    "00-00-00-00-00-30",
    "6A34F992175D0D2ACD794FB107791EBF",
    "00-00-00-00-00-10",
    "CB29E07B8A25732D808E4DF3B26718E2",
    "00-13-74-00-00-00",
    "E5A433E40C7D5C05E1F82A0C86983656"
);

my @ProtectedLogs = (
    "acpidump",
    "acpidump_decoded",
    "biosdecode",
    "cpuid",
    "dev",
    "dmidecode",
    "dmi_id",
    "edid",
    "ethtool_p",
    "hciconfig",
    "hdparm",
    "hwinfo",
    "ifconfig",
    "ip_addr",
    "lsb_release",
    "lsmod",
    "lspci",
    "lspci_all",
    "lsusb",
    "mmcli",
    "opensc-tool",
    "os-release",
    "power_supply",
    "smartctl",
    "smartctl_megaraid",
    "system-release",
    "upower",
    "usb-devices",
    "xrandr",
    "xrandr_providers"
);

my @ProtectFromRm = (
    "dmesg",
    "dmesg.1"
);

my $USE_DIGEST = 0;
my $USE_DUMPER = 0;

my $HASH_LEN_CLIENT = 32;
my $SALT_CLIENT = "GN-4w?T]>r3FS/*_";

my $MAX_LOG_SIZE = 1048576; # 1Mb
my @LARGE_LOGS = ("xorg.log", "xorg.log.1", "dmesg", "dmesg.1", "boot.log");
my $EMPTY_LOG_SIZE = 150;

sub getSha512L($$)
{
    my ($String, $Len) = @_;
    my $Hash = undef;
    
    if($USE_DIGEST) {
        $Hash = Digest::SHA::sha512_hex($String);
    }
    else
    { # No module installed
        $Hash = qx/echo -n \'$String\' | sha512sum/;
        $Hash=~s/\A([\da-f]+).*?\Z/$1/;
    }
    
    return substr($Hash, 0, $Len);
}

sub clientHash($)
{
    my $Subj = $_[0];
    return uc(getSha512L($Subj."+".$SALT_CLIENT, $HASH_LEN_CLIENT));
}

sub encryptSerialsInPaths($)
{
    my $Content = $_[0];
    
    my %DiskSer = ();
    while($Content=~/((\/|^)(ata|nvme|scsi)-[^\s]*_)(.+?)(\-part|[\s\n,])/mg) {
        $DiskSer{$4} = 1;
    }
    
    foreach my $Ser (sort keys(%DiskSer))
    {
        my $Enc = clientHash($Ser);
        $Content=~s/_\Q$Ser\E\b/_$Enc/g; # /dev/disk/by-id/ata-Samsung_SSD_850_EVO_250GB_XXXXXXXXXXXXXXX
    }
    
    $Content=~s/(\/usb-[^\s]*_).+?([\s\n,]|\-[\da-z])/$1...$2/g;
    
    return $Content;
}

sub encryptSerials(@)
{
    my $Content = shift(@_);
    my $Tag = shift(@_);
    
    my $Name = undef;
    if(@_) {
        $Name = shift(@_);
    }
    
    my $Lower = undef;
    if(@_) {
        $Lower = shift(@_);
    }
    
    my %Serials = ();
    while($Content=~/\Q$Tag\E\s*[:=]\s*"?([^"]+?)"?\s*\n/g) {
        $Serials{$1} = 1;
    }
    foreach my $Ser (sort keys(%Serials))
    {
        if(grep {$Ser eq $_} ("Not Specified", "To Be Filled By O.E.M.")
        or index($Ser, ":")!=-1) {
            next;
        }
        
        my $Enc = undef;
        
        if($Lower) {
            $Enc = clientHash(lc($Ser));
        }
        else {
            $Enc = clientHash($Ser);
        }
        
        $Content=~s/(\Q$Tag\E\s*[:=]\s*"?)\Q$Ser\E("?\s*\n)/$1$Enc$2/g;
        
        if($Name and $Name eq "hwinfo") {
            $Content=~s/_\Q$Ser\E\b/_$Enc/g; # /dev/disk/by-id/ata-Samsung_SSD_850_EVO_250GB_XXXXXXXXXXXXXXX
        }
    }
    return $Content;
}

sub encryptWWNs($)
{
    my $Content = $_[0];
    my %WWNs = ();
    while($Content=~/\/wwn-0x(.+?)\W/g) {
        $WWNs{$1} = 1;
    }
    foreach my $WWN (sort keys(%WWNs))
    {
        my $Enc = clientHash($WWN);
        $Content=~s/(wwn-0x)\Q$WWN\E/$1$Enc/g; # wwn-0xXXXXXXXXXXXXXXXX
    }
    return $Content;
}

sub hideWWNs($)
{
    my $Content = $_[0];
    $Content=~s/(LU WWN Device Id:\s*\w \w{6} )\w+(\n|\Z)/$1...$2/;
    $Content=~s/(IEEE EUI-64:\s*\w{6}\s)\w+(\n|\Z)/$1...$2/;
    return $Content;
}

sub hideTags($$)
{
    my ($Content, $Tags) = @_;
    $Content=~s/(($Tags)\s*[:=]\s*).*?(\n|\Z)/$1...$3/g;
    return $Content;
}

sub hideHostname($)
{
    my $Content = $_[0];
    $Content=~s/(Set hostname to\s+).+/$1.../g;
    return $Content;
}

sub hidePaths($)
{
    my $Content = $_[0];
    foreach my $Dir ("mnt", "mount", "home", "media", "data", "shares", "vhosts", "mapper") {
        $Content = hideByRegexp($Content, qr/$Dir\/([^\s]+)/);
    }
    return $Content;
}

sub hideIPs($)
{
    my $Content = $_[0];
    
    # IPv4
    $Content=~s/\d+\.\d+\.\d+\.\d+/XXX.XXX.XXX.XXX/g;
    
    # IPv6
    $Content=~s/[\da-f]+\:\:[\da-f]+\:[\da-f]+\:[\da-f]+\:[\da-f]+/XXXX::XXX:XXX:XXX:XXX/gi;
    $Content=~s/[\da-f]+\:[\da-f]+\:[\da-f]+\:[\da-f]+\:[\da-f]+\:[\da-f]+\:[\da-f]+\:[\da-f]+/XXXX:XXXX:XXXX:XXXX:XXXX:XXXX:XXXX:XXXX/gi;
    
    return $Content;
}

sub hideUrls($)
{
    my $Content = $_[0];
    $Content=~s{[\w\-]+\.[\w\.\-]+\:\/[^\s]+}{XXX:/XXX}g;
    $Content=~s{(\w+\:\/+)[^\s]+}{$1\XXX}g;
    return $Content;
}

sub hidePass($)
{
    my $Content = $_[0];
    $Content=~s/.*password.*/XXXXXXXXXX/gi;
    return $Content;
}

sub hideMACs($)
{
    my $Content = $_[0];
    $Content=~s/[\da-f]{2}\:[\da-f]{2}\:[\da-f]{2}\:[\da-f]{2}\:[\da-f]{2}\:[\da-f]{2}/XX:XX:XX:XX:XX:XX/gi;
    return $Content;
}

sub encryptMACs($)
{
    my $Content = $_[0];
    my @MACs = ($Content=~/[\da-f]{2}\:[\da-f]{2}\:[\da-f]{2}\:[\da-f]{2}\:[\da-f]{2}\:[\da-f]{2}/gi);
    foreach my $MAC (@MACs)
    {
        my $Enc = lc($MAC);
        $Enc=~s/\:/-/g;
        $Enc = clientHash($Enc);
        $Content=~s/\Q$MAC\E/$Enc/gi;
    }
    return $Content;
}

sub hideByRegexp(@)
{
    my ($Content, $Regexp) = @_;
    
    my $Subj = undef;
    if(@_) {
        $Subj = shift(@_);
    }
    
    my @Matches = ($Content=~/$Regexp/gi);
    foreach my $Match (@Matches)
    {
        $Content = hideStr($Content, $Match);
        
        if($Subj)
        {
            if($Subj eq "systemd")
            {
                if($Match=~s/\x2d/-/g) {
                    $Content = hideStr($Content, $Match);
                }
            }
        }
    }
    
    return $Content;
}

sub hideStr($$)
{
    my ($Content, $Str) = @_;
    my $Hide = "X" x length($Str);
    $Content=~s/\Q$Str\E/$Hide/g;
    return $Content;
}

sub decorateSystemd($)
{
    my $Content = $_[0];
    $Content = hideByRegexp($Content, qr/systemd-cryptsetup@(.+?)\.service/, "systemd");
    return $Content;
}

sub exitStatus($)
{
    my $St = $_[0];
    if($Opt{"Flatpak"} and -d $TMP_DIR) {
        rmtree($TMP_DIR);
    }
    exit($St);
}

sub printMsg($$)
{
    my ($Type, $Msg) = @_;
    if($Type!~/\AINFO/) {
        $Msg = $Type.": ".$Msg;
    }
    if($Type!~/_C\Z/) {
        $Msg .= "\n";
    }
    if(grep { $Type eq $_ } ("ERROR", "WARNING")) {
        print STDERR $Msg;
    }
    else {
        print $Msg;
    }
}

sub checkModule($)
{
    my $Name = $_[0];
    foreach my $P (@INC)
    {
        if(-e "$P/$Name") {
            return 1;
        }
    }
    
    return 0;
}

sub runCmd($)
{
    my $Cmd = $_[0];
    
    if($Opt{"ListProbes"}) {
        print "Executing: ".$Cmd."\n";
    }
    
    return `LC_ALL=$LOCALE $Cmd`;
}

sub getOldProbeDir()
{
    my $SubDir = "HW_PROBE";
    my $Dir = undef;
    
    if(my $Home = $ENV{"HOME"}) {
        $Dir = $Home."/".$SubDir;
    }
    
    if($Dir and $Dir eq $PROBE_DIR)
    {
        $Dir = undef;
        
        if(my $SessUser = getUser()) {
            $Dir = "/home/".$SessUser."/".$SubDir;
        }
    }
    
    return $Dir;
}

sub getGroup()
{
    my $GroupURL = $URL."/get_group.php";
    
    my $Log = "";
    
    if(checkCmd("curl"))
    {
        my $CurlCmd = "curl -s -S -f -POST -F get=group -H \"Expect:\" $GroupURL"; # --http1.0
        $Log = qx/$CurlCmd 2>&1/;
    }
    else {
        $Log = postRequest($GroupURL, { "get"=>"group" }, "NoSSL");
    }
    
    print $Log;
    if($?)
    {
        my $ECode = $?>>8;
        printMsg("ERROR", "failed to get group, curl error code \"".$ECode."\"");
        exitStatus(1);
    }
    
    if($Log=~/(Group|Inventory) ID: (\w+)/)
    {
        my $ID = $2;
        my $GroupLog = "INVENTORY\n=====\n".localtime(time)."\nInventory ID: $ID\n";
        appendFile($PROBE_LOG, $GroupLog."\n");
    }
}

sub postRequest($$$)
{
    my ($UploadURL, $Data, $SSL) = @_;
    
    require LWP::UserAgent;
    
    my $UAgent = LWP::UserAgent->new(parse_head => 0);
    
    if($SSL eq "NoSSL" or not checkModule("Mozilla/CA.pm"))
    {
        $UploadURL=~s/\Ahttps:/http:/g;
        $UAgent->ssl_opts(verify_hostname => 0, SSL_verify_mode => 0x00);
    }
    
    my $Res = $UAgent->post(
        $UploadURL,
        Content_Type => "form-data",
        Content => $Data
    );
    
    my $Out = $Res->{"_content"};
    
    if(not $Out) {
        return $Res->{"_headers"}{"x-died"};
    }
    
    return $Out;
}

sub getRequest($$)
{
    my ($UploadURL, $SSL) = @_;
    
    require LWP::UserAgent;
    
    my $UAgent = LWP::UserAgent->new(parse_head => 0);
    
    if($SSL eq "NoSSL" or not checkModule("Mozilla/CA.pm"))
    {
        $UploadURL=~s/\Ahttps:/http:/g;
        $UAgent->ssl_opts(verify_hostname => 0, SSL_verify_mode => 0x00);
    }
    
    $UAgent->agent("Mozilla/5.0 (X11; Linux x86_64; rv:50.0) Gecko/20100101 Firefox/50.123");
    
    my $Res = $UAgent->get($UploadURL);
    
    my $Out = $Res->{"_content"};
    
    if(not $Out) {
        return $Res->{"_headers"}{"x-died"};
    }
    
    return $Out;
}

sub saveProbe($)
{
    my $To = $_[0];

    $To=~s{/+\Z}{};

    my ($Pkg, $HWaddr) = createPackage();
    
    if(not $Pkg) {
        return;
    }
    
    move($Pkg, $To);
    
    print "Saved to: $To/".basename($Pkg)."\n";
}

sub uploadData()
{
    my ($Pkg, $HWaddr) = createPackage();
    
    if(not $Pkg) {
        return;
    }
    
    my $UploadURL = $URL."/upload_result.php";
    my $Salt = getSha512L($SALT_CLIENT, 10);
    
    # upload package
    my @Cmd = ("curl", "-s", "-S", "-f", "-POST");
    my %Data = ();
    
    @Cmd = (@Cmd, "-F file=\@".$Pkg);
    $Data{"file"} = [$Pkg];
    
    @Cmd = (@Cmd, "-F hwaddr=$HWaddr");
    $Data{"hwaddr"} = $HWaddr;
    
    if($Opt{"Debug"})
    {
        @Cmd = (@Cmd, "-F debug=1");
        $Data{"debug"} = "1";
    }
    
    if($Opt{"Docker"})
    {
        @Cmd = (@Cmd, "-F docker=1");
        $Data{"docker"} = "1";
    }
    
    if($Opt{"AppImage"})
    {
        @Cmd = (@Cmd, "-F appimage=1");
        $Data{"appimage"} = "1";
    }
    
    if($Opt{"Snap"})
    {
        @Cmd = (@Cmd, "-F snap=1");
        $Data{"snap"} = "1";
    }
    
    if($Opt{"Flatpak"})
    {
        @Cmd = (@Cmd, "-F flatpak=1");
        $Data{"flatpak"} = "1";
    }
    
    if($Opt{"PC_Name"})
    {
        @Cmd = (@Cmd, "-F id='".$Opt{"PC_Name"}."'");
        $Data{"id"} = $Opt{"PC_Name"};
    }
    
    if($Opt{"Group"})
    {
        @Cmd = (@Cmd, "-F group='".$Opt{"Group"}."'");
        $Data{"group"} = $Opt{"Group"};
    }
    
    @Cmd = (@Cmd, "-F tool_ver=\'$TOOL_VERSION\'");
    $Data{"tool_ver"} = $TOOL_VERSION;
    
    @Cmd = (@Cmd, "-F salt=\'$Salt\'");
    $Data{"salt"} = $Salt;
    
    # fix curl error 22: "The requested URL returned error: 417 Expectation Failed"
    @Cmd = (@Cmd, "-H", "Expect:");
    # @Cmd = (@Cmd, "--http1.0");
    
    @Cmd = (@Cmd, $UploadURL);
    
    my $CurlCmd = join(" ", @Cmd);
    my $Log = qx/$CurlCmd 2>&1/;
    my $Err = $?;
    
    if($Err)
    {
        if(my $WWWLog = postRequest($UploadURL, \%Data, "NoSSL"))
        {
            if(index($WWWLog, "probe=")==-1)
            {
                print STDERR $WWWLog."\n";
                printMsg("ERROR", "failed to upload data");
                if(index($WWWLog, "Can't locate HTML/HeadParser.pm")!=-1) {
                    printMsg("ERROR", "please add 'libhtml-parser-perl' or 'perl-HTML-Parser' package to your system");
                }
                exitStatus(1);
            }
            
            $Log = $WWWLog;
        }
        else
        {
            my $ECode = $Err>>8;
            print STDERR $Log."\n";
            printMsg("ERROR", "failed to upload data, curl error code \"".$ECode."\"");
            exitStatus(1);
        }
    }
    
    $Log=~s/\s*Private access:\s*http.+?token\=(\w+)\s*/\n/;
    print $Log;
    
    my ($ID, $Token) = ();
    if($Log=~/probe\=(\w+)/) {
        $ID = $1;
    }
    if($Log=~/token\=(\w+)/) {
        $Token = $1;
    }
    
    # save uploaded probe and its ID
    if($ID)
    {
        my $NewProbe = $PROBE_DIR."/".$ID;
        
        if(-d $NewProbe)
        {
            printMsg("ERROR", "the probe with ID \'$ID\' already exists, overwriting ...");
            unlink($NewProbe."/hw.info.txz");
        }
        else {
            mkpath($NewProbe);
        }
        
        if($Opt{"Source"}) {
            copy($Pkg, $NewProbe);
        }
        else {
            move($Pkg, $NewProbe);
        }
        
        my $Time = time;
        my $ProbeUrl = "$URL/?probe=$ID";
        my $ProbeLog = "PROBE\n=====\nDate: ".localtime($Time)." ($Time)\n";
        
        $ProbeLog .= "Probe URL: $ProbeUrl\n";
        if($Token) {
            $ProbeLog .= "Private access: $ProbeUrl&token=$Token\n";
        }
        
        appendFile($PROBE_LOG, $ProbeLog."\n");
    }
}

sub cleanData()
{
    if($Opt{"Clean"})
    {
        if(-d $DATA_DIR) {
            rmtree($DATA_DIR);
        }
    }
}

sub readHostAttr($$)
{
    my ($Path, $Attr) = @_;
    
    if(readFile($Path."/host")=~/\Q$Attr\E\:([^\n]*)/)
    {
        return $1;
    }
    
    return "";
}

sub createPackage()
{
    my ($Pkg, $HWaddr) = ();
    
    if($Opt{"Source"})
    {
        if(-f $Opt{"Source"})
        {
            if(isPkg($Opt{"Source"}))
            {
                $Pkg = $Opt{"Source"};
                
                system("tar", "--directory", $TMP_DIR, "-xf", $Pkg);
                if($?)
                {
                    printMsg("ERROR", "failed to extract package (".$?.")");
                    exitStatus(1);
                }
                
                if(my @Dirs = listDir($TMP_DIR))
                {
                    my $Dir = $Dirs[0];
                    
                    my $Chg = 0;
                    
                    if($Dir ne "hw.info")
                    { # packaged by user
                        move($TMP_DIR."/".$Dir, $TMP_DIR."/hw.info");
                        $Chg = 1;
                    }
                    
                    if(updateHost($TMP_DIR."/hw.info", "id", $Opt{"PC_Name"})) {
                        $Chg = 1;
                    }
                    
                    $HWaddr = readHostAttr($TMP_DIR."/hw.info", "hwaddr");
                    
                    if($Chg)
                    {
                        chdir($TMP_DIR);
                        system("tar", "-cJf", "hw.info.txz", "hw.info");
                        chdir($ORIG_DIR);
                        
                        if($?)
                        {
                            printMsg("ERROR", "failed to create a package (".$?.")");
                            exitStatus(1);
                        }
                        
                        $Pkg = $TMP_DIR."/hw.info.txz";
                    }
                }
            }
            else
            {
                printMsg("ERROR", "not a package");
                exitStatus(1);
            }
        }
        elsif(-d $Opt{"Source"})
        {
            copyFiles($Opt{"Source"}, $TMP_DIR."/hw.info");
            updateHost($TMP_DIR."/hw.info", "id", $Opt{"PC_Name"});
            
            $HWaddr = readHostAttr($TMP_DIR."/hw.info", "hwaddr");
            
            chdir($TMP_DIR);
            system("tar", "-cJf", "hw.info.txz", "hw.info");
            chdir($ORIG_DIR);
            
            if($?)
            {
                printMsg("ERROR", "failed to create a package (".$?.")");
                exitStatus(1);
            }
            
            $Pkg = $TMP_DIR."/hw.info.txz";
        }
        else
        {
            printMsg("ERROR", "can't access '".$Opt{"Source"}."'");
            exitStatus(1);
        }
    }
    else
    {
        if(-d $DATA_DIR)
        {
            if(not -f "$DATA_DIR/devices")
            {
                printMsg("ERROR", "\'./$DATA_DIR/devices\' file is not found, please make probe first");
                exitStatus(1);
            }
            
            updateHost($DATA_DIR, "id", $Opt{"PC_Name"});
            $HWaddr = readHostAttr($DATA_DIR, "hwaddr");
            
            $Pkg = $TMP_DIR."/hw.info.txz";
            
            chdir(dirname($DATA_DIR));
            system("tar", "-cJf", $Pkg, basename($DATA_DIR));
            chdir($ORIG_DIR);
        }
        else
        {
            if($Admin) {
                printMsg("ERROR", "can't access '".$DATA_DIR."', please make probe first");
            }
            else {
                printMsg("ERROR", "can't access '".$DATA_DIR."', please run as root");
            }
            exitStatus(1);
        }
    }
    
    return ($Pkg, $HWaddr);
}

sub ceilNum($) {
    return int($_[0]+0.99);
}

sub copyFiles($$)
{
    my ($P1, $P2) = @_;
    
    mkpath($P2);
    
    foreach my $Top (listDir($P1))
    {
        if(-d "$P1/$Top")
        { # copy subdirectory
            foreach my $Sub (listDir("$P1/$Top"))
            {
                if($Sub=~/~\Z/) {
                    next;
                }
                mkpath("$P2/$Top");
                copy("$P1/$Top/$Sub", "$P2/$Top/$Sub");
            }
        }
        else
        { # copy file
            if($Top=~/~\Z/) {
                next;
            }
            copy("$P1/$Top", "$P2/$Top");
        }
    }
}

sub isPkg($)
{
    my $Path = $_[0];
    return ($Path=~/\.(tar\.xz|txz|tar\.gz|tgz)\Z/ or `file "$Path"`=~/(XZ|gzip) compressed data/);
}

sub updateHost($$$)
{
    my ($Path, $Attr, $Val) = @_;
    
    if($Val)
    {
        if(not -f "$Path/host")
        { # internal error
            return 0;
        }
        
        my $Content = readFile($Path."/host");
        
        my $Chg = 0;
        
        if($Content!~/(\A|\n)$Attr:/)
        {
            if($Content!~/\n\Z/) {
                $Content .= "\n";
            }
            $Content .= $Attr.":".$Val."\n";
            $Chg = 1;
        }
        elsif($Content=~/(\A|\n)$Attr:(.*)/)
        {
            if($2 ne $Val)
            {
                $Content=~s/(\A|\n)$Attr:(.*)/$1$Attr:$Val/;
                $Chg = 1;
            }
        }
        
        if($Chg)
        {
            writeFile($Path."/host", $Content);
            print "Added \'$Attr\' to host info\n";
            return 1;
        }
    }
    
    return 0;
}

sub fmtVal($)
{
    my $Val = $_[0];
    
    if(not defined $Val or $Val eq "" or $Val=~/\A\s+\Z/) {
        return "";
    }
    
    if($Val!~/[a-z0-9]/i) { # invalid
        return "";
    }
    
    $Val=~s/\((R|TM)\)\-/-/gi;
    $Val=~s/\((R|TM)\)/ /gi;
    
    $Val=~s/\342\204\242|\302\256|\302\251//g; # TM (trade mark), R (registered), C (copyright) special symbols
    $Val=~s/\303\227/x/g; # multiplication sign
    
    $Val=~s/\A[_\-\? ]//gi;
    $Val=~s/[_\-\? ]\Z//gi;
    
    $Val=~s/[ ]{2,}/ /g;
    
    return $Val;
}

sub bytesToHuman($)
{
    my $Bytes = $_[0];
    
    $Bytes /= 1000000; # MB
    
    if($Bytes>=1000)
    {
        $Bytes /= 1000; # GB
        $Bytes = roundToNearest($Bytes);
        if($Bytes>=1000)
        {
            $Bytes /= 1000; # TB
            $Bytes = roundToNearest($Bytes);
            return $Bytes."TB";
        }
        
        return $Bytes."GB";
    }
    
    return $Bytes."MB";
}

sub getPnpVendor($)
{
    my $V = $_[0];
    
    if(defined $MonVendor{$V}) {
        return $MonVendor{$V};
    }
    
    if(grep {$V eq $_} @UnknownMonVendor) {
        return $V;
    }
    
    # NOTE: this is not reliable
    # if(not keys(%PnpVendor)) {
    #     readPnpIds();
    # }
    #
    # if(defined $PnpVendor{$V})
    # {
    #     if($PnpVendor{$V}!~/do not use/i) {
    #         return $PnpVendor{$V};
    #     }
    # }

    return;
}

sub readPnpIds()
{
    my $Path = undef;
    
    if($Opt{"PnpIDs"}) {
        $Path = $Opt{"PnpIDs"};
    }
    else {
        $Path = "/usr/share/hwdata/pnp.ids"; # ROSA Fresh, RELS
    }
    
    if(not -e $Path) {
        $Path = "/usr/share/misc/pnp.ids"; # ROSA Marathon
    }
    
    if(not -e $Path) {
        return;
    }
    
    foreach my $Line (split(/\n/, readFile($Path)))
    {
        if($Line=~/\A([A-Z]+)\s+(.*?)\Z/) {
            $PnpVendor{$1} = $2;
        }
    }
}

sub getPciVendor($)
{
    my $V = $_[0];
    
    if(defined $PciVendor{$V}) {
        return $PciVendor{$V};
    }
    
    if(not keys(%PciInfo)) {
        readVendorIds();
    }
    
    if(defined $PciVendor{$V}) {
        return $PciVendor{$V};
    }

    return;
}

sub readVendorIds()
{
    my $Path = "/usr/share/hwdata/pci.ids";
    
    if($Opt{"PciIDs"}) {
        $Path = $Opt{"PciIDs"};
    }
    elsif(-e "ids/pci.ids") {
        $Path = "ids/pci.ids";
    }
    
    if(not -e $Path) {
        return;
    }
    
    foreach my $Line (split(/\n/, readFile($Path)))
    {
        if($Line=~/\A(\w{4})\s+(.*?)\Z/) {
            $PciVendor{$1} = $2;
        }
    }
}

sub getSdioType($)
{
    my $Class = $_[0];
    
    return $SdioType{$Class};
}

sub getClassType($$)
{
    my ($Bus, $Class) = @_;
    
    while($Class)
    {
        if($Bus eq "pci")
        {
            if(defined $PciClassType{$Class}) {
                return $PciClassType{$Class};
            }
        }
        elsif($Bus eq "usb")
        {
            if(defined $UsbClassType{$Class}) {
                return $UsbClassType{$Class};
            }
        }
        
        if($Class!~s/\-\w+?\Z//) {
            last;
        }
    }
    
    return "";
}

sub getDefaultType($$)
{
    my ($Bus, $Device) = @_;
    
    foreach my $Name ($Device->{"Device"}, $Device->{"SDevice"})
    {
        if(not $Name) {
            next;
        }
        
        if($Bus eq "usb")
        {
            if($Name=~/camera|webcam|web cam/i) {
                return "camera";
            }
            elsif($Name=~/card reader/i) {
                return "card reader";
            }
            elsif($Name=~/fingerprint (reader|scanner|sensor)/i) {
                return "fingerprint reader";
            }
            elsif($Name=~/USB Scanner|CanoScan|FlatbedScanner|Scanjet|EPSON Scanner/i) {
                return "scanner";
            }
            elsif($Name=~/bluetooth/i) {
                return "bluetooth";
            }
            elsif($Name=~/(\A| )(WLAN|NIC|11n Adapter)( |\Z)|Wireless.*Adapter|Wireless Network|Wireless LAN|WiMAX|WiFi|802\.11/i) {
                return "network";
            }
            elsif($Name=~/converter/i) {
                return "converter";
            }
            elsif($Name=~/(\A| )UPS(\Z| )/) {
                return "ups";
            }
            elsif($Name=~/TouchScreen/i) {
                return "touchscreen";
            }
            elsif($Name=~/Touchpad|Touch Pad/i) {
                return "touchpad";
            }
            elsif($Name=~/(\A| )Phone(\Z| )/i) {
                return "phone";
            }
            elsif($Name=~/Gamepad/i) {
                return "gamepad";
            }
            elsif($Name=~/DVB-T/) {
                return "dvb card";
            }
        }
        elsif($Bus eq "pci")
        {
            if($Name=~/card reader/i) {
                return "card reader";
            }
            elsif($Name=~/I\/O card/i) {
                return "i/o card";
            }
            elsif($Name=~/PCI Bridge/i) {
                return "bridge";
            }
        }
        elsif($Bus eq "pcmcia")
        {
            if($Name=~/Bay8Controller/i) {
                return "smartcard reader";
            }
        }
    }
    
    if($Bus eq "usb")
    {
        if(defined $Device->{"ActiveDriver"}{"btusb"}) {
            return "bluetooth";
        }
    }
    
    return "";
}

sub addCapacity($$)
{
    my ($Device, $Capacity) = @_;
    
    $Capacity=~s/\.\d+//;
    
    if($Capacity)
    {
        $Capacity=~s/\s+//g;
        if($Device!~/(\A|\s|\-)[\d\.\,]+\s*(MB|GB|TB|PB|[MGT])(\s|\Z)/
        and $Device!~/reader|bridge|\/sd\/|adapter/i and $Device!~/\Q$Capacity\E/i) {
            return " ".$Capacity;
        }
    }
    
    return "";
}

sub decodeEdid($)
{
    my $Edid = $_[0];
    
    my $TmpFile = $TMP_DIR."/hex-edid";
    writeFile($TmpFile, $Edid);
    
    my $Res = qx/edid-decode $TmpFile 2>&1/;
    unlink($TmpFile);
    
    return $Res;
}

sub countDevice($)
{
    my $DevId = $_[0];
    
    if(not defined $HW_Count{$DevId}) {
        $HW_Count{$DevId} = 1;
    } else {
        $HW_Count{$DevId} += 1;
    }
}

sub probeHW()
{
    if($Opt{"FixProbe"}) {
        print "Fixing probe ... ";
    }
    else
    {
        if(not defined $Opt{"HWInfoPath"} and not checkCmd("hwinfo"))
        {
            printMsg("ERROR", "'hwinfo' is not installed");
            exitStatus(1);
        }
        
        if($Opt{"HWLogs"})
        {
            foreach my $Prog ("dmidecode", "edid-decode")
            {
                if(not checkCmd($Prog)) {
                    printMsg("WARNING", "'".$Prog."' package is not installed");
                }
            }
            
            if(not checkCmd("smartctl")) {
                printMsg("WARNING", "'smartmontools' package is not installed");
            }
            
            if(not checkCmd("lspci")) {
                printMsg("WARNING", "'pciutils' package is not installed");
            }
            
            if(not checkCmd("lsusb")) {
                printMsg("WARNING", "'usbutils' package is not installed");
            }
        }
        
        print "Probe for hardware ... ";
        
        if($Opt{"ListProbes"}) {
            print "\n";
        }
    }
    
    # Dev listing
    my $DevFiles = "";
    
    if($Opt{"FixProbe"}) {
        $DevFiles = readFile($FixProbe_Logs."/dev");
    }
    else
    {
        listProbe("logs", "dev");
        $DevFiles = runCmd("find /dev -ls 2>/dev/null");
        if($DevFiles)
        {
            $DevFiles=~s/(\A|\n).*?\d+ \//$1\//g;
            $DevFiles = join("\n", sort split(/\n/, $DevFiles));
        }
        else
        { # Alpine
            $DevFiles = runCmd("ls -lR /dev");
            $DevFiles=~s/total \d+\n//g;
            $DevFiles=~s/(\A|\n).*?\s+\d+\s+\d\d:\d\d\s+/$1/g;
        }
        
        $DevFiles = encryptSerialsInPaths($DevFiles);
        $DevFiles = encryptWWNs($DevFiles);
        $DevFiles = hideByRegexp($DevFiles, qr/\/by-partlabel\/([^\s]+)/);
        
        writeLog($LOG_DIR."/dev", $DevFiles);
    }
    
    my %DevIdByName = ();
    my %DevNameById = ();
    
    my $InDevById = 0;
    foreach my $Line (split(/\n/, $DevFiles))
    {
        if(not $InDevById and index($Line, "/dev/disk/by-id")==0) {
            $InDevById = 1;
        }
        
        if($InDevById)
        {
            if(not $Line or index($Line, "/dev/disk/by-uuid")==0) {
                last;
            }
            
            if($Line=~/\A(\/dev\/disk\/by-id\/|)((ata|usb|nvme|wwn)\-[^\/]+)\s+\-\>\s+.*?(\w+)\Z/)
            {
                my ($DFile, $DIdent) = ($4, $2);
                if($DIdent!~/\Awwn\-/) {
                    $DevIdByName{$DFile} = $DIdent;
                }
                $DevNameById{$DIdent} = "/dev/".$DFile;
            }
        }
    }
    
    # Loaded modules
    my $Lsmod = "";
    
    if($Opt{"FixProbe"}) {
        $Lsmod = readFile($FixProbe_Logs."/lsmod");
    }
    else
    {
        listProbe("logs", "lsmod");
        if($Opt{"Snap"} or $Opt{"Flatpak"})
        {
            $Lsmod = "Module                  Size  Used by\n";
            foreach my $L (split(/\n/, readFile("/proc/modules")))
            {
                if($L=~/\A(\w+)\s+(\d+)\s+(\d+)\s+([\w,-]+)/)
                {
                    my ($Mod, $Size, $Used, $By) = ($1, $2, $3, $4);
                    $By=~s/[,-]\Z//;
                    # if($By) {
                    #     $By = join(",", sort split(/,/, $By));
                    # }
                    $Lsmod .= $Mod;
                    my $Sp = 28 - length($Size) - length($Mod);
                    if($Sp<4) {
                        $Sp = 4;
                    }
                    foreach (1 .. $Sp) {
                        $Lsmod .= " ";
                    }
                    $Lsmod .= $Size."  ".$Used." ".$By."\n";
                }
            }
        }
        else
        {
            $Lsmod = runCmd("lsmod 2>&1");
            
            if(length($Lsmod)<60) {
                $Lsmod = "";
            }
        }
        
        if($Lsmod)
        { # Sort, but save title
            my $FL = "";
            if($Lsmod=~s/\A(.*?)\n//) {
                $FL = $1;
            }
            
            $Lsmod = $FL."\n".join("\n", sort split(/\n/, $Lsmod));
        }
        
        if($Opt{"HWLogs"}) {
            writeLog($LOG_DIR."/lsmod", $Lsmod);
        }
    }
    
    my @KernDrvs = ();
    foreach my $Line (split(/\n/, $Lsmod))
    {
        if($Line=~/(\w+)\s+(\d+)\s+(\d+)/)
        {
            my ($Name, $Use) = ($1, $3);
            $KernMod{$Name} = $Use;
            push(@KernDrvs, $Name);
            
            if($Use) {
                $WorkMod{$Name} = 1;
            }
        }
    }
    
    if($Sys{"System"}=~/Gentoo/i)
    { # Gentoo
        %WorkMod = ();
    }
    
    if(not $Opt{"FixProbe"} and $Opt{"Logs"})
    {
        if(enabledLog("modinfo")
        and checkCmd("modinfo"))
        {
            listProbe("logs", "modinfo");
            my $Modinfo = runCmd("modinfo ".join(" ", @KernDrvs)." 2>&1");
            $Modinfo=~s/\n(filename:)/\n\n$1/g;
            $Modinfo=~s/\n(author|signer|sig_key|sig_hashalgo|vermagic):.+//g;
            $Modinfo=~s/\ndepends:\s+\n/\n/g;
            $Modinfo=~s&/lib/modules/[^\/]+/kernel/&&g;
            writeLog($LOG_DIR."/modinfo", $Modinfo);
        }
    }
    
    if(not $Opt{"FixProbe"})
    {
        my $RpmLst = "/run/initramfs/live/rpm.lst";
        if(-f $RpmLst)
        { # Live
            my $Build = `head -n 1 $RpmLst 2>&1`; # iso build No.11506
            
            if($Build=~/(\d+)/) {
                $Sys{"Build"} = $1;
            }
            
            if($Opt{"Logs"}) {
                writeLog($LOG_DIR."/build", $Build);
            }
        }
        else
        {
            my $RevInfo = "/run/initramfs/live/revision.info";
            if(-f $RevInfo)
            { # DX
                my $Build = readFile($RevInfo);
                
                if($Build=~/RELEASE\:\s*(\d+)/i) {
                    $Sys{"Build"} = $1;
                }
                
                if($Opt{"Logs"}) {
                    writeLog($LOG_DIR."/revision.info", $Build);
                }
            }
        }
    }
    
    my %DriveKind = ();
    
    if($Opt{"FixProbe"})
    { # Fix drive IDs after uploading
        my $Smart = readFile($FixProbe_Logs."/smartctl");
        
        my $CurDev = undef;
        foreach my $SL (split(/\n/, $Smart))
        {
            if(index($SL, "/dev/")==0)
            {
                $CurDev = $SL;
                $DriveKind{$CurDev} = "HDD";
            }
            elsif($CurDev)
            {
                if($SL=~/Rotation Rate:.*Solid State Device|\bSSD/) {
                    $DriveKind{$CurDev} = "SSD";
                }
                elsif(index($SL, "NVM Commands")!=-1 or index($SL, "NVMe Log")!=-1) {
                    $DriveKind{$CurDev} = "NVMe";
                }
            }
        }
    }
    
    # HW Info
    my $HWInfo = "";
    
    if($Opt{"FixProbe"}) {
        $HWInfo = readFile($FixProbe_Logs."/hwinfo");
    }
    else
    {
        listProbe("logs", "hwinfo");
        
        my @Items = qw(monitor bluetooth bridge
        camera cdrom chipcard cpu disk dvb fingerprint floppy
        gfxcard hub ide isapnp isdn joystick keyboard
        mouse netcard network pci pcmcia scanner scsi smp sound
        tape tv usb usb-ctrl wlan);
        
        my $HWInfoCmd = "hwinfo";
        
        if(defined $Opt{"HWInfoPath"})
        {
            my $HWInfoDir = dirname(dirname($Opt{"HWInfoPath"}));
            $HWInfoCmd = $Opt{"HWInfoPath"};

            if(-d "$HWInfoDir/lib64") {
                $HWInfoCmd = "LD_LIBRARY_PATH=\"$HWInfoDir/lib64\" ".$HWInfoCmd;
            }
            elsif(-d "$HWInfoDir/lib") {
                $HWInfoCmd = "LD_LIBRARY_PATH=\"$HWInfoDir/lib\" ".$HWInfoCmd;
            }
        }
        
        if(my $HWInfoVer = qx/$HWInfoCmd --version/)
        {
            chomp($HWInfoVer);
            if($HWInfoVer=~/\A(\d+)\.(\d+)\Z/)
            {
                my ($V1, $V2) = (int($1), int($2));
                if($V1>21 or $V1==21 and $V2>=34)
                { # newer than 21.34
                    push(@Items, "mmc-ctrl");
                }
            }
        }
        
        if($Opt{"LogLevel"} eq "maximal")
        { # this may hang
            push(@Items, "framebuffer");
        }
        
        my $Items = "--".join(" --", @Items);
        
        $HWInfo = runCmd("$HWInfoCmd $Items 2>/dev/null");
        
        if(not $HWInfo)
        { # incorrect option
            printMsg("WARNING", "incorrect hwinfo option passed, using --all");
            $HWInfo = runCmd($HWInfoCmd." --all 2>&1");
        }
        
        $HWInfo = hideMACs($HWInfo);
        $HWInfo = hideTags($HWInfo, "UUID|Asset Tag");
        if(index($HWInfo, "Serial ID:")) {
            $HWInfo = encryptSerials($HWInfo, "Serial ID", "hwinfo");
        }
        else
        { # Snap
            $HWInfo = encryptSerialsInPaths($HWInfo);
        }
        $HWInfo = encryptWWNs($HWInfo);
        
        if($Opt{"HWLogs"}) {
            writeLog($LOG_DIR."/hwinfo", $HWInfo);
        }
    }

    my %LongID = ();
    
    foreach my $Info (split(/\n\n/, $HWInfo))
    {
        my %Device = ();
        my ($DevNum, $Bus) = ();
        
        my ($V, $D, $SV, $SD, $C) = ();
        
        if($Info=~s/(\d+):\s*([^ ]+)//)
        { # 37: PCI 700.0: 0200 Ethernet controller
            $DevNum = $1;
            $Bus = lc($2);
        }
        
        $Bus=~s/\(.*?\)//g;
        
        if($Bus eq "adb")
        { # adb:0001-0001-macintosh-mouse-button-emulation
            next;
        }
        
        if($Info=~s/:\s*\w+\s+(.*)//)
        { # 37: PCI 700.0: 0200 Ethernet controller
            if($1 eq "BIOS")
            {
                next;
            }
            elsif($1 ne "Unclassified device")
            {
                $Device{"Type"} = lc($1);
                $Device{"GeneralType"} = $1;
            }
        }
        
        if($Device{"Type"} eq "partition") {
            next;
        }
        elsif($Device{"Type"} eq "disk"
        and $Bus eq "pci") {
            $Bus = $PCI_DISK_BUS;
        }
        
        $Info=~s/[ ]{2,}/ /g;
        
        my $ID = "";
        
        while($Info=~s/[ \t]*([\w ]+?):[ \t]*(.*)//)
        {
            my ($Key, $Val) = ($1, $2);
            
            if($Key eq "Device" or $Key eq "Vendor" or $Key eq "SubVendor" or $Key eq "SubDevice")
            {
                $Key=~s/\ASub/S/; # name mapping
                
                if($Bus ne "ide" and $Bus ne $PCI_DISK_BUS)
                {
                    if($Val=~s/\A(\w+) 0x/0x/) {
                        $Bus = $1;
                    }
                    
                    if($Val=~s/0x(\w{4})\s*//)
                    {
                        if($Key eq "Vendor") {
                            $V = $1;
                        }
                        elsif($Key eq "Device") {
                            $D = $1;
                        }
                        elsif($Key eq "SVendor") {
                            $SV = $1;
                        }
                        elsif($Key eq "SDevice") {
                            $SD = $1;
                        }
                    }
                }
                
                if($Val=~/\"(.*)\"/) {
                    $Device{$Key} = fmtVal($1);
                }
                
                if($Device{"Type"} eq "cpu")
                { # fix cpu
                    if($Key eq "Vendor")
                    {
                        if($Device{$Key}=~/Intel/) {
                            $Device{$Key} = "Intel";
                        }
                        elsif($Device{$Key}=~/AMD/) {
                            $Device{$Key} = "AMD";
                        }
                        elsif($Device{$Key}=~/ARM/) {
                            $Device{$Key} = "ARM";
                        }
                    }
                }
                
                if(not $V)
                {
                    if($Val=~/(\w+)\s+\".*\"/) {
                        $V = $1;
                    }
                    elsif($Val!~/\".*\"/) {
                        $V = fmtVal($Val);
                    }
                }
            }
            elsif($Key eq "Model")
            {
                if($Val=~/\A(.*?)\s*\"(.*)\"/)
                {
                    $D = $1;
                    $Device{"Model"} = fmtVal($2);
                }
            }
            elsif($Key eq "Hardware Class")
            {
                if(lc($Val) ne "unknown") {
                    $Device{"Type"} = $Val;
                }
            }
            elsif($Key eq "Driver")
            {
                while($Val=~s/\"([\w\-]+)\"//)
                {
                    my $Dr = $1;
                    $Dr=~s/\-/_/g;
                    $Device{"ActiveDriver_Common"}{$Dr} = keys(%{$Device{"ActiveDriver_Common"}});
                }
            }
            elsif($Key eq "Driver Status")
            {
                if($Val=~/(.*) is active/)
                {
                    my $Dr = $1;
                    $Dr=~s/\-/_/g;
                    $Device{"ActiveDriver"}{$Dr} = keys(%{$Device{"ActiveDriver"}});
                }
            }
            elsif($Key eq "Module Alias")
            {
                if($Val=~/\"(.*)\"/)
                {
                    $Val = $1;
                    
                    if($Val=~/ic(\w\w)isc(\w\w)ip(\w\w)\Z/)
                    { # usb
                        $C = devID($1, $2, $3);
                    }
                    elsif($Val=~/bc(\w\w)sc(\w\w)i(\w\w)\Z/)
                    { # pci
                        $C = devID($1, $2, $3);
                    }
                }
            }
            elsif($Key eq "Resolution"
            and $Device{"Type"} eq "monitor")
            { # monitor
                if($Val=~s/\@.*//)
                {
                    if(not defined $Device{"Resolution"}
                    or getXRes($Val)>getXRes($Device{"Resolution"}))
                    {
                        $Device{$Key} = $Val;
                        $Device{$Key}=~s/ //g;
                    }
                }
            }
            elsif($Key eq "Size"
            and $Device{"Type"} eq "monitor")
            { # monitor
                $Device{$Key} = $Val;
                $Device{$Key}=~s/ //g;
            }
            elsif($Key eq "Size")
            { # disk
                if($Val=~/(\d+) sectors a (\d+) bytes/) {
                    $Device{"Capacity"} = bytesToHuman($1*$2);
                }
            }
            elsif($Key eq "Capacity")
            { # disk
                if($Val=~s/\s*\((.*?)\)//)
                {
                    my $Bytes = $1;
                    $Bytes=~s/ bytes//g;
                    
                    $Val = bytesToHuman($Bytes);
                }
                $Val=~s/ //g;
                $Device{$Key} = $Val;
            }
            elsif($Key eq "Attached to")
            {
                $Device{"Attached"} = $Val;
                if($Bus eq "ide" or $Bus eq $PCI_DISK_BUS)
                {
                    # FIXME: check for PATA
                    # if($Val=~/SATA/)
                    # {
                    #     $Bus = "sata";
                    # }
                }
                
                if($Val=~/#(\d+)/) {
                    $DeviceAttached{$DevNum} = $1;
                }
            }
            elsif($Key eq "Device Files")
            {
                if($Val=~/by-id\/(.*?)(,|\Z)/) {
                    $Device{"FsId"} = $1;
                }
                
                foreach my $F (split(/,\s*/, $Val))
                {
                    $Device{"AllFiles"}{$F} = 1;
                }
            }
            elsif($Key eq "Device File")
            {
                if($Device{"Type"} eq "disk"
                or $Device{"Type"} eq "storage device")
                {
                    if($Val=~s/\s*\((.*)\)//) {
                        $Device{"AdvFile"} = $1;
                    }
                    $Device{"File"} = $Val;
                    
                    if($Bus eq "ide" or $Bus eq $PCI_DISK_BUS
                    or index($Val, "nvme")!=-1 or $Bus eq "usb") {
                        $HDD{$Val} = 0;
                    }
                    elsif(index($Val, "mmcblk")!=-1 and $Val=~/mmcblk\d+\Z/) {
                        $MMC{$Val} = 0;
                    }
                }
                elsif($Device{"Type"} eq "network") {
                    $Device{"Files"}{$Val} = 1;
                }
            }
            elsif($Key eq "Serial ID")
            { # disk
                if($Val=~/\"(.*)\"/) {
                    $Device{"Serial"} = $1;
                }
            }
            elsif($Key eq "Memory Size")
            { # framebuffer
                $Val=~s/(\d)\s+(MB|GB|KB)/$1$2/ig;
                $Device{"Memory Size"} = $Val;
            }
            elsif($Key eq "Platform"
            and $Device{"Type"} eq "cpu")
            { # ARM
                if($Val=~/\"(.*)\"/) {
                    $Device{"Platform"} = $1;
                }
            }
            elsif($Key eq "Link detected") {
                $Device{"Link detected"} = $Val;
            }
        }
        
        cleanValues(\%Device);
        
        if(my $DF = $Device{"File"})
        {
            if($Bus eq "scsi")
            {
                if($Device{"Attached"}!~/RAID/) {
                    $HDD{$DF} = 0;
                }
            }
        }
        
        if(not $Device{"Device"})
        {
            if(my $Model = $Device{"Model"}) {
                $Device{"Device"} = $Model;
            }
            elsif($Device{"Type"} eq "cpu")
            {
                if(my $Platform = $Device{"Platform"})
                {
                    $Device{"Device"} = $Platform." Processor";
                }
                elsif($Device{"Vendor"}) {
                    $Device{"Device"} = $Device{"Vendor"}." Processor";
                }
            }
        }
        
        if(defined $Device{"ActiveDriver"}) {
            $Device{"Driver"} = join(", ", sort {$Device{"ActiveDriver"}{$a} <=> $Device{"ActiveDriver"}{$b}} keys(%{$Device{"ActiveDriver"}}));
        }
        elsif(defined $Device{"ActiveDriver_Common"}) {
            $Device{"Driver"} = join(", ", sort {$Device{"ActiveDriver_Common"}{$a} <=> $Device{"ActiveDriver_Common"}{$b}} keys(%{$Device{"ActiveDriver_Common"}}));
        }
        
        if($Device{"Type"} eq "cpu") {
            $Bus = "cpu";
        }
        elsif($Device{"Type"} eq "framebuffer")
        {
            $Bus = "fb";
            next; # disabled
        }
        
        if($Device{"Type"} eq "disk")
        {
            $DriveNumByFile{$Device{"File"}} = $DevNum;
            
            if(index($Device{"File"}, "nvme")!=-1)
            {
                if(not $Device{"Device"} or $Device{"Device"} eq "Disk"
                or not $Device{"Vendor"} or not $Device{"Serial"})
                {
                    if($Device{"FsId"}=~/\Anvme\-(INTEL)_([^_]+)_([^_]+)\Z/)
                    {
                        $Device{"Vendor"} = ucfirst(lc($1));
                        $Device{"Model"} = $2;
                        $Device{"Serial"} = $3;
                        $Device{"Device"} = $Device{"Model"};
                        
                        if($Device{"Serial"}!~/\A[A-F]{$HASH_LEN_CLIENT}\Z/) {
                            $Device{"Serial"} = clientHash($Device{"Serial"});
                        }
                        
                        if($Bus eq "none") {
                            $Bus = $PCI_DISK_BUS;
                        }
                    }
                }
                
                if(not $Device{"Device"} or $Device{"Device"} eq "Disk"
                or not $Device{"Vendor"} or not $Device{"Serial"})
                { # empty info for NVMe drives
                    if($Device{"Model"})
                    {
                        if(index($Device{"Model"}, $Device{"Device"})!=-1)
                        {
                            if(my $Vnd = guessDeviceVendor($Device{"Model"}))
                            {
                                $Device{"Model"} = $Vnd." Disk";
                                $Device{"Vendor"} = $Vnd;
                            }
                            else {
                                $Device{"Model"} = undef;
                            }
                        }
                        elsif($Device{"Model"}=~/controller/i) {
                            $Device{"Model"} = undef;
                        }
                    }
                    $HDD_Info{$Device{"File"}} = \%Device;
                    next;
                }
            }
            elsif(index($Device{"File"}, "mmcblk")!=-1)
            {
                if($Device{"FsId"}=~/\Ammc-(.+?)[_]+(0x[a-f\d]{8})\Z/)
                {
                    $Bus = "mmc";
                    $Device{"Device"} = $1;
                    $Device{"Serial"} = clientHash($2);
                    
                    $MMC_Info{$Device{"File"}} = \%Device;
                    next;
                }
            }
            
            if(not $Device{"Attached"}) {
                next;
            }
        }
        
        #if($Bus eq "none")
        #{
        #    if($Device{"Type"} eq "disk" and $Device{"File"}=~/\/dev\/vd/) {
        #        $Bus = "ide";
        #    }
        #}
        
        if($Bus eq "none") {
            next;
        }
        
        if(not $Device{"Type"}) {
            $Device{"Type"} = getDefaultType($Bus, \%Device);
        }
        
        # fix type
        if($Device{"Type"} eq "keyboard")
        {
            if($Device{"Device"}=~/mouse/i and $Device{"Device"}!~/keyboard/i) {
                $Device{"Type"} = "mouse";
            }
        }
        elsif($Device{"Type"} eq "mouse")
        {
            if($Device{"Device"}!~/mouse/i)
            {
                if($Device{"Device"}=~/keyboard/i) {
                    $Device{"Type"} = "keyboard";
                }
                elsif($Device{"Device"}=~/touchscreen/i) {
                    $Device{"Type"} = "touchscreen";
                }
                elsif($Device{"Device"}=~/touchpad/i) {
                    $Device{"Type"} = "touchpad";
                }
            }
        }
        elsif($Device{"Type"} eq "printer")
        {
            if($Device{"Device"}=~/(\A| )MFP( |\Z)/) {
                $Device{"Type"} = "mfp";
            }
        }
        elsif($Device{"Type"} eq "disk")
        {
            if(defined $Device{"AllFiles"}{"/dev/cdrom"})
            {
                $Device{"Type"} = "cdrom";
                if(my $File = $Device{"File"}) {
                    delete($HDD{$File});
                }
            }
        }
        
        # fix vendor
        if($V eq "1d6b") {
            $Device{"Vendor"} = "Linux Foundation";
        }
        
        if(not $Device{"Vendor"})
        {
            if($Bus eq "ps/2")
            {
                if($Device{"Type"} eq "touchpad"
                or $Device{"Type"} eq "mouse")
                {
                    if($Device{"Device"}=~s/(\w+) (DualPoint Touchpad)/$2/i)
                    { # AlpsPS/2 ALPS DualPoint TouchPad
                        $Device{"Vendor"} = $1;
                    }
                    elsif($Device{"Device"}=~s/(\w+) (Touchpad|TrackPoint|GlidePoint)/$2/i) {
                        $Device{"Vendor"} = $1;
                    }
                    elsif($Device{"Device"}=~s/(PS\/2) (\w+) (Wheel Mouse)/$1 $3/i)
                    {
                        if($2 ne "Generic") {
                            $Device{"Vendor"} = $2;
                        }
                    }
                    elsif($Device{"Device"}=~/(Sony) Vaio Jogdial/i) {
                        $Device{"Vendor"} = $1;
                    }
                    elsif($Device{"Device"}=~/\A(Wacom) /i) {
                        $Device{"Vendor"} = $1;
                    }
                    elsif($Device{"Device"}=~/\A(ALPS) /i) {
                        $Device{"Vendor"} = "ALPS";
                    }
                    
                    if($Device{"Vendor"} eq "FocalTech") {
                        $Device{"Device"}=~s/FocalTech (FocalTech)/$1/i;
                    }
                }
            }
        }
        
        if($Device{"Type"} eq "disk" and $Bus ne "usb")
        {
            my $FsId = $Device{"FsId"};
            
            if(not $FsId)
            { # Docker
                if($Device{"File"}) {
                    $FsId = $DevIdByName{basename($Device{"File"})};
                }
            }
            
            if($FsId)
            {
                my $N = $Device{"Device"};
                $N=~s/ /_/g;
                
                if(my $Serial = $Device{"Serial"})
                {
                    if($FsId=~/\Q$N\E(.*?)_\Q$Serial\E/)
                    {
                        my $Suffix = $1;
                        $Suffix=~s/[_]+/ /g;
                        $Device{"Device"} .= $Suffix;
                    }
                }
                elsif($FsId=~/\Q$N\E(.*)_(.*?)\Z/)
                {
                    my $Suffix = $1;
                    my $Ser = $2;
                    
                    $Suffix=~s/[_]+/ /g;
                    $Device{"Device"} .= $Suffix;
                    if(not $Device{"Serial"}) {
                        $Device{"Serial"} = $Ser;
                    }
                }
            }
            
            if(defined $DriveKind{$Device{"File"}})
            { # NOTE: on fixing probe
                $Device{"Kind"} = $DriveKind{$Device{"File"}};
            }
            
            $Device{"Device"} = duplVendor($Device{"Vendor"}, $Device{"Device"});
            
            # Fix incorrect vendor in hwinfo
            if($Device{"Vendor"} eq "m.2")
            {
                $Device{"Device"} .= " ".$Device{"Vendor"};
                $Device{"Vendor"} = undef;
            }
            elsif($Device{"Vendor"} eq "SK")
            {
                $Device{"Device"} = $Device{"Vendor"}." ".$Device{"Device"};
                $Device{"Vendor"} = undef;
            }
            
            fixDrive_Pre(\%Device);
            fixDrive(\%Device);
        }
        else
        {
            $Device{"Device"} = duplVendor($Device{"Vendor"}, $Device{"Device"});
            if($Device{"Type"} eq "monitor" and not $Device{"Device"}) {
                $Device{"Device"} = "LCD Monitor";
            }
        }
        
        if($Bus eq "usb" or $Bus eq "pci")
        {
            $ID = devID($V, $D, $SV, $SD);
            
            if($SD) {
                $LongID{devID($V, $D)}{$ID} = 1;
            }
            
            if($Device{"Type"} eq "disk") {
                $Device{"Device"} .= addCapacity($Device{"Device"}, $Device{"Capacity"});
            }
        }
        else
        {
            if($Device{"Device"} eq "Unclassified device")
            { # PNP devices, etc.
                next;
            }
            
            if(not $Device{"Device"}) {
                next;
            }
            
            if($Device{"Type"} eq "monitor")
            {
                if(lc($Device{"Device"}) eq lc($Device{"Vendor"})) {
                    $Device{"Device"} = $Device{"GeneralType"};
                }
                
                if($V)
                {
                    if(my $Vendor = getPnpVendor($V))
                    {
                        $Device{"Vendor"} = $Vendor;
                        $Device{"Device"}=~s/\A\Q$Vendor\E(\s+|\-)//ig;
                    }
                    elsif(not $Device{"Vendor"}) {
                        $Device{"Vendor"} = $V;
                    }
                }
            }
            
            if($Device{"Type"} eq "framebuffer")
            {
                if($Device{"Vendor"} eq $Device{"Device"}) {
                    $Device{"Vendor"} = "";
                }
            }
            
            # create id
            if($Device{"Type"} eq "monitor" and $V)
            { 
                #if(nameID($Device{"Vendor"}) ne $V)
                #{ # do not add vendor name to id
                    $ID = devID(nameID($Device{"Vendor"}));
                #}
                $ID = devID($ID, $V.$D);
            }
            else
            {
                if(my $Vendor = $Device{"Vendor"}) {
                    $ID = devID(nameID($Vendor));
                }
                else {
                    $ID = devID($V);
                }
                $ID = devID($ID, $D, devSuffix(\%Device));
            }
            
            # additionals to device attributes
            if($Device{"Type"} eq "monitor")
            {
                if($D) {
                    $Device{"Device"} .= " ".uc($V.$D);
                }
                
                if($Device{"Resolution"}) {
                    $Device{"Device"} .= " ".$Device{"Resolution"};
                }
                
                if($Device{"Size"}) {
                    $Device{"Device"} .= " ".$Device{"Size"};
                }
                
                if(my $Inch = computeInch($Device{"Device"})) {
                    $Device{"Device"} .= " ".$Inch."-inch";
                }
            }
            elsif($Device{"Type"} eq "disk")
            {
                $Device{"Device"} .= addCapacity($Device{"Device"}, $Device{"Capacity"});
                if($Device{"Kind"} eq "SSD" and $Device{"Device"}!~/SSD|Solid State/i) {
                    $Device{"Device"} .= " SSD";
                }
            }
            elsif($Device{"Type"} eq "cpu") {
                $Device{"Status"} = "works";
            }
            elsif($Device{"Type"} eq "framebuffer") {
                $Device{"Device"} .= " ".$Device{"Memory Size"};
            }
        }
        
        if($Device{"Type"} eq "network")
        {
            if(defined $Device{"Files"})
            {
                foreach my $F (sort keys(%{$Device{"Files"}}))
                {
                    if(defined $UsedNetworkDev{$F}) {
                        $Device{"Status"} = "works";
                    }
                }
            }
            
            if($Device{"Link detected"} eq "yes") {
                $Device{"Status"} = "works";
            }
        }
        
        # delete unused fields
        delete($Device{"ActiveDriver_Common"});
        delete($Device{"ActiveDriver"});
        
        delete($Device{"FsId"});
        delete($Device{"Serial"});
        delete($Device{"Model"});
        
        $Device{"Class"} = $C;
        
        cleanValues(\%Device);
        
        $ID = fmtID($ID);
        
        my $BusID = $Bus.":".$ID;
        
        if($Device{"Type"} eq "monitor") {
            $Monitor_ID{uc($V.$D)} = $ID;
        }
        elsif($Device{"Type"} eq "disk"
        or $Device{"Type"} eq "storage device")
        {
            if(my $File = $Device{"File"}) {
                $HDD{$File} = $BusID;
            }
        }
        
        if($Bus eq "ps/2"
        and $Device{"Type"}=~/touchpad/)
        {
            if(not $Sys{"Type"}
            or $Sys{"Type"}=~/desktop|server|other/) {
                $Sys{"Type"} = "notebook";
            }
        }
        
        $DeviceIDByNum{$DevNum} = $BusID;
        $DeviceNumByID{$BusID} = $DevNum;
        
        if(not $HW{$BusID}) {
            $HW{$BusID} = \%Device;
        }
        else
        { # double entry
            if($Device{"Type"} and not $HW{$BusID}{"Type"}) {
                $HW{$BusID} = \%Device;
            }
        }
        
        if($Device{"Type"}
        and $Device{"Type"}!~/cpu|mouse|keyboard|monitor/) {
            countDevice($BusID);
        }
        
        if($Device{"Type"} eq "cpu") {
            $CPU_ID = $BusID;
        }
        else {
            $ComponentID{$Device{"Type"}}{$BusID} = 1;
        }
    }
    
    my %HDD_Serial = ();
    
    # UDEV
    my $Udevadm = "";
    
    if($Opt{"FixProbe"})
    {
        $Udevadm = readFile($FixProbe_Logs."/udev-db");
        if(not $Udevadm)
        { # support for old probes
            $Udevadm = readFile($FixProbe_Logs."/udevadm");
        }
        if(not $Udevadm)
        { # support for sdio
            $Udevadm = readFile($FixProbe_Logs."/sdio");
        }
    }
    elsif(checkCmd("udevadm") and $Opt{"HWLogs"})
    {
        listProbe("logs", "udev-db");
        $Udevadm = runCmd("udevadm info --export-db 2>/dev/null");
        $Udevadm = hideTags($Udevadm, "ID_NET_NAME_MAC|ID_SERIAL|ID_SERIAL_SHORT|DEVLINKS|ID_WWN|ID_WWN_WITH_EXTENSION");
        $Udevadm=~s/(by\-id\/(ata|usb|nvme|wwn)\-).+/$1.../g;
        if(enabledLog("udev-db")) {
            writeLog($LOG_DIR."/udev-db", $Udevadm);
        }
        else
        {
            my $ExtraDevs = "";
            foreach my $UL (split(/\n\n/, $Udevadm))
            {
                if($UL=~/sdio/) {
                    $ExtraDevs .= $UL."\n\n";
                }
            }
            $Udevadm = $ExtraDevs;
            if($ExtraDevs) {
                writeLog($LOG_DIR."/sdio", $ExtraDevs);
            }
        }
    }
    
    foreach my $Info (split(/\n\n/, $Udevadm))
    {
        my %DInfo = "";
        
        foreach my $Line (split(/\n/, $Info))
        {
            if($Line=~/E:\s+(\w+)\=(.+)/) {
                $DInfo{$1} = $2;
            }
        }
        
        my %Device = ();
        
        my $Bus = undef;
        my ($V, $D) = ();
        my $ID = undef;
        
        if($DInfo{"DEVTYPE"} eq "disk"
        and $DInfo{"ID_TYPE"} eq "disk")
        {
            $HDD_Serial{$DInfo{"ID_MODEL"}}{$DInfo{"ID_SERIAL_SHORT"}} = 1;
        }
        
        if($DInfo{"SUBSYSTEM"} eq "sdio")
        {
            $Bus = "sdio";
            
            if($DInfo{"SDIO_ID"}=~/(\w\w\w\w)\:(\w\w\w\w)/)
            {
                ($V, $D) = (lc($1), lc($2));
                
                if(not keys(%SdioInfo)) {
                    readSdioIds_Sys();
                }
                
                $Device{"Vendor"} = $SdioVendor{$V};
                $Device{"Device"} = $SdioInfo{$V}{$D};
                
                $ID = devID($V, $D);
            }
            
            $Device{"Class"} = $DInfo{"SDIO_CLASS"};
            if($Device{"Device"}=~/WLAN|Wireless/i) {
                $Device{"Class"} = "07";
            }
            
            $Device{"Driver"} = $DInfo{"DRIVER"};
            $Device{"Type"} = getSdioType($Device{"Class"});
        }
        
        if($ID)
        {
            $ID = fmtID($ID);
            
            if(not $HW{$Bus.":".$ID}) {
                $HW{$Bus.":".$ID} = \%Device;
            }
        }
    }
    
    # fix incomplete HDD ids (if not root)
    if((not $Admin or $Opt{"FixProbe"}) and keys(%HDD_Serial))
    {
        foreach my $ID (sort keys(%HW))
        {
            if($ID=~/\Aide:(.+)/)
            {
                my $Name = $HW{$ID}{"Device"};
                
                foreach my $FN (sort keys(%HDD_Serial))
                {
                    if($FN=~/$Name(.+)/i)
                    {
                        my $Missed = $1;
                        
                        foreach my $Ser (sort keys(%{$HDD_Serial{$FN}}))
                        {
                            my $NewID = $ID.devID($Missed)."-serial-".devID($Ser);
                            $HW{$NewID} = $HW{$ID};
                            $HW{$NewID}{"Device"}=~s/(\Q$Name\E)/$1$Missed/;
                            countDevice($NewID);
                        }
                        
                        delete($HW{$ID});
                    }
                }
            }
        }
    }
    
    # PCI (all)
    my $Lspci_A = "";
    
    if($Opt{"FixProbe"}) {
        $Lspci_A = readFile($FixProbe_Logs."/lspci_all");
    }
    elsif(checkCmd("lspci"))
    {
        listProbe("logs", "lspci_all");
        
        my $PciLink = createIDsLink("pci");
        $Lspci_A = runCmd("lspci -vvnn 2>&1");
        if($PciLink) {
            unlink($PciLink);
        }
        
        $Lspci_A=~s/(Serial Number:?\s+|Manufacture ID:\s+).+/$1.../gi;
        
        if($Opt{"HWLogs"}) {
            writeLog($LOG_DIR."/lspci_all", $Lspci_A);
        }
    }
    
    foreach my $Info (split(/\n\n/, $Lspci_A))
    {
        my ($V, $D) = ();
        my @ID = ();
        
        if($Info=~/\w+:\w+\.\w\s+(.*?)\s*\[\w+\]:.*?\[(\w+)\:(\w+)\]/) {
            ($V, $D) = ($2, $3);
        }
        
        if($Info=~/Subsystem\:.*?\[(\w+)\:(\w+)\]/i) {
            push(@ID, $1, $2);
        }
        
        my $ID = devID($V, $D, @ID);
        
        if($V and $D and @ID) {
            $LongID{devID($V, $D)}{$ID} = 1;
        }
    }
    
    # PCI
    my $Lspci = "";
    
    if($Opt{"FixProbe"}) {
        $Lspci = readFile($FixProbe_Logs."/lspci");
    }
    else
    {
        if(checkCmd("lspci"))
        {
            listProbe("logs", "lspci");
            
            my $PciLink = createIDsLink("pci");
            $Lspci = runCmd("lspci -vmnnk 2>&1");
            if($PciLink) {
                unlink($PciLink);
            }
        }
        
        if($Opt{"HWLogs"}) {
            writeLog($LOG_DIR."/lspci", $Lspci);
        }
    }
    
    foreach my $Info (split(/\n\n/, $Lspci))
    {
        my %Device = ();
        my (@ID, @Class) = ();
        
        while($Info=~s/(\w+):\s*(.*)//) {
            $Device{$1} = $2;
        }
        
        foreach ("Vendor", "Device", "SVendor", "SDevice")
        {
            if($Device{$_}=~s/\s*\[(\w{4})\]//) {
                push(@ID, $1);
            }
        }
        
        my $ClassName = $Device{"Class"};
        
        if($ClassName=~s/\s*\[(\w{2})(\w{2})\]//)
        {
            push(@Class, $1, $2);
            
            if($Device{"ProgIf"}) {
                push(@Class, $Device{"ProgIf"});
            }
        }
        
        delete($Device{"Class"});
        delete($Device{"ProgIf"});
        
        cleanValues(\%Device);
        
        if($Opt{"PciIDs"})
        {
            if(not $Device{"Device"})
            { # get name of the device from local pci.ids file
                if(my $Name = $PciInfo{$ID[0]}{$ID[1]}) {
                    $Device{"Device"} = $Name;
                }
            }
            
            if(my $AddName = $AddPciInfo{$ID[0]}{$ID[1]}) {
                $Device{"Device"} = $AddName;
            }
            
            if(not $Device{"SDevice"})
            {
                if(my $Name = $PciInfo_D{$ID[0]}{$ID[1]}{$ID[2]}{$ID[3]}) {
                    $Device{"SDevice"} = $Name;
                }
            }
            
            if(my $AddSubName = $AddPciInfo_D{$ID[0]}{$ID[1]}{$ID[2]}{$ID[3]}) {
                $Device{"SDevice"} = $AddSubName;
            }
        }
        
        $Device{"Class"} = devID(@Class);
        
        my $ID = devID(@ID);
        my @L_IDs = keys(%{$LongID{$ID}});
        
        if($#L_IDs==0) {
            $ID = $L_IDs[0];
        }
        
        if(not $ID) {
            next;
        }
        
        #if(defined $HW{"pci:".$ID}{"Class"}) {
        #    delete($Device{"Class"});
        #}
        
        if($Device{"Module"})
        {
            $Device{"Driver"} = $Device{"Module"};
            delete($Device{"Module"});
        }
        
        my $NewDevice = (not defined $HW{"pci:".$ID});
        
        if(not $NewDevice and not $HW{"pci:".$ID}{"Type"})
        {
            $Device{"Type"} = getDefaultType("pci", \%Device);
            
            if(not $Device{"Type"})
            {
                if($Class[0] eq "02")
                { # pci:10ec-8136-10ec-8136
                    $Device{"Type"} = "network";
                }
            }
            
            if(not $Device{"Type"})
            {
                if(@Class) {
                    $Device{"Type"} = getClassType("pci", devID(@Class));
                }
            }
            
            if(not $Device{"Type"})
            {
                if($Device{"Device"}=~/Ethernet Controller/i) {
                    $Device{"Type"} = "network";
                }
            }
            
            if(not $Device{"Type"}) {
                $Device{"Type"} = lc($ClassName);
            }
        }
        
        foreach (keys(%Device))
        {
            if(my $Val = $Device{$_})
            {
                if($NewDevice or $_ ne "Driver") {
                    $HW{"pci:".$ID}{$_} = $Val;
                }
            }
        }
    }
    
    # USB
    my $Lsusb = "";
    
    if($Opt{"FixProbe"}) {
        $Lsusb = readFile($FixProbe_Logs."/lsusb");
    }
    else
    {
        if(checkCmd("lsusb"))
        {
            listProbe("logs", "lsusb");
            
            my $UsbLink = createIDsLink("usb");
            $Lsusb = runCmd("lsusb -v 2>&1");
            if($UsbLink) {
                unlink($UsbLink);
            }
            
            $Lsusb=~s/(iSerial\s+\d+\s*)[^\s]+$/$1.../mg;
            
            if(length($Lsusb)<60 and $Lsusb=~/unable to initialize/i) {
                $Lsusb = "";
            }
        }
        
        if($Opt{"HWLogs"}) {
            writeLog($LOG_DIR."/lsusb", $Lsusb);
        }
    }
    
    foreach my $Info (split(/\n\n/, $Lsusb))
    {
        my %Device = ();
        my ($V, $D, @Class) = ();
        
        if($Info=~/idVendor[ ]+0x(\w{4})[ ]+(.*)/)
        {
            $V = $1;
            
            if($2) {
                $Device{"Vendor"} = fmtVal($2);
            }
        }
        
        if($Info=~/idProduct[ ]+0x(\w{4})[ ]+(.*)/)
        {
            $D = $1;
            
            if($2) {
                $Device{"Device"} = fmtVal($2);
            }
        }
        
        if($Info=~/bInterfaceClass\s+(\w+)\s+/) {
            push(@Class, fNum(sprintf('%x',$1)));
        }
        if($Info=~/bInterfaceSubClass\s+(\w+)\s+/) {
            push(@Class, fNum(sprintf('%x',$1)));
        }
        if($Info=~/bInterfaceProtocol\s+(\w+)\s+/) {
            push(@Class, fNum(sprintf('%x',$1)));
        }
        
        $Device{"Class"} = devID(@Class);
        
        if(not $V)
        { # Couldn't open device
            next;
        }
        
        if(not $D)
        { # Couldn't open device
            next;
        }
        
        my $ID = devID($V, $D);
        
        #if(defined $HW{"usb:".$ID}{"Class"}) {
        #    delete($Device{"Class"});
        #}
        
        my $Vendor = $Device{"Vendor"};
        
        my $OldName = $HW{"usb:".$ID}{"Device"};
        my $OldVendor = $HW{"usb:".$ID}{"Vendor"};
        
        if($Device{"Device"}=~/\AFlash (Drive|Disk)\Z/i and $OldName)
        {
            $Device{"Device"} = $OldName;
        }
        else
        {
            if($Device{"Device"}) {
                $Device{"Device"} .= addCapacity($Device{"Device"}, $HW{"usb:".$ID}{"Capacity"});
            }
        }
        
        if($Opt{"UsbIDs"})
        {
            if(not $Device{"Device"})
            {
                if(my $Name = $UsbInfo{$V}{$D})
                {
                    if($Vendor)
                    {
                        if($Name ne $Vendor) {
                            $Device{"Device"} = $Name;
                        }
                    }
                    else
                    {
                        if($Name ne $OldVendor) {
                            $Device{"Device"} = $Name;
                        }
                    }
                }
            }
            
            if(my $AddName = $AddUsbInfo{$V}{$D})
            {
                if($Vendor)
                {
                    if($AddName ne $Vendor) {
                        $Device{"Device"} = $AddName;
                    }
                }
                else
                {
                    if($AddName ne $OldVendor) {
                        $Device{"Device"} = $AddName;
                    }
                }
            }
        }
        
        my $FinalName = $Device{"Device"};
        
        if(not $FinalName) {
            $FinalName = $OldName;
        }
        
        if($FinalName!~/root hub/i)
        {
            if($Info=~/iProduct[ ]+\w+[ ]+(.+)/)
            {
                if(my $SubDevice = fmtVal($1))
                {
                    if($FinalName)
                    {
                        my $N1 = $FinalName;
                        my $N2 = $SubDevice;
                        
                        $N2=~s/\AUSB //g;
                        
                        if($N1!~/\Q$N2\E/i and $N2!~/\Q$N1\E/i) {
                            $Device{"SDevice"} = $SubDevice;
                        }
                    }
                    else {
                        $Device{"Device"} = $SubDevice;
                    }
                }
            }
            elsif($OldName)
            {
                if($FinalName!~/\Q$OldName\E/i and $OldName!~/\Q$FinalName\E/i) {
                    $Device{"SDevice"} = $OldName;
                }
            }
            
            if($Info=~/iManufacturer[ ]+\w+[ ]+(.+)/)
            {
                if(my $SubVendor = fmtVal($1))
                {
                    $SubVendor=~s/\AManufacturer\s+//ig;

                    if($Vendor
                    and $SubVendor!~/usb/i and $SubVendor!~/generic/
                    and $SubVendor ne $Device{"SDevice"}
                    and $SubVendor ne $FinalName)
                    {
                        $Device{"SVendor"} = $SubVendor;
                    }
                }
            }
        }
        
        if(not $HW{"usb:".$ID}{"Type"})
        {
            $Device{"Type"} = getDefaultType("usb", \%Device);
            
            if(not $Device{"Type"})
            {
                if($Info=~/Camera Sensor/i) {
                    $Device{"Type"} = "camera";
                }
                elsif($Info=~/Uninterruptible Power Supply/i) {
                    $Device{"Type"} = "ups";
                }
                elsif($Info=~/Card Reader/i) {
                    $Device{"Type"} = "card reader";
                }
            }
            
            if(not $Device{"Type"})
            {
                if(@Class) {
                    $Device{"Type"} = getClassType("usb", devID(@Class));
                }
            }
        }
        
        cleanValues(\%Device);
        
        foreach (keys(%Device))
        {
            if($Device{$_}) {
                $HW{"usb:".$ID}{$_} = $Device{$_};
            }
        }
    }
    
    my $Usb_devices = "";
    
    if($Opt{"FixProbe"}) {
        $Usb_devices = readFile($FixProbe_Logs."/usb-devices");
    }
    else
    {
        if(checkCmd("usb-devices"))
        {
            listProbe("logs", "usb-devices");
            $Usb_devices = runCmd("usb-devices -v 2>&1");
            $Usb_devices = encryptSerials($Usb_devices, "SerialNumber");
        }
        
        if($Opt{"HWLogs"}) {
            writeLog($LOG_DIR."/usb-devices", $Usb_devices);
        }
    }
    
    foreach my $Info (split(/\n\n/, $Usb_devices))
    {
        my ($V, $D) = ();
        
        if($Info=~/Vendor=([^ ]+)/) {
            $V = $1;
        }
        
        if($Info=~/ProdID=([^ ]+)/) {
            $D = $1;
        }
        
        my %Driver = ();
        
        while($Info=~s/Driver=([\w\-]+)//)
        {
            my $Dr = $1;
            $Dr=~s/\-/_/g;
            
            if(not defined $Driver{$Dr}) {
                $Driver{$Dr} = keys(%Driver);
            }
        }
        
        if($V and $D)
        {
            my $ID = devID($V, $D);
            
            if(defined $HW{"usb:".$ID} and not defined $HW{"usb:".$ID}{"Driver"})
            {
                if(my @Dr = keys(%Driver))
                {
                    @Dr = sort {$Driver{$a} <=> $Driver{$b}} @Dr;
                    $HW{"usb:".$ID}{"Driver"} = join(", ", @Dr);
                }
            }
        }
    }
    
    # Fix incorrectly detected drivers
    foreach my $ID (sort keys(%HW))
    {
        my $Driver = $HW{$ID}{"Driver"};
        
        if(not $Driver) {
            next;
        }
        
        my %Drivers = ();
        my $Num = 0;
        
        foreach my $Dr (split(/\,\s+/, $Driver)) {
            $Drivers{$Dr} = $Num++
        }
        
        if(keys(%WorkMod))
        { # lsmod is collected
            if(defined $Drivers{"nouveau"})
            {
                if(defined $WorkMod{"nvidia"})
                {
                    delete($Drivers{"nouveau"});
                    $Drivers{"nvidia"} = 1;
                }
            }
            
            if(defined $Drivers{"nvidia"} and defined $WorkMod{"nvidia"})
            {
                foreach ("nvidiafb", "nvidia_drm")
                {
                    if(defined $Drivers{$_}) {
                        delete($Drivers{$_});
                    }
                }
            }
            
            if(defined $Drivers{"radeon"})
            {
                if(defined $Drivers{"amdgpu"} and defined $WorkMod{"amdgpu"}) {
                    delete($Drivers{"radeon"});
                }
            }
            
            foreach my $Dr (@G_DRIVERS)
            {
                if(defined $Drivers{$Dr})
                {
                    if(not defined $WorkMod{$Dr}) {
                        delete($Drivers{$Dr});
                    }
                }
            }
            
            foreach my $Dr (sort keys(%Drivers))
            {
                if($Dr=~/\Anvidia/)
                { # nvidia346, nvidia_375, etc.
                    if(not defined $WorkMod{"nvidia"}) {
                        delete($Drivers{$Dr});
                    }
                }
            }
            
            if($Driver ne "wl" and defined $Drivers{"wl"})
            {
                if(not defined $WorkMod{"wl"}) {
                    delete($Drivers{"wl"});
                }
            }
        }
        
        $HW{$ID}{"Driver"} = join(", ", sort {$Drivers{$a}<=>$Drivers{$b}} keys(%Drivers));
    }
    
    # Fix incorrectly detected types
    foreach my $ID (sort keys(%HW))
    {
        my $Type = $HW{$ID}{"Type"};
        my $Type_New = undef;
        
        if($Type eq "cdrom" or $Type eq "serial controller")
        {
            my $Device = $HW{$ID}{"Device"};
            my $SDevice = $HW{$ID}{"SDevice"};
            my $Vendor = $HW{$ID}{"Vendor"};
            
            if($Vendor=~/Huawei/i
            and ($Device=~/modem|mobile|broadband/i
            or $SDevice=~/modem|mobile|broadband/i)) {
                $Type_New = "modem";
            }
        }
        
        if(defined $Type_New) {
            $HW{$ID}{"Type"} = $Type_New;
        }
    }
    
    # Fix status of graphics cards, network devices, etc.
    my $PCIDrivers = 0;
    
    foreach my $ID (sort keys(%HW))
    {
        if($HW{$ID}{"Driver"}
        and $ID=~/\Apci/)
        {
            $PCIDrivers = 1;
            last;
        }
    }
    
    foreach my $ID (sort keys(%HW))
    {
        my $DevType = $HW{$ID}{"Type"};
        
        if($DevType eq "graphics card")
        {
            if($ID=~/\w+:(.+?)\-/)
            {
                $GraphicsCards{$1}{$ID} = $HW{$ID}{"Driver"};
                $GraphicsCards_All{$ID} = $HW{$ID}{"Driver"};
            }
        }
        elsif(grep { $DevType eq $_ } ("bluetooth", "camera", "card reader", "chipcard", "communication controller", "dvb card", "fingerprint reader", "firewire controller", "flash memory", "modem", "multimedia controller", "network", "sd host controller", "sound", "storage", "system peripheral", "tv card", "video", "wireless"))
        {
            if(grep { $DevType eq $_ } ("sd host controller", "system peripheral")
            and $HW{$ID}{"Vendor"}=~/Intel/) {
                next;
            }
            
            if($ID=~/\A(usb|pci|ide|sdio):/)
            {
                if($1 ne "pci" or $PCIDrivers)
                {
                    if(not $HW{$ID}{"Driver"}) {
                        $HW{$ID}{"Status"} = "failed";
                    }
                }
            }
            
            if($HW{$ID}{"Status"} eq "works") {
                setAttachedStatus($ID, "works");
            }
        }
    }
    
    foreach my $V (sort keys(%GraphicsCards))
    {
        foreach my $ID (sort keys(%{$GraphicsCards{$V}}))
        {
            if(index($HW{$ID}{"Device"}, "Secondary")!=-1) {
                next;
            }
            
            if($HW{$ID}{"Class"} eq "03-80"
            and keys(%{$GraphicsCards{$V}})>=2) {
                next;
            }
            
            if(not $GraphicsCards{$V}{$ID}
            and $Sys{"Type"}!~/portable|laptop|notebook|docking/)
            { # not a hybrid graphics
                if(grep { $GraphicsCards_All{$_} } keys(%GraphicsCards_All))
                { # some of them are connected
                    next;
                }
            }
            
            if(grep {$V eq $_} ("1002", "8086"))
            {
                if(not $GraphicsCards{$V}{$ID}) {
                    $HW{$ID}{"Status"} = "failed";
                }
            }
            elsif($V eq "10de")
            {
                if(not defined $GraphicsCards{"8086"})
                {
                    if(not $GraphicsCards{$V}{$ID}) {
                        $HW{$ID}{"Status"} = "failed";
                    }
                }
            }
        }
    }
    
    # DMI
    my $Dmidecode = "";
    
    if($Opt{"FixProbe"}) {
        $Dmidecode = readFile($FixProbe_Logs."/dmidecode");
    }
    else
    {
        if(checkCmd("dmidecode"))
        {
            listProbe("logs", "dmidecode");
            $Dmidecode = runCmd("dmidecode 2>&1");
            $Dmidecode = hideTags($Dmidecode, "UUID|Asset Tag");
            $Dmidecode = encryptSerials($Dmidecode, "Serial Number");
        }
        
        if($Opt{"HWLogs"}) {
            writeLog($LOG_DIR."/dmidecode", $Dmidecode);
        }
    }
    
    my $MemIndex = 0;
    my %MemIDs = ();
    
    foreach my $Info (split(/\n\n/, $Dmidecode))
    {
        my %Device = ();
        my $D = "";
        my $ID = "";
        
        $Info=~s/[ ]{2,}/ /g;
        
        if($Info=~/Chassis Information\n/)
        { # notebook or desktop
            if($Info=~/Type:[ ]*(.+?)[ ]*(\n|\Z)/)
            {
                if(my $CType = getChassisType($1)) {
                    $Sys{"Type"} = $CType;
                }
            }
        }
        elsif($Info=~/System Information\n/)
        {
            if($Info=~/Manufacturer:[ ]*(.+?)[ ]*(\n|\Z)/) {
                $Sys{"Vendor"} = fmtVal($1);
            }
            
            if($Info=~/Product Name:[ ]*(.+?)[ ]*(\n|\Z)/) {
                $Sys{"Model"} = $1;
            }
            
            if($Info=~/Version:[ ]*(.+?)[ ]*(\n|\Z)/) {
                $Sys{"Version"} = $1;
            }
            
            if($Info=~/Family:[ ]*(.+?)[ ]*(\n|\Z)/) {
                $Sys{"Family"} = $1;
            }
            
            # clear
            if(emptyProduct($Sys{"Vendor"})) {
                $Sys{"Vendor"} = "";
            }
            
            if(emptyProduct($Sys{"Model"})) {
                $Sys{"Model"} = "";
            }
            
            if(emptyProduct($Sys{"Version"})) {
                $Sys{"Version"} = "";
            }
        }
        elsif($Info=~/Memory Device\n/) # $Info=~/Memory Module Information\n/
        {
            my @Add = ();
            
            while($Info=~s/([\w ]+):[ \t]*(.+?)[ \t]*(\n|\Z)//)
            {
                my ($Key, $Val) = ($1, fmtVal($2));
                
                if(grep { lc($Val) eq $_ } ("unknown", "other")) {
                    next;
                }
                
                if(grep { $Val=~/$_/i } ("OUT OF SPEC", "NOT AVAILABLE")) {
                    next;
                }
                
                if($Key eq "Manufacturer") {
                    $Device{"Vendor"} = nameID($Val, "memory");
                }
                elsif($Key eq "Part Number") {
                    $Device{"Device"} = $Val;
                }
                elsif($Key eq "Serial Number") {
                    $Device{"Serial"} = $Val;
                }
                elsif($Key eq "Type")
                {
                    if($Val eq "Reserved") {
                        next;
                    }
                    
                    if(my $FF = $Device{"FF"}) {
                        $Val=~s/ \Q$FF\E\Z//;
                    }
                    $Device{"Kind"} = $Val;
                    push(@Add, $Val);
                }
                elsif($Key eq "Size")
                {
                    $Device{"Size"} = $Val;
                    
                    $Val=~s/ //g;
                    push(@Add, $Val);
                }
                elsif($Key eq "Speed")
                {
                    $Device{"Speed"} = $Val;
                    
                    $Val=~s/ //g;
                    push(@Add, $Val);
                }
                # Memory Module
                elsif($Key eq "Installed Size")
                {
                    $Device{"Size"} = $Val;
                    
                    $Val=~s/ //g;
                    $Val=~s/\(.+\)//g;
                    
                    push(@Add, $Val);
                }
                elsif($Key eq "Current Speed")
                {
                    $Device{"Speed"} = $Val;
                    
                    $Val=~s/ //g;
                    push(@Add, $Val);
                }
                elsif($Key eq "Form Factor")
                {
                    $Device{"FF"} = $Val;
                    push(@Add, $Val);
                }
            }
            
            cleanValues(\%Device);
            
            if($Device{"Size"} eq "No Module Installed") {
                next;
            }
            
            if($Device{"Size"} eq "Not Installed") {
                next;
            }
            
            if(grep { $Device{"FF"} eq $_ } ("Chip", "TSOP")
            or $Device{"Kind"} eq "Flash")
            { # TODO: add this kind of devices
                next;
            }
            
            $Device{"Type"} = "memory";
            $Device{"Status"} = "works";
            
            my $Inc = 0;
            
            if($Device{"Vendor"})
            {
                if($Device{"Vendor"}=~/\A(JEDEC|Unknown) ID:(.+)/)
                {
                    $Device{"Vendor"} = $2;
                    $Device{"Vendor"}=~s/ //g;
                }
                elsif($Device{"Vendor"}=~/\AUnknown - \[0x(.+)\]/) {
                    $Device{"Vendor"} = $1;
                }
                
                if(defined $JedecVendor{$Device{"Vendor"}}) {
                    $Device{"Vendor"} = $JedecVendor{$Device{"Vendor"}};
                }
                elsif($Device{"Vendor"}=~/\A0x(.+)\Z/
                and defined $JedecVendor{$1}) {
                    $Device{"Vendor"} = $JedecVendor{$1};
                }
                elsif($Device{"Vendor"}=~/\A(0x|)([A-F\d]{4})/
                and defined $JedecVendor{$2}) {
                    $Device{"Vendor"} = $JedecVendor{$2};
                }
            }
            
            if(not $Device{"Vendor"} or isUnknownRam($Device{"Vendor"}))
            {
                if(my $GuessVendor = guessRamVendor($Device{"Device"})) {
                    $Device{"Vendor"} = $GuessVendor;
                }
            }
            
            if(not $Device{"Vendor"} or isUnknownRam($Device{"Vendor"}))
            {
                if(defined $RamVendor{$Device{"Device"}}) {
                    $Device{"Vendor"} = $RamVendor{$Device{"Device"}};
                }
            }
            
            if(not $Device{"Vendor"})
            {
                $Device{"Vendor"} = "Manufacturer".$MemIndex;
                $Inc = 1;
            }
            
            if(not $Device{"Device"})
            {
                $Device{"Device"} = "Partnum".$MemIndex;
                $Inc = 1;
            }
            
            if(not $Device{"Serial"})
            {
                $Device{"Serial"} = "Sernum".$MemIndex;
                $Inc = 1;
            }
            
            $Device{"Size"}=~s/ //g;
            $Device{"Speed"}=~s/ (MHz|MT\/s)//;
            
            if($Inc) {
                $MemIndex++;
            }
            
            if(isUnknownRam($Device{"Vendor"})) {
                $Device{"Vendor"} = undef;
            }
            
            $Device{"Device"} = duplVendor($Device{"Vendor"}, $Device{"Device"});
            
            if($Device{"Device"}=~/\A(\s*)\Z/
            or $Device{"Device"}=~/\A(SODIMM)\d+\Z/i
            or $Device{"Device"}=~/\AArray\d+_(Part)Number\d+\Z/i
            or $Device{"Device"}=~/\A(Part)Num\d+\Z/i
            or $Device{"Device"}=~/\A(0x)[\dA-F]+\Z/i
            or $Device{"Device"}=~/\A(0)0+\Z/i
            or $Device{"Device"}=~/Module(Part)Number/i
            or $Device{"Device"}=~/NOT AVAILABLE/i)
            {
                $Device{"Device"} = $1;
                if(not $Device{"Device"} or grep { lc($Device{"Device"}) eq $_ } ("part", "0x", "0")) {
                    $Device{"Device"} = "RAM Module";
                }
                
                $ID = devID(nameID($Device{"Vendor"}), $Device{"Device"});
                if($Device{"Size"} or $Device{"Kind"} or $Device{"Speed"}) {
                    $ID = devID($ID, $Device{"Size"}, $Device{"Kind"}, $Device{"Speed"});
                }
                if($Device{"Serial"}) {
                    $ID = devID($ID, "serial", $Device{"Serial"});
                }
            }
            else
            {
                $ID = devID(nameID($Device{"Vendor"}), devSuffix(\%Device));
                $Device{"Device"} = "RAM ".$Device{"Device"};
            }
            $ID = fmtID($ID);
            
            if(defined $MemIDs{$ID})
            { # ERROR: the same ID of RAM memory module
                $ID .= "-".keys(%MemIDs);
            }
            
            $MemIDs{$ID} = 1;
            
            if(@Add)
            { # additionals
                $Device{"Device"} .= " ".join(" ", @Add);
                $Device{"Device"}=~s/\A\s+//g;
            }
            
            if($ID) {
                $HW{"mem:".$ID} = \%Device;
            }
        }
        elsif($Info=~/Base Board Information\n/)
        {
            while($Info=~s/([\w ]+):[ \t]*(.+?)[ \t]*(\n|\Z)//)
            {
                my ($Key, $Val) = ($1, $2);
                
                if($Key eq "Manufacturer") {
                    $Device{"Vendor"} = fmtVal($Val);
                }
                elsif($Key eq "Product Name") {
                    $Device{"Device"} = fmtVal($Val);
                }
                elsif($Key eq "Version") {
                    $Device{"Version"} = $Val;
                }
            }
            
            $Board_ID = detectBoard(\%Device);
        }
        elsif($Info=~/BIOS Information\n/)
        {
            while($Info=~s/([\w ]+):[ \t]*(.+?)[ \t]*(\n|\Z)//)
            {
                my ($Key, $Val) = ($1, $2);
                
                if($Key eq "Vendor") {
                    $Device{$Key} = fmtVal($Val);
                }
                elsif($Key eq "Version" or $Key eq "Release Date") {
                    $Device{$Key} = $Val;
                }
            }
            
            detectBIOS(\%Device);
        }
        elsif($Info=~/Processor Information\n/)
        {
            while($Info=~s/([\w ]+):[ \t]*(.+?)[ \t]*(\n|\Z)//)
            {
                my ($Key, $Val) = ($1, $2);
                
                if($Key eq "Manufacturer")
                {
                    $Device{"Vendor"} = fmtVal($Val);
                    
                    if($Device{"Vendor"}=~/Intel/) {
                        $Device{"Vendor"} = "Intel";
                    }
                    elsif($Device{"Vendor"}=~/AMD/) {
                        $Device{"Vendor"} = "AMD";
                    }
                }
                elsif($Key eq "Signature")
                { # Family 6, Model 42, Stepping 7
                    my @Model = ();
                    
                    if($Val=~/Family\s+(\w+),/) {
                        push(@Model, $1);
                    }
                    
                    if($Val=~/Model\s+(\w+),/) {
                        push(@Model, $1);
                    }
                    
                    if($Val=~/Stepping\s+(\w+)/) {
                        push(@Model, $1);
                    }
                    
                    $D = join(".", @Model);
                }
                elsif($Key eq "Version") {
                    $Device{"Device"} = fmtVal($Val);
                }
            }
            
            cleanValues(\%Device);
            
            $Device{"Device"} = duplVendor($Device{"Vendor"}, $Device{"Device"});
            
            $Device{"Type"} = "cpu";
            $Device{"Status"} = "works";
            
            if(not $CPU_ID)
            {
                $ID = devID(nameID($Device{"Vendor"}), $D, devSuffix(\%Device));
                $ID = fmtID($ID);
                
                if($ID)
                {
                    $CPU_ID = "cpu:".$ID;
                    $HW{$CPU_ID} = \%Device;
                }
            }
            else
            { # add info
                foreach (keys(%Device))
                {
                    my $Val1 = $HW{$CPU_ID}{$_};
                    my $Val2 = $Device{$_};
                    
                    if($Val2
                    and not $Val1) {
                        $HW{$CPU_ID}{$_} = $Val2;
                    }
                }
            }
        }
    }
    
    if($CPU_ID) {
        fixFFByCPU($HW{$CPU_ID}{"Device"});
    }
    
    foreach (keys(%{$ComponentID{"cdrom"}})) {
        fixFFByCDRom($HW{$_}{"Device"});
    }
    
    foreach (keys(%{$ComponentID{"graphics card"}})) {
        fixFFByGPU($HW{$_}{"Device"});
    }
    
    foreach (keys(%{$ComponentID{"monitor"}})) {
        fixFFByMonitor($HW{$_}{"Device"});
    }
    
    fixFFByModel($Sys{"Vendor"}, $Sys{"Model"});
    
    foreach (keys(%{$ComponentID{"touchpad"}})) {
        fixFFByTouchpad($_);
    }
    
    if($Board_ID)
    {
        fixFFByBoard($HW{$Board_ID}{"Device"});
        
        if(not $Sys{"Vendor"} or not $Sys{"Model"})
        {
            if($Sys{"Type"}=~/desktop|server/)
            {
                my ($MVendor, $MModel) = ($HW{$Board_ID}{"Vendor"}, shortModel($HW{$Board_ID}{"Device"}));
                
                if($MVendor eq "NA"
                or $MVendor=~/unkn|default|uknown/i) {
                    $MVendor = undef;
                }
                
                if($MModel eq "NA") {
                    $MModel = undef;
                }
                
                if(not $Sys{"Vendor"} and not $Sys{"Model"})
                {
                    $Sys{"Vendor"} = $MVendor;
                    $Sys{"Model"} = $MModel;
                }
                elsif(not $Sys{"Vendor"})
                {
                    if($Sys{"Model"} eq $MModel) {
                        $Sys{"Vendor"} = $MVendor;
                    }
                }
                elsif(not $Sys{"Model"})
                {
                    if($Sys{"Vendor"} eq $MVendor) {
                        $Sys{"Model"} = $MModel;
                    }
                }
            }
        }
    }
    
    # Printers
    my %Pr;
    
    my $HP_probe = "";
    
    if($Opt{"FixProbe"}) {
        $HP_probe = readFile($FixProbe_Logs."/hp-probe");
    }
    elsif($Opt{"Printers"} and enabledLog("hp-probe")
    and checkCmd("hp-probe"))
    {
        listProbe("logs", "hp-probe");
        
        # Net
        $HP_probe = runCmd("hp-probe -bnet -g 2>&1");
        $HP_probe .= "\n";
        
        # Usb
        $HP_probe .= runCmd("hp-probe -busb -g 2>&1");
        
        $HP_probe = clearLog($HP_probe);
        
        if($Opt{"HWLogs"}) {
            writeLog($LOG_DIR."/hp-probe", $HP_probe);
        }
    }
    
    foreach my $Line (split(/\n/, $HP_probe))
    {
        if($Line=~/Found device/)
        {
            my %Device = ();
            
            my %Attr = ();
            
            while($Line=~s/\'([^']*?)\'\s*:\s*\'([^']*?)\'//)
            {
                my ($Key, $Val) = ($1, $2);
                
                if($Val=~/MDL:(.*?);/) {
                    $Device{"Device"} = $1;
                }
                #if($Val=~/MFG:(.*?);/) {
                #    $Device{"Vendor"} = $1;
                #}
                
                $Attr{$Key} = $Val;
            }
            
            $Pr{$Device{"Device"}} = 1;
            
            if(not $Device{"Vendor"})
            {
                if(my $Vnd = guessDeviceVendor($Device{"Device"})) {
                    $Device{"Vendor"} = $Vnd;
                }
            }
            
            if(my $Vendor = $Device{"Vendor"})
            {
                $Device{"Device"} = duplVendor($Vendor, $Device{"Device"});
                $Pr{$Device{"Device"}} = 1;
            }
            
            $Device{"Type"} = "printer";
            if($Device{"Device"}=~/(\A| )MFP( |\Z)/) {
                $Device{"Type"} = "mfp";
            }
            
            # $Device{"Driver"} = "hplip";
            
            my $ID = devID($Device{"Vendor"}, $Device{"Device"});
            $ID = fmtID($ID);
            
            # additional info
            if(my $D = $Attr{"product_id"}) {
                $Device{"Device"} .= " ".$D;
            }
            
            if($ID) {
                $HW{"net:".$ID} = \%Device;
            }
        }
    }
    
    my $Avahi = "";
    
    if($Opt{"FixProbe"})
    {
        if(-f "$FixProbe_Logs/hp-probe")
        { # i.e. executed with -printers option (-fix)
            $Avahi = readFile("$FixProbe_Logs/avahi");
        }
    }
    elsif($Opt{"Printers"} and enabledLog("avahi")
    and checkCmd("avahi-browse"))
    {
        listProbe("logs", "avahi-browse");
        $Avahi = runCmd("avahi-browse -a -t 2>&1 | grep 'PDL Printer'");
        
        if($Opt{"HWLogs"} and $Avahi) {
            writeLog($LOG_DIR."/avahi", $Avahi);
        }
    }
    
    foreach my $Line (split(/\n/, $Avahi))
    {
        if($Line=~/IPv\d\s+(.*?)\s+PDL Printer/)
        {
            my %Device;
            
            $Device{"Device"} = $1;
            $Device{"Device"}=~s/\s*[\(\[].+[\)\]]//g;
            
            if($Pr{$Device{"Device"}})
            { # already registered
                next;
            }
            
            if(not $Device{"Vendor"})
            {
                if(my $Vnd = guessDeviceVendor($Device{"Device"})) {
                    $Device{"Vendor"} = $Vnd;
                }
            }
            
            if(my $Vendor = $Device{"Vendor"}) {
                $Device{"Device"} = duplVendor($Vendor, $Device{"Device"});
            }
            
            $Device{"Type"} = "printer";
            if($Device{"Device"}=~/(\A| )MFP( |\Z)/) {
                $Device{"Type"} = "mfp";
            }
            
            my $ID = devID($Device{"Vendor"}, $Device{"Device"});
            $ID = fmtID($ID);
            
            if($ID) {
                $HW{"net:".$ID} = \%Device;
            }
        }
    }
    
    # Monitors
    my $Edid = "";
    
    if($Opt{"FixProbe"})
    {
        $Edid = readFile($FixProbe_Logs."/edid");
        
        my $XRandrLog = $FixProbe_Logs."/xrandr";
        my $XOrgLog = $FixProbe_Logs."/xorg.log";
        
        if($Opt{"FixEdid"} and ($Edid or -s $XRandrLog or -s $XOrgLog))
        {
            my %EdidHex = ();
            my %FoundEdid = ();
            if(-s $XRandrLog)
            {
                my $RCard = undef;
                foreach my $L (split(/\n/, readFile($XRandrLog)))
                {
                    if($L=~/([^\s]+)\s+connected /) {
                        $RCard = $1."/edid";
                    }
                    elsif($RCard)
                    {
                        if($L=~/\s+(\w{32})\Z/) {
                            $FoundEdid{$RCard} .= $1."\n";
                        }
                    }
                }
            }
            
            if(not keys(%FoundEdid) and -s $XOrgLog)
            {
                my $XCard = "DEFAULT1";
                foreach my $L (split(/\n/, readFile($XOrgLog)))
                {
                    if($L=~/EDID for output ([\w\-]+)/) {
                        $XCard = $1."/edid";
                    }
                    elsif($XCard)
                    {
                        if($L=~/\s+(\w{32})\Z/) {
                            $FoundEdid{$XCard} .= $1."\n";
                        }
                    }
                }
            }
            
            if(index($Edid, "edid-decode")!=-1)
            {
                my %OldEdid = ();
                foreach my $Block (split(/edid-decode /, $Edid))
                {
                    if($Block=~/\A\"(.+?)\"/)
                    {
                        my $Card = $1;
                        
                        if($Card!~/edid/) {
                            $Card .= "/edid";
                        }
                        
                        if(not $OldEdid{$Card})
                        {
                            foreach my $L (split(/\n/, $Block))
                            {
                                if($L=~/([a-f0-9]{32})/)
                                {
                                    if(not defined $OldEdid{$Card}) {
                                        $OldEdid{$Card} = $1;
                                    }
                                    else {
                                        $OldEdid{$Card} .= " ".$1;
                                    }
                                }
                            }
                        }
                        
                        if(not $OldEdid{$Card})
                        {
                            foreach my $B (split(/\n\n/, $Block))
                            {
                                if($B=~/serial number:/)
                                {
                                    foreach my $L (split(/\n/, $B))
                                    {
                                        if($L=~/\A[a-z\d\s]+:\s+([a-f\d\s]+?)\Z/)
                                        {
                                            if(not defined $OldEdid{$Card}) {
                                                $OldEdid{$Card} = $1;
                                            }
                                            else {
                                                $OldEdid{$Card} .= " ".$1;
                                            }
                                        }
                                    }
                                    last;
                                }
                            }
                        }
                    }
                }
                
                foreach my $C (keys(%OldEdid))
                {
                    if($C!~/\A\//)
                    { # from Xrandr or Xorg
                        next;
                    }
                    
                    my $Hex = $OldEdid{$C};
                    $Hex=~s/\s//g;
                    $Hex=~s/(\w{32})/$1\n/g;
                    
                    if(grep {$FoundEdid{$_}=~/\A$Hex\w+/} keys(%FoundEdid))
                    { # extended EDID is available
                        next;
                    }
                    
                    $FoundEdid{$C} = $Hex;
                }
            }
            
            my $FixedContent = "";
            foreach my $C (sort {$b=~/\A\// cmp $a=~/\A\//} sort {lc($a) cmp lc($b)} keys(%FoundEdid))
            {
                my $Hex = $FoundEdid{$C};
                if(defined $EdidHex{$Hex}) {
                    next;
                }
                $EdidHex{$Hex} = 1;
                
                my $Decoded = decodeEdid($Hex);
                
                if($Decoded=~/No header found/i) {
                    next;
                }
                
                $FixedContent .= "edid-decode \"$C\":\n";
                $FixedContent .= "\nEDID (hex):\n".$Hex."\n";
                $FixedContent .= $Decoded;
                $FixedContent .= "\n\n";
            }
            
            if($FixedContent)
            {
                $Edid = $FixedContent;
                writeFile($FixProbe_Logs."/edid", $FixedContent);
            }
            else
            {
                if($Edid) {
                    printMsg("WARNING", "failed to fix EDID");
                }
                else {
                    printMsg("WARNING", "failed to create EDID");
                }
            }
        }
    }
    else
    { # NOTE: works for KMS video drivers only
        listProbe("logs", "edid");
        
        my $EdidDecode = checkCmd("edid-decode");
        
        my $MDir = "/sys/class/drm";
        foreach my $Dir (listDir($MDir))
        {
            my $Path = $MDir."/".$Dir."/edid";
            
            if(-f $Path)
            {
                my $Dec = "";
                my $EdidHex = readFileHex($Path);
                $EdidHex=~s/(.{32})/$1\n/g;
                
                if($EdidDecode) {
                    $Dec = runCmd("edid-decode \"$Path\" 2>/dev/null");
                }
                
                if($EdidHex)
                {
                    $Edid .= "edid-decode \"$Path\"\n\n";
                    $Edid .= "EDID (hex):\n";
                    $Edid .= $EdidHex."\n";
                    $Edid .= $Dec."\n\n";
                }
            }
        }
        
        if(not $Edid)
        { # for nvidia, fglrx
            if(my $MonEdid = checkCmd("monitor-get-edid"))
            {
                if($Admin)
                {
                    if($EdidDecode) {
                        $Edid .= runCmd("monitor-get-edid 2>/dev/null | edid-decode 2>&1");
                    }
                    else
                    { # LTS
                        $Edid .= runCmd("monitor-get-edid 2>/dev/null | monitor-parse-edid 2>/dev/null");
                    }
                    $Edid=~s/\n\n/\n/g;
                }
            }
        }
        
        if($Opt{"HWLogs"} and $Edid) {
            writeLog($LOG_DIR."/edid", $Edid);
        }
    }
    
    my @Mons = ();
    if(index($Edid, "edid-decode")!=-1) {
        @Mons = grep { /\S/ } split(/edid\-decode /, $Edid);
    }
    else {
        @Mons = ($Edid);
    }
    
    foreach my $Info (@Mons) {
        detectMonitor($Info);
    }
    
    # Battery
    my $Upower = "";
    
    if($Opt{"FixProbe"}) {
        $Upower = readFile($FixProbe_Logs."/upower");
    }
    elsif(checkCmd("upower"))
    {
        listProbe("logs", "upower");
        $Upower = runCmd("upower -d 2>/dev/null");
        $Upower = encryptSerials($Upower, "serial");
        if($Opt{"HWLogs"} and $Upower) {
            writeLog($LOG_DIR."/upower", $Upower);
        }
    }
    
    if($Upower)
    {
        foreach my $UPInfo (split(/\n\n/, $Upower))
        {
            if($UPInfo=~/devices\/battery_/ and $UPInfo!~/$HID_BATTERY/i)
            {
                my %Device = ();
                
                foreach my $Line (split(/\n/, $UPInfo))
                {
                    if($Line=~/vendor:[ ]*(.+?)[ ]*\Z/) {
                        $Device{"Vendor"} = fmtVal($1);
                    }
                    elsif($Line=~/model:[ ]*(.+?)[ ]*\Z/) {
                        $Device{"Device"} = fmtVal($1);
                    }
                    elsif($Line=~/serial:[ ]*(.+?)[ ]*\Z/) {
                        $Device{"Serial"} = $1;
                    }
                    elsif($Line=~/energy-full-design:[ ]*(.+?)[ ]*\Z/)
                    {
                        $Device{"Size"} = $1;
                        $Device{"Size"}=~s/\,/\./g;
                    }
                    elsif($Line=~/energy-full:[ ]*(.+?)[ ]*\Z/)
                    {
                        $Device{"CurSize"} = $1;
                        $Device{"CurSize"}=~s/\,/\./g;
                    }
                    elsif($Line=~/technology:[ ]*(.+?)[ ]*\Z/) {
                        $Device{"Technology"} = $1;
                    }
                    elsif($Line=~/capacity:[ ]*(.+?)[ ]*\Z/) {
                        $Device{"Capacity"} = $1;
                    }
                }
                
                if($Device{"Device"}=~/Keyboard|Mouse/i) {
                    next;
                }
                
                if(not $Device{"Size"}
                or $Device{"Size"} eq "0 Wh")
                {
                    my $C = $Device{"Capacity"};
                    $C=~s/\%//;
                    
                    my $F = $Device{"CurSize"};
                    $F=~s/ Wh//;
                    
                    $Device{"Size"} = ($F*100/$C)." Wh";
                }
                
                cleanValues(\%Device);
                
                registerBattery(\%Device);
            }
        }
    }
    
    my $PSDir = "/sys/class/power_supply";
    my $PowerSupply = "";
    
    if($Opt{"FixProbe"}) {
        $PowerSupply = readFile($FixProbe_Logs."/power_supply");
    }
    elsif(-d $PSDir)
    {
        listProbe("logs", "power_supply");
        foreach my $Bat (listDir($PSDir))
        {
            my $PSPath = $PSDir."/".$Bat;
            $PowerSupply .= $PSPath.":\n";
            $PowerSupply .= readFile($PSPath."/uevent");
            $PowerSupply .= "\n";
        }
        
        $PowerSupply = encryptSerials($PowerSupply, "SERIAL_NUMBER");
        
        if($Opt{"HWLogs"} and $PowerSupply) {
            writeLog($LOG_DIR."/power_supply", $PowerSupply);
        }
    }
    
    if(not $Upower and $PowerSupply)
    {
        foreach my $Block (split(/\n\n/, $PowerSupply))
        {
            if(($Block=~/$PSDir\/BAT/i or $Block=~/POWER_SUPPLY_CAPACITY\=/i)
            and $Block!~/$HID_BATTERY/i)
            {
                my %Device = ();
                
                if($Block=~/POWER_SUPPLY_MODEL_NAME=(.+)/i) {
                    $Device{"Device"} = $1;
                }
                
                if($Device{"Device"}=~/Keyboard|Mouse/i) {
                    next;
                }
                
                if($Block=~/POWER_SUPPLY_MANUFACTURER=(.+)/i) {
                    $Device{"Vendor"} = $1;
                }
                else
                {
                    if($Device{"Device"}=~s/\A(DELL)\s+//i) {
                        $Device{"Vendor"} = $1;
                    }
                }
                
                if($Block=~/POWER_SUPPLY_TECHNOLOGY=(.+)/i) {
                    $Device{"Technology"} = $1;
                }
                
                if($Block=~/POWER_SUPPLY_ENERGY_FULL_DESIGN=(.+)/i)
                {
                    if(my $EFullDesign = $1)
                    {
                        $Device{"Size"} = ($EFullDesign/1000000)." Wh";
                        
                        if($Block=~/POWER_SUPPLY_ENERGY_FULL=(.+)/i) {
                            $Device{"Capacity"} = $1*100/$EFullDesign;
                        }
                    }
                }
                
                if($Block=~/POWER_SUPPLY_CHARGE_FULL=(.+)/i) {
                    $Device{"Charge"} = $1;
                }
                
                if($Block=~/POWER_SUPPLY_CHARGE_FULL_DESIGN=(.+)/i)
                {
                    $Device{"DesignCharge"} = $1;
                    
                    if($Device{"Charge"}) {
                        $Device{"Capacity"} = $Device{"Charge"}*100/$Device{"DesignCharge"};
                    }
                }
                
                if($Block=~/POWER_SUPPLY_SERIAL_NUMBER=(.+)/i) {
                    $Device{"Serial"} = $1;
                }
                
                if($Block=~/POWER_SUPPLY_VOLTAGE_MIN_DESIGN=(.+)/i) {
                    $Device{"MinVoltage"} = $1;
                }
                
                if($Block=~/POWER_SUPPLY_VOLTAGE_MAX_DESIGN=(.+)/i) {
                    $Device{"MaxVoltage"} = $1;
                }
                
                if(not $Device{"Size"})
                {
                    if($Device{"MinVoltage"} and $Device{"DesignCharge"}) {
                        $Device{"Size"} = (($Device{"DesignCharge"}/1000000)*($Device{"MinVoltage"}/1000000))." Wh";
                    }
                    elsif($Device{"MaxVoltage"} and $Device{"Charge"}) {
                        $Device{"Size"} = (($Device{"Charge"}/1000000)*($Device{"MaxVoltage"}/1000000))." Wh";
                    }
                }
                
                registerBattery(\%Device);
            }
        }
    }
    
    # PNP
    my $Lspnp = "";
    if($Opt{"FixProbe"}) {
        $Lspnp = readFile($FixProbe_Logs."/lspnp");
    }
    elsif(enabledLog("lspnp")
    and checkCmd("lspnp"))
    {
        listProbe("logs", "lspnp");
        $Lspnp = runCmd("lspnp -vv 2>&1");
        if($Opt{"HWLogs"}) {
            writeLog($LOG_DIR."/lspnp", $Lspnp);
        }
    }
    
    # HDD
    my $Hdparm = "";
    if($Opt{"FixProbe"}) {
        $Hdparm = readFile($FixProbe_Logs."/hdparm");
    }
    elsif($Opt{"HWLogs"})
    {
        if($Admin and checkCmd("hdparm"))
        {
            listProbe("logs", "hdparm");
            foreach my $Dev (sort keys(%HDD))
            {
                if($Dev=~/\A\/dev\/sr\d+\Z/) {
                    next;
                }
                
                my $Id = $HDD{$Dev};
                
                if(index($Id, "usb:")==0 or index($Id, "scsi:")==0) {
                    next;
                }
                
                my $Output = runCmd("hdparm -I \"$Dev\" 2>/dev/null");
                $Output = encryptSerials($Output, "Serial Number");
                $Output = encryptSerials($Output, "Unique ID");
                $Output = hideTags($Output, "WWN Device Identifier");
                
                if(length($Output)<30)
                { # empty
                    next;
                }
                
                $Hdparm .= $Output;
            }
        }
        writeLog($LOG_DIR."/hdparm", $Hdparm);
    }
    
    my $Smartctl = "";
    
    my $SmartctlCmd = "smartctl";
    
    if($Opt{"Snap"} or $Opt{"AppImage"} or $Opt{"Flatpak"})
    {
        if(not $Opt{"FixProbe"} and $Opt{"HWLogs"}) {
            $SmartctlCmd = findCmd("smartctl");
        }
    }
    
    if($Opt{"FixProbe"})
    {
        $Smartctl = readFile($FixProbe_Logs."/smartctl");
        
        my $CurDev = undef;
        my %DriveDesc = ();
        foreach my $SL (split(/\n/, $Smartctl))
        {
            if(index($SL, "/dev/")==0) {
                $CurDev = $SL;
            }
            elsif($CurDev) {
                $DriveDesc{$CurDev} .= $SL."\n";
            }
        }
        foreach my $Dev (sort keys(%DriveDesc))
        {
            my $Id = $HDD{$Dev};
            if(not $Id) {
                $Id = detectDrive($DriveDesc{$Dev}, $Dev);
            }
            
            if($Id) {
                setDriveStatus($DriveDesc{$Dev}, $Id);
            }
        }
    }
    elsif($Opt{"HWLogs"})
    {
        if($Admin and checkCmd("smartctl")) # $Admin or $Opt{"Snap"} ?
        {
            listProbe("logs", "smartctl");
            my %CheckedScsi = ();
            my $SnapNoBlockDevices = 0;
            foreach my $Dev (sort keys(%HDD))
            {
                if($Dev=~/\A\/dev\/sr\d+\Z/) {
                    next;
                }
                
                my $Id = $HDD{$Dev};
                my $Output = runCmd($SmartctlCmd." -x \"".$Dev."\" 2>/dev/null");
                
                if(not $Output or $Output=~/Operation not permitted|Permission denied/)
                {
                    if($Opt{"Snap"} and not $SnapNoBlockDevices)
                    {
                        print STDERR "\nWARNING: Make sure 'block-devices' interface is connected to verify SMART attributes of your drives:\n\n";
                        print STDERR "    sudo snap connect hw-probe:block-devices :block-devices\n";
                        $SnapNoBlockDevices = 1;
                    }
                    next;
                }
                
                if(index($Id, "usb:")==0
                and $Output=~/Unsupported USB|Unknown USB/i)
                { # device doesn't provide SMART
                    next;
                }
                
                if(index($Id, "nvme:")==0
                and $Output=~/Unable to detect device type/i)
                { # old version of smartctl
                    next;
                }
                
                if(index($Id, "scsi:")==0)
                {
                    if(defined $CheckedScsi{$Id}) {
                        next;
                    }
                    $CheckedScsi{$Id} = 1;
                    
                    if($Output=~/Unsupported|Unknown|Unable/i) {
                        next;
                    }
                }
                
                $Output = encryptSerials($Output, "Serial Number");
                $Output = hideWWNs($Output);
                
                # $Output=~s/\A.*?(\=\=\=)/$1/sg;
                $Smartctl .= $Dev."\n".$Output."\n";
                
                if(not $Id) {
                    $Id = detectDrive($Output, $Dev);
                }
                
                if($Id) {
                    setDriveStatus($Output, $Id);
                }
            }
            
            writeLog($LOG_DIR."/smartctl", $Smartctl);
        }
        else
        { # write empty
            writeLog($LOG_DIR."/smartctl", "");
        }
    }
    
    if(not $Opt{"FixProbe"})
    {
        if($Admin and enabledLog("smart-log")
        and checkCmd("nvme"))
        {
            listProbe("logs", "smart-log");
            my $NvmeCli = "";
            foreach my $Dev (sort keys(%HDD))
            {
                if($Dev=~/nvme/)
                {
                    my $Output = runCmd("nvme smart-log \"".$Dev."\" 2>/dev/null");
                    my $OutputAdd = runCmd("nvme smart-log-add \"".$Dev."\" 2>/dev/null");
                    
                    if($Output or $OutputAdd)
                    {
                        $NvmeCli .= $Dev."\n";
                        if($Output) {
                            $NvmeCli .= $Output."\n";
                        }
                        if($OutputAdd) {
                            $NvmeCli .= $OutputAdd."\n";
                        }
                        $NvmeCli .= "\n";
                    }
                }
            }
            if($NvmeCli) {
                writeLog($LOG_DIR."/smart-log", $NvmeCli);
            }
        }
    }
    
    foreach my $Dev (keys(%HDD))
    {
        if(not $HDD{$Dev})
        {
            if(index($Dev, "nvme")!=-1)
            {
                my %Drv = ( "Type"=>"disk" );
                if(defined $HDD_Info{$Dev})
                {
                    foreach ("Capacity", "Driver", "Model", "Vendor") {
                        $Drv{$_} = $HDD_Info{$Dev}{$_};
                    }
                }
                
                if($Drv{"Model"} and my $Vnd = guessDeviceVendor($Drv{"Model"}))
                {
                    $Drv{"Vendor"} = $Vnd;
                    $Drv{"Model"} = duplVendor($Vnd, $Drv{"Model"});
                }
                
                if($Drv{"Model"} and $Drv{"Model"} ne "Disk") {
                    $Drv{"Device"} = $Drv{"Model"};
                }
                else {
                    $Drv{"Device"} = "NVMe SSD Drive";
                }
                
                $Drv{"Device"} .= addCapacity($Drv{"Device"}, $Drv{"Capacity"});
                
                my $DiskId = $PCI_DISK_BUS.":".devID("solid-state-drive", $Drv{"Capacity"});
                $HW{$DiskId} = \%Drv;
                countDevice($DiskId);
            }
        }
    }
    
    foreach my $Dev (keys(%MMC))
    {
        if(not $MMC{$Dev})
        {
            if(index($Dev, "mmcblk")!=-1)
            {
                my %Drv = ( "Type"=>"disk" );
                if(defined $MMC_Info{$Dev})
                {
                    foreach ("Capacity", "Driver", "Vendor", "Device", "Serial") {
                        $Drv{$_} = $MMC_Info{$Dev}{$_};
                    }
                }
                
                if(defined $VendorByModel{$Drv{"Device"}}) {
                    $Drv{"Vendor"} = $VendorByModel{$Drv{"Device"}};
                }
                
                $Drv{"Capacity"} = fixCapacity($Drv{"Capacity"});
                
                if($Drv{"Device"})
                {
                    $Drv{"Device"} .= " SSD".addCapacity($Drv{"Device"}, $Drv{"Capacity"});
                    
                    my $MmcId = "mmc:".fmtID(devID(nameID($Drv{"Vendor"}), devSuffix(\%Drv)));
                    $HW{$MmcId} = \%Drv;
                    countDevice($MmcId);
                }
            }
        }
    }
    
    my $SmartctlMR = "";
    if($Opt{"FixProbe"})
    {
        $SmartctlMR = readFile($FixProbe_Logs."/smartctl_megaraid");
        
        my ($CurDev, $CurDid) = (undef, undef);
        my %DriveDesc = ();
        foreach my $SL (split(/\n/, $SmartctlMR))
        {
            if(index($SL, "/dev/")==0)
            {
                if($SL=~/(.+),(.+)/) {
                    ($CurDev, $CurDid) = ($1, $2);
                }
            }
            elsif($CurDev) {
                $DriveDesc{$CurDev}{$CurDid} .= $SL."\n";
            }
        }
        foreach my $Dev (sort keys(%DriveDesc))
        {
            foreach my $Did (sort keys(%{$DriveDesc{$Dev}}))
            {
                my $Desc = $DriveDesc{$Dev}{$Did};
                if(my $Id = detectDrive($Desc, $Dev, 1)) {
                    setDriveStatus($Desc, $Id);
                }
            }
        }
    }
    else
    {
        my $StorcliCmd = undef;
        
        foreach my $Cmd ("storcli64", "storcli")
        {
            if(checkCmd($Cmd))
            {
                $StorcliCmd = $Cmd;
                last;
            }
        }
        
        if($StorcliCmd)
        { # MegaRAID
            listProbe("logs", "storcli");
            my $Storcli = runCmd($StorcliCmd." /call /vall /eall /sall show 2>&1");
            if($Storcli=~/No Controller found/i) {
                $Storcli = undef;
            }
            $Storcli = encryptSerials($Storcli, "SCSI NAA Id");
            if($Storcli) {
                writeLog($LOG_DIR."/storcli", $Storcli);
            }
            
            if($Storcli)
            {
                my %DInfo = ();
                my $Ctrl = undef;
                
                foreach my $L (split(/\n/, $Storcli))
                {
                    if($L=~/Controller = (\d+)/) {
                        $Ctrl = $1;
                    }
                    elsif($Ctrl and $L=~/SCSI NAA Id = (\w+)/) {
                        $DInfo{$Ctrl}{"NAA"} = $1;
                    }
                    elsif($Ctrl and $L=~/\d+:\d+\s+(\d+)/) {
                        $DInfo{$Ctrl}{"DID"}{$1} = 1;
                    }
                }
                
                my %DID = ();
                foreach my $Controller (sort {int($a)<=>int($b)} keys(%DInfo))
                {
                    if(my $NAA = $DInfo{$Controller}{"NAA"})
                    {
                        if(my $Dev = $DevNameById{"wwn-0x".$NAA})
                        {
                            foreach my $D (keys(%{$DInfo{$Controller}{"DID"}})) {
                                $DID{$Dev}{$D} = 1;
                            }
                        }
                    }
                }
                
                foreach my $Dev (sort keys(%DID))
                {
                    foreach my $Did (sort keys(%{$DID{$Dev}}))
                    {
                        my $Output = runCmd($SmartctlCmd." -x -d megaraid,$Did \"$Dev\" 2>/dev/null");
                        $Output = encryptSerials($Output, "Serial Number");
                        $Output = hideWWNs($Output);
                        
                        if($Output)
                        {
                            # $Output=~s/\A.*?(\=\=\=)/$1/sg;
                            $SmartctlMR .= $Dev.",".$Did."\n".$Output."\n";
                        }
                        
                        if(my $Id = detectDrive($Output, $Dev, 1)) {
                            setDriveStatus($Output, $Id);
                        }
                    }
                }
                
                if($SmartctlMR) {
                    writeLog($LOG_DIR."/smartctl_megaraid", $SmartctlMR);
                }
            }
        }
    }
    
    if(not $Opt{"FixProbe"} and not $SmartctlMR
    and enabledLog("megacli"))
    {
        my $MegacliCmd = undef;
        
        foreach my $Cmd ("megacli", "MegaCli64", "MegaCli")
        {
            if(checkCmd($Cmd))
            {
                $MegacliCmd = $Cmd;
                last;
            }
        }
        
        if($MegacliCmd)
        {
            listProbe("logs", "megacli");
            my $Megacli = runCmd($MegacliCmd." -PDList -aAll 2>&1");
            $Megacli=~s/(Inquiry Data\s*:.+?)\s\w+\n/$1.../g; # Hide serial
            $Megacli = encryptSerials($Megacli, "WWN");
            if($Megacli) {
                writeLog($LOG_DIR."/megacli", $Megacli);
            }
            
            # my %DIDs = ();
            # while($Megacli=~/Device Id\s*:\s*(\d+)/g) {
            #     $DIDs{$1} = 1;
            # }
        }
    }
    
    if(not $Opt{"FixProbe"})
    {
        if(enabledLog("megactl")
        and checkCmd("megactl"))
        {
            listProbe("logs", "megactl");
            my $Megactl = runCmd("megactl 2>&1");
            if($Megactl) {
                writeLog($LOG_DIR."/megactl", $Megactl);
            }
        }
    }
    
    if(not $Opt{"FixProbe"})
    {
        if(enabledLog("arcconf")
        and checkCmd("arcconf"))
        { # Adaptec RAID
            listProbe("logs", "arcconf");
            
            my @Controllers = ();
            my $ArcconfList = runCmd("arcconf LIST 2>&1");
            while($ArcconfList=~s/Controller\s+(\d+)//) {
                push(@Controllers, $1);
            }
            
            my $Arcconf = "";
            
            foreach my $Cn (@Controllers)
            {
                $Arcconf .= "Controller $Cn:\n";
                $Arcconf .= runCmd("arcconf GETCONFIG $Cn PD 2>&1");
                $Arcconf .= "\n";
            }
            
            if($Arcconf)
            {
                $Arcconf = encryptSerials($Arcconf, "Serial number");
                $Arcconf = encryptSerials($Arcconf, "World-wide name", "arcconf", 1);
                
                writeLog($LOG_DIR."/arcconf", $Arcconf);
            }
            
            listProbe("logs", "arcconf_smart");
            my $Arcconf_Smart = "";
            
            foreach my $Cn (@Controllers)
            {
                $Arcconf_Smart .= "Controller $Cn:\n";
                $Arcconf_Smart .= runCmd("arcconf GETSMARTSTATS $Cn TABULAR 2>&1");
                $Arcconf_Smart .= "\n";
            }
            
            if($Arcconf_Smart)
            {
                $Arcconf_Smart=~s/\.{4,}/:/g;
                $Arcconf_Smart = encryptSerials($Arcconf_Smart, "serialNumber");
                $Arcconf_Smart = encryptSerials($Arcconf_Smart, "vendorProductID");
                
                writeLog($LOG_DIR."/arcconf_smart", $Arcconf_Smart);
            }
        }
    }
    
    my $Dmesg = "";
    
    if($Opt{"FixProbe"}) {
        $Dmesg = readFile($FixProbe_Logs."/dmesg");
    }
    elsif(checkCmd("dmesg"))
    {
        listProbe("logs", "dmesg");
        $Dmesg = runCmd("dmesg 2>&1");
        $Dmesg = hideTags($Dmesg, "SerialNumber");
        $Dmesg = hideHostname($Dmesg);
        $Dmesg = hideIPs($Dmesg);
        $Dmesg = hideMACs($Dmesg);
        $Dmesg = hidePaths($Dmesg);
        
        if($Opt{"HWLogs"}) {
            writeLog($LOG_DIR."/dmesg", $Dmesg);
        }
    }
    
    if(not $Sys{"System"} and $Dmesg)
    {
        if($Dmesg=~/Linux version.+\-Ubuntu /) {
            $Sys{"System"} = "ubuntu";
        }
    }
    
    if(index($Dmesg, "Secure boot enabled")!=-1) { # or index($Dmesg, "Secure boot could not be determined")!=-1
        $Sys{"Secureboot"} = "enabled";
    }
    elsif(defined $Sys{"Secureboot"}) {
        delete($Sys{"Secureboot"});
    }
    
    if(not $Sys{"Model"} or $Sys{"Arch"}=~/arm|aarch/i)
    {
        if(index($Dmesg, "Machine model")!=-1)
        {
            if($Dmesg=~/Machine model: (.+)/)
            {
                $Sys{"Model"} = $1;
                if($Sys{"Model"}=~/(Orange Pi|Banana Pi|Raspberry Pi|Odroid)/i) {
                    $Sys{"Type"} = "system on chip";
                }
            }
        }
    }
    
    my $XLog = "";
    
    if($Opt{"FixProbe"}) {
        $XLog = readFile($FixProbe_Logs."/xorg.log");
    }
    else
    {
        listProbe("logs", "xorg.log");
        $XLog = readFile("/var/log/Xorg.0.log");
        
        if(not $XLog)
        {
            if(my $SessUser = getUser())
            { # Xorg.0.log in XWayland (Ubuntu 18.04)
                $XLog = readFile("/home/".$SessUser."/.local/share/xorg/Xorg.0.log");
            }
        }
        
        if(not $XLog) {
            $XLog = readFile("/home/ubuntu/.local/share/xorg/Xorg.0.log");
        }
        
        if($XLog)
        {
            $XLog = hideTags($XLog, "Serial#");
            $XLog = hidePaths($XLog);
            if(my $HostName = $ENV{"HOSTNAME"}) {
                $XLog=~s/ $HostName / NODE /g;
            }
        }
        
        if(not $Opt{"Docker"} or $XLog) {
            writeLog($LOG_DIR."/xorg.log", $XLog);
        }
    }
    
    my $CmdLine = "";
    my ($Nomodeset, $ForceVESA) = (undef, undef);
    
    if($XLog)
    {
        if($XLog=~/Kernel command line:(.*)/) {
            $CmdLine = $1;
        }
        
        $Nomodeset = (index($CmdLine, " nomodeset")!=-1 or index($CmdLine, " nokmsboot")!=-1);
        $ForceVESA = (index($CmdLine, "xdriver=vesa")!=-1);
        
        foreach my $D (@G_DRIVERS)
        {
            if($Nomodeset or index($CmdLine, "$D.modeset=0")!=-1)
            {
                if($ForceVESA or isIntelDriver($D))
                { # can't check
                    setCardStatus($D, "detected");
                    next;
                }
            }
            
            if(keys(%WorkMod) and defined $WorkMod{$D})
            {
                my @Loaded = ();
                my @Drs = ($D);
                
                if(isIntelDriver($D)) {
                    @Drs = ("intel", "modesetting");
                }
                elsif($D eq "nouveau")
                { # Manjaro 17
                    @Drs = ("nouveau", "nvidia");
                    # if(keys(%GraphicsCards)==1)
                    # { # Ubuntu 18
                    #     push(@Drs, "modesetting");
                    # }
                }
                elsif($D eq "amdgpu" and keys(%GraphicsCards)==1)
                { # Ubuntu 18
                    push(@Drs, "modesetting");
                }
                
                foreach my $Dr (@Drs)
                {
                    if(index($XLog, "LoadModule: \"$Dr\"")!=-1) {
                        push(@Loaded, $Dr);
                    }
                }
                
                if(@Loaded)
                {
                    my @Unloaded = ();
                    
                    foreach my $Dr (@Loaded)
                    {
                        if(index($XLog, "UnloadModule: \"$Dr\"")!=-1) {
                            push(@Unloaded, $Dr);
                        }
                    }
                    
                    if(isIntelDriver($D) and defined $GraphicsCards{"1002"}
                    and defined $WorkMod{"fglrx"})
                    { # fglrx by intel, intel is unloaded
                        setCardStatus($D, "works");
                        next;
                    }
                    
                    if($#Unloaded==$#Loaded) {
                        setCardStatus($D, "failed");
                    }
                    else {
                        setCardStatus($D, "works");
                    }
                }
                elsif(grep {$D eq $_} ("nvidia") and defined $GraphicsCards{"8086"})
                { # no entries in the Xorg.0.log
                    setCardStatus($D, "works");
                }
            }
            else
            { # no lsmod info
                my $DrLabel = uc($D);
                if(isIntelDriver($D)) {
                    $DrLabel = "intel";
                }
                
                if(index($XLog, ") ".$DrLabel."(")!=-1)
                { # (II) RADEON(0)
                  # (II) NOUVEAU(0)
                  # (II) intel(0)
                    setCardStatus($D, "works");
                }
            }
        }
    }
    else
    { # No Xorg log
        if($Dmesg)
        {
            if($Dmesg=~/Command line:(.*)/) {
                $CmdLine = $1;
            }
            
            $Nomodeset = (index($CmdLine, " nomodeset")!=-1 or index($CmdLine, " nokmsboot")!=-1);
            $ForceVESA = (index($CmdLine, "xdriver=vesa")!=-1);
        }
        
        foreach my $D (@G_DRIVERS)
        {
            if($Nomodeset or index($CmdLine, "$D.modeset=0")!=-1)
            {
                if($ForceVESA or isIntelDriver($D))
                { # can't check
                    setCardStatus($D, "detected");
                    next;
                }
            }
            
            if(defined $WorkMod{$D}) {
                setCardStatus($D, "works");
            }
        }
    }
    
    my $HciConfig = "";
    
    if($Opt{"FixProbe"})
    {
        $HciConfig = readFile($FixProbe_Logs."/hciconfig");
    }
    elsif(checkCmd("hciconfig"))
    {
        listProbe("logs", "hciconfig");
        $HciConfig = runCmd("hciconfig -a 2>&1");
        $HciConfig = hideMACs($HciConfig);
        if($HciConfig) {
            writeLog($LOG_DIR."/hciconfig", $HciConfig);
        }
    }
    
    if($HciConfig)
    {
        foreach my $HCI (split(/\n\n/, $HciConfig))
        {
            if(index($HCI, "UP RUNNING ")!=-1)
            {
                if($HCI=~/\A[^:]+:?\s/)
                {
                    foreach my $ID (sort grep {defined $HW{$_}{"Type"} and $HW{$_}{"Type"} eq "bluetooth"} keys(%HW))
                    { # TODO: identify particular bt devices by lsusb
                        if($HW{$ID}{"Driver"})
                        {
                            $HW{$ID}{"Status"} = "works";
                            setAttachedStatus($ID, "works");
                        }
                    }
                }
            }
        }
    }
    
    my $MmCli = "";
    
    if($Opt{"FixProbe"}) {
        $MmCli = readFile($FixProbe_Logs."/mmcli");
    }
    elsif(checkCmd("mmcli"))
    {
        listProbe("logs", "mmcli");
        my $Modems = runCmd("mmcli -L 2>&1");
        if($Modems=~/No modems were found/i) {
            $Modems = "";
        }
        
        my %MNums = ();
        while($Modems=~s/Modem\/(\d+)//) {
            $MNums{$1} = 1;
        }
        
        foreach my $Modem (sort {int($a)<=>int($b)} keys(%MNums))
        {
            my $MInfo = runCmd("mmcli -m $Modem");
            $MInfo = hideTags($MInfo, "own|imei|equipment id");
            $MmCli .= $MInfo;
            
            $MmCli .= "\n";
        }
        
        if($MmCli) {
            writeLog($LOG_DIR."/mmcli", $MmCli);
        }
    }
    
    if($MmCli)
    {
        foreach my $MM (split(/\n\n/, $MmCli))
        {
            if($MM=~/model:.*\[(\w+):(\w+)\]/)
            {
                if(my $ID = "usb:".lc($1."-".$2))
                {
                    if(defined $HW{$ID} and $HW{$ID}{"Driver"})
                    {
                        $HW{$ID}{"Status"} = "works";
                        setAttachedStatus($ID, "works");
                    }
                }
            }
        }
    }
    
    my $OpenscTool = "";
    
    if($Opt{"FixProbe"}) {
        $OpenscTool = readFile($FixProbe_Logs."/opensc-tool");
    }
    elsif(checkCmd("opensc-tool"))
    {
        listProbe("logs", "opensc-tool");
        $OpenscTool = runCmd("opensc-tool --list-readers");
        if($OpenscTool and $OpenscTool!~/No smart card readers/)
        {
            $OpenscTool=~s/ \([^\(\)]+\)//g;
            writeLog($LOG_DIR."/opensc-tool", $OpenscTool);
        }
    }
    
    if($OpenscTool)
    {
        foreach my $SCReader (split(/\n\n/, $OpenscTool))
        {
            if(index($SCReader, "Driver")!=-1)
            {
                foreach my $ID (sort grep {defined $HW{$_}{"Type"} and $HW{$_}{"Type"} eq "chipcard"} keys(%HW))
                { # TODO: match particular chipcard devices by name
                    if($HW{$ID}{"Driver"})
                    {
                        $HW{$ID}{"Status"} = "works";
                        setAttachedStatus($ID, "works");
                    }
                }
            }
        }
    }
    
    print "Ok\n";
}

sub registerBattery($)
{
    my $Device = $_[0];
    
    $Device->{"Type"} = "battery";
    
    if(not $Sys{"Type"}
    or $Sys{"Type"}=~/desktop|server|other/) {
        $Sys{"Type"} = "notebook";
    }
    
    if(defined $BatType{$Device->{"Technology"}}) {
        $Device->{"Technology"} = $BatType{$Device->{"Technology"}};
    }
    
    if($Device->{"Technology"} eq "Unknown") {
        $Device->{"Technology"} = undef;
    }
    
    if(not $Device->{"Device"}) {
        $Device->{"Device"} = "Battery";
    }
    
    if($Device->{"Size"}=~/(.+)( Wh)/) {
        $Device->{"Size"} = sprintf("%.1f", $1).$2;
    }
    
    my $ID = undef;
    
    if($Device->{"Device"}=~/\A(Battery|Primary|Dell|Bat)\d*\Z/i
    or not $Device->{"Vendor"})
    {
        $Device->{"Device"} = $1;
        
        if($Device->{"Size"}=~/(.+)( Wh)/) {
            $Device->{"Size"} = sprintf("%.0f", $1).$2;
        }
        $ID = devID(nameID($Device->{"Vendor"}), lc($Device->{"Device"}), $Device->{"Technology"}, $Device->{"Size"});
        if($Device->{"Serial"}) {
            $ID = devID($ID, "serial", $Device->{"Serial"});
        }
    }
    else
    {
        $ID = devID(nameID($Device->{"Vendor"}), devSuffix($Device));
        $Device->{"Device"} = "Battery ".$Device->{"Device"};
    }
    
    $ID = fmtID($ID);
    
    if($Device->{"Technology"}) {
        $Device->{"Device"} .= " ".$Device->{"Technology"};
    }
    
    if($Device->{"Size"}) {
        $Device->{"Device"} .= " ".$Device->{"Size"};
    }
    
    if($Device->{"Capacity"}=~/\A(\d+)/)
    {
        if($1>$MIN_BAT_CAPACITY) {
            $Device->{"Status"} = "works";
        }
        else {
            $Device->{"Status"} = "malfunc";
        }
    }
    
    if($ID) {
        $HW{"bat:".$ID} = $Device;
    }
}

sub fixCapacity($)
{
    my $Capacity = $_[0];
    if($Capacity=~/\A(31|63|127|255)GB\Z/)
    {
        my $Size = $1;
        my $NSize = $1 + 1;
        $Capacity=~s/\A\Q$Size\E(GB)\Z/$NSize$1/;
    }
    return $Capacity;
}

sub isIntelDriver($) {
    return grep {$_[0] eq $_} @G_DRIVERS_INTEL;
}

sub setDriveStatus($$)
{
    my ($Desc, $Id) = @_;
    
    if($Desc=~/result:\s*(PASSED|FAILED)/i)
    {
        my $Res = $1;
        if($Res eq "PASSED") {
            $HW{$Id}{"Status"} = "works";
        }
        elsif($Res eq "FAILED") {
            $HW{$Id}{"Status"} = "malfunc";
        }
    }
    
    setAttachedStatus($Id, "works"); # got SMART
}

sub setAttachedStatus(@)
{
    my $Id = shift(@_);
    my $Status = shift(@_);
    
    my $Recur = {};
    if(@_) {
        $Recur = shift(@_);
    }
    
    if(defined $Recur->{$Id}) {
        return;
    }
    
    $Recur->{$Id} = 1;
    
    if(my $DevNum = $DeviceNumByID{$Id})
    {
        if(my $AttachedTo = $DeviceAttached{$DevNum})
        {
            if(my $AttachedId = $DeviceIDByNum{$AttachedTo})
            {
                $HW{$AttachedId}{"Status"} = $Status;
                
                if($Status eq "works") {
                    setAttachedStatus($AttachedId, $Status, $Recur);
                }
            }
        }
    }
}

sub shortModel($)
{
    my $Mdl = $_[0];
    
    $Mdl=~s/\AMotherboard\s+//g;
    $Mdl=~s/\s+\Z//g;
    $Mdl=~s/\s*\(.+\)//g;
    $Mdl=~s/\s+Rev\s+.+//ig;
    $Mdl=~s/\s+REV\:[^\s]+//ig; # REV:0A
    $Mdl=~s/(\s+|\/)[x\d]+\.[x\d]+//i;
    $Mdl=~s/\s*[\.\*]\Z//;
    $Mdl=~s/\s*\d\*.*//; # Motherboard C31 1*V1.*
    $Mdl=~s/\s+(Unknow|INVALID|Default string)\Z//;
    
    # $Mdl=~s/\s+R\d+\.\d+\Z//ig; # R2.0
    
    return $Mdl;
}

sub shortOS($)
{
    my $Name = $_[0];
    $Name=~s/\s+(linux|project|amd64|x86_64)\s+/ /i;
    $Name=~s/\s*(linux|project|amd64|x86_64)\Z//i;
    $Name=~s/\s+/\-/g;
    $Name=~s/\.\Z//g;
    return $Name;
}

sub detectBoard($)
{
    my $Device = $_[0];
    
    $Device->{"Vendor"}=~s{\Ahttp://www\.}{}i; # http://www.abit.com.tw as vendor
    if(index($Device->{"Vendor"}, "abit.com.tw")!=-1) {
        $Device->{"Vendor"} = "ABIT";
    }
    
    if($Device->{"Version"}=~/\b(n\/a|Not)\b/i) {
        $Device->{"Version"} = undef;
    }
    
    cleanValues($Device);
    
    if(emptyProduct($Device->{"Version"})) {
        delete($Device->{"Version"});
    }
    
    if($Device->{"Device"}=~/\bName\d*\b/i)
    { # no info
        return;
    }
    
    if(not $Device->{"Vendor"})
    {
        if($Device->{"Device"}=~/\AConRoe[A-Z\d]/)
        { # ConRoe1333, ConRoeXFire
            $Device->{"Vendor"} = "ASRock";
        }
    }
    
    if(my $Ver = $Device->{"Version"}) {
        $Device->{"Device"} .= " ".$Ver;
    }
    
    if(my $Vendor = $Device->{"Vendor"}) {
        $Device->{"Device"}=~s/\A\Q$Vendor\E\s+//ig;
    }
    
    $Device->{"Type"} = "motherboard";
    $Device->{"Status"} = "works";
    
    if(not $Device->{"Vendor"}) {
        $Device->{"Vendor"} = $VendorByModel{shortModel($Device->{"Device"})};
    }
    
    if(not $Device->{"Vendor"})
    {
        if($Device->{"Device"}=~/\AMS\-\d+\Z/) {
            $Device->{"Vendor"} = "MSI";
        }
        elsif($Device->{"Device"}=~/\ASiS\-\d+/) {
            $Device->{"Vendor"} = "SiS Technology";
        }
        elsif($Device->{"Device"}=~/\A(4CoreDual|4Core1600|775XFire|ALiveNF)/) {
            $Device->{"Vendor"} = "ASRock";
        }
    }
    
    if(not $Device->{"Vendor"} or not $Device->{"Device"}) {
        return;
    }
    
    my $ID = devID(nameID($Device->{"Vendor"}), devSuffix($Device));
    $ID = fmtID($ID);
    
    $Device->{"Device"} = "Motherboard ".$Device->{"Device"};
    
    my $MID = "board:".$ID;
    $HW{$MID} = $Device;
    
    return $MID;
}

sub detectBIOS($)
{
    my $Device = $_[0];
    
    cleanValues($Device);
    
    my @Name = ();
    
    if($Device->{"Version"}) {
        push(@Name, $Device->{"Version"});
    }
    
    if(my $BiosDate = $Device->{"Release Date"})
    {
        push(@Name, $Device->{"Release Date"});
        
        if($BiosDate=~/\b(\d\d\d\d)\b/) {
            $Sys{"Year"} = $1;
        }
    }
    
    $Device->{"Device"} = join(" ", @Name);
    
    if(not $Device->{"Vendor"} or not $Device->{"Device"}) {
        return;
    }
    
    $Device->{"Type"} = "bios";
    $Device->{"Status"} = "works";
    
    my $ID = devID(nameID($Device->{"Vendor"}), devSuffix($Device));
    $ID = fmtID($ID);
    
    $Device->{"Device"} = "BIOS ".$Device->{"Device"};
    
    if($ID) {
        $HW{"bios:".$ID} = $Device;
    }
}

sub detectMonitor($)
{
    my $Info = $_[0];
    
    my ($V, $D) = ();
    my %Device = ();
    
    if($Info=~/Digital display/) {
        $Device{"Kind"} = "Digital";
    }
    elsif($Info=~/Analog display/) {
        $Device{"Kind"} = "Analog";
    }
    
    if($Info=~/Made in (.+)/) {
        $Device{"Made"} = $1;
    }
    
    if($Info=~/Manufacturer:\s*(.+?)\s+Model\s+(.+?)\s+Serial/)
    {
        ($V, $D) = ($1, $2);
        if(length($D)<4)
        {
            foreach (1 .. 4 - length($D)) {
                $D = "0".$D;
            }
        }
    }
    elsif($Info=~/EISA ID:\s*(\w{3})(\w+)/) {
        ($V, $D) = (uc($1), uc($2));
    }

    if(not $V or not $D) {
        return;
    }
    
    if($V eq "\@\@\@") {
        return;
    }
    
    if($Info=~/Monitor name:\s*(.*?)(\n|\Z)/) {
        $Device{"Device"} = $1;
    }
    else
    {
        # if($Info=~s/ASCII string:\s*(.*?)(\n|\Z)//)
        # { # broken data
        #     if($Info=~s/ASCII string:\s*(.*?)(\n|\Z)//)
        #     {
        #         $Device{"Device"} = $1;
        #     }
        # }
    }
    
    foreach my $Attr ("Maximum image size", "Screen size", "Detailed mode")
    {
        if($Info=~/$Attr:(.+?)\n/i)
        {
            my $MonSize = $1;
            
            if($MonSize=~/(\d+)\s*mm\s*x\s*(\d+)\s*mm/) {
                $Device{"Size"} = $1."x".$2."mm";
            }
            elsif($MonSize=~/([\d\.]+)\s*cm\s*x\s*([\d\.]+)\s*cm/) {
                $Device{"Size"} = ($1*10)."x".($2*10)."mm";
            }
            
            if($Device{"Size"}) {
                last;
            }
        }
    }
    
    if(grep {$Device{"Size"} eq $_} ("1600x900mm", "160x90mm", "16x9mm", "0x0mm")) {
        $Device{"Size"} = undef;
    }
    
    $Info=~s/CTA extension block.+//s;
    
    my %Resolutions = ();
    while($Info=~s/(\d+)x(\d+)\@\d+//) {
        $Resolutions{$1} = $2;
    }

    while($Info=~s/\n\s+(\d+)\s+.+?\s+hborder//)
    {
        my $W = $1;
        if($Info=~s/\n\s+(\d+)\s+.+?\s+vborder//)
        {
            my $H = $1;
            
            if(not defined $Resolutions{$W} or $H>$Resolutions{$W}) {
                $Resolutions{$W} = $H;
            }
        }
    }
    
    if(my @Res = sort {int($b)<=>int($a)} keys(%Resolutions)) {
        $Device{"Resolution"} = $Res[0]."x".$Resolutions{$Res[0]};
    }
    
    if(not $Device{"Resolution"})
    { # monitor-parse-edid
        if($Info=~s/"(\d+x\d+)"//) {
            $Device{"Resolution"} = $1;
        }
    }
    
    if($V)
    {
        if(my $Vendor = getPnpVendor($V))
        {
            $Device{"Vendor"} = $Vendor;
            $Device{"Device"}=~s/\A\Q$Vendor\E(\s+|\-)//ig;
        }
        elsif(not $Device{"Vendor"}) {
            $Device{"Vendor"} = $V;
        }
    }
    
    my $MName = $Device{"Device"};
    
    if(not $MName or $Device{"Vendor"}=~/\Q$MName\E/i) {
        $Device{"Device"} = "LCD Monitor";
    }
    
    my $ID = undef;
    
    if($Device{"Vendor"})
    {
        if($Device{"Vendor"} ne $V) {
            $ID = devID(nameID($Device{"Vendor"}));
        }
    }
    $ID = devID($ID, $V.$D);
    $ID = fmtID($ID);
    
    if(my $OldID = $Monitor_ID{uc($V.$D)})
    {
        my $OldID_F = "eisa:".$OldID;
        my $Name = $Device{"Device"};
        
        if($Name ne "LCD Monitor")
        {
            if($HW{$OldID_F}{"Vendor"}!~/\Q$Name\E/i) {
                $HW{$OldID_F}{"Device"}=~s/LCD Monitor/$Name/;
            }
        }
        $HW{$OldID_F}{"Status"} = "works"; # got EDID
        
        if(my $Res = $Device{"Resolution"}) {
            $HW{$OldID_F}{"Device"}=~s/ \d+x\d+ / $Res /;
        }
        
        return;
    }
    
    if($D) {
        $Device{"Device"} .= " ".uc($V.$D);
    }
    
    if($Device{"Resolution"}) {
        $Device{"Device"} .= " ".$Device{"Resolution"};
    }
    
    if($Device{"Size"}) {
        $Device{"Device"} .= " ".$Device{"Size"};
    }
    
    if(my $Inch = computeInch($Device{"Device"}))
    {
        $Device{"Inches"} .= $Inch;
        $Device{"Device"} .= " ".$Inch."-inch";
    }
    
    $Device{"Type"} = "monitor";
    
    if($Opt{"IdentifyMonitor"})
    {
        $Device{"Vendor"} = nameID($Device{"Vendor"});
        
        if(not defined $MonVendor{$V})
        {
            if(grep {$V eq $_} @UnknownMonVendor) {
                $Device{"KnownUnknown"} = 1;
            }
            else {
                $Device{"Unknown"} = 1;
            }
        }
    }
    
    if($ID)
    {
        if(not defined $HW{"eisa:".$ID})
        {
            $HW{"eisa:".$ID} = \%Device;
            $HW{"eisa:".$ID}{"Status"} = "works"; # got EDID
        }
    }
}

sub detectDrive(@)
{
    my $Desc = shift(@_);
    my $Dev = undef;
    my $Raid = undef;
    
    if(@_) {
        $Dev = shift(@_);
    }
    if(@_) {
        $Raid = shift(@_);
    }
    
    my $Device = { "Type"=>"disk" };
    
    my $Bus = "ide"; # SATA, PATA, M.2, mSATA, etc.
    if(index($Dev, "nvme")!=-1)
    {
        $Bus = $PCI_DISK_BUS;
        $Device->{"Kind"} = "NVMe";
    }
    
    if(not $Opt{"IdentifyDrive"} and not $Raid
    and defined $HDD_Info{$Dev})
    {
        foreach ("Capacity", "Driver") {
            $Device->{$_} = $HDD_Info{$Dev}{$_};
        }
    }
    
    if($Desc=~/Serial Number:\s*(.+?)(\Z|\n)/) {
        $Device->{"Serial"} = $1;
    }
    
    if($Desc=~/Device Model:\s*(.+?)(\Z|\n)/)
    { # ATA
        $Device->{"Device"} = $1;
    }
    elsif($Desc=~/Model Number:\s*(.+?)(\Z|\n)/)
    { # NVMe
        $Device->{"Device"} = $1;
    }
    
    if($Desc=~/Model Family:\s*(.+?)(\Z|\n)/) {
        $Device->{"Family"} = $1;
    }
    
    if($Desc=~/Firmware Version:\s*(.+?)(\Z|\n)/) {
        $Device->{"Firmware"} = $1;
    }
    
    if($Desc=~/LU WWN Device Id:\s*\w\s(\w{6})\s(\w+|\.\.\.)(\Z|\n)/) {
        $Device->{"IEEE_OUI"} = $1;
    }
    elsif($Desc=~/IEEE OUI Identifier:\s*0x(\w+)/) {
        $Device->{"IEEE_OUI"} = $1;
    }
    elsif($Desc=~/IEEE EUI-64:\s*(\w{6})\s(\w+|\.\.\.)(\Z|\n)/) {
        $Device->{"IEEE_OUI"} = $1;
    }
    
    if(not $Device->{"Kind"})
    {
        if($Desc=~/Rotation Rate:.*Solid State Device/
        or $Device->{"Device"}=~/\bSSD/
        or $Device->{"Family"}=~/\bSSD/) {
            $Device->{"Kind"} = "SSD";
        }
        elsif($Desc=~/NVM Commands|NVMe Log/
        or $Device->{"Device"}=~/\bNVMe\b/i)
        {
            $Device->{"Kind"} = "NVMe";
            $Bus = $PCI_DISK_BUS;
        }
        else {
            $Device->{"Kind"} = "HDD";
        }
    }
    
    if($Desc=~/User Capacity:.*\[(.+?)\]/)
    { # ATA
        $Device->{"Capacity"} = $1;
    }
    elsif($Desc=~/Size\/Capacity:.*\[(.+?)\]/)
    { # NVMe
        $Device->{"Capacity"} = $1;
    }
    
    $Device->{"Capacity"}=~s/,/./g;
    $Device->{"Capacity"}=~s/\.0+ //g;
    $Device->{"Capacity"}=~s/\s+//g;
    
    $Device->{"Device"}=~s/\//-/g;
    $Device->{"Device"}=~s/"/-inch/g;
    $Device->{"Device"}=~s/\ASSD\s+//g;
    $Device->{"Device"}=~s/\Am\.2\s+//g;
    $Device->{"Device"}=~s/\s{2,}/ /g;
    $Device->{"Device"}=~s/\.\Z//g;
    
    fixDrive_Pre($Device);
    
    if(not $Device->{"Vendor"})
    { # NVMe
        if($Desc=~/PCI Vendor ID:\s*0x(\w+)/) {
            $Device->{"Vendor"} = nameID(getPciVendor($1));
        }
        elsif($Desc=~/PCI Vendor\/Subsystem ID:\s*0x(\w+)/) {
            $Device->{"Vendor"} = nameID(getPciVendor($1));
        }
        
        if($Device->{"Vendor"}
        and my $Vnd = guessDeviceVendor($Device->{"Vendor"}))
        {
            $Device->{"Vendor"} = $Vnd;
            $Device->{"Device"} = duplVendor($Vnd, $Device->{"Device"});
        }
    }
    
    if(not $Opt{"IdentifyDrive"})
    {
        if(not $Device->{"Vendor"} or not $Device->{"Device"}) {
            return;
        }
    }
    
    $Device->{"Device"} = duplVendor($Device->{"Vendor"}, $Device->{"Device"});
    
    $Device->{"Device"}=~s/[\[\]]/ /g;
    $Device->{"Device"}=~s/\A //g;
    $Device->{"Device"}=~s/ \Z//g;
    
    fixDrive($Device);
    
    $Device->{"Model"} = $Device->{"Device"};
    
    my $ID = devID(nameID($Device->{"Vendor"}));
    $ID = devID($ID, devSuffix($Device));
    
    $Device->{"Device"} .= addCapacity($Device->{"Device"}, $Device->{"Capacity"});
    foreach (keys(%{$Device}))
    {
        if(not $Device->{$_}) {
            delete($Device->{$_});
        }
    }
    
    my $HWId = $Bus.":".fmtID($ID);
    $HW{$HWId} = $Device;
    $HDD{$Dev} = $HWId;
    
    $DeviceNumByID{$HWId} = $DriveNumByFile{$Dev};
    
    countDevice($HWId);
    
    return $HWId;
}

sub fixDrive_Pre($)
{
    my $Device = $_[0];
    
    if(not $Device->{"Vendor"}
    and not $Device->{"Family"}
    and $Device->{"Device"})
    {
        if($Device->{"Device"}=~/\ASATA (32GB |)SSD\Z/) {
            $Device->{"Vendor"} = $DEFAULT_VENDOR;
        }
        elsif($Device->{"Device"}=~/\AForce MP/) {
            $Device->{"Vendor"} = "Corsair";
        }
    }
    
    if($Device->{"Device"} eq "ASUS-PHISON SSD") {
        $Device->{"Device"} = "ASUS PHISON SSD";
    }
    elsif($Device->{"Device"} eq "kingpower1108 SSD") {
        $Device->{"Device"} = "KingPower 1108 SSD";
    }
    
    if(not $Device->{"Vendor"} and $Device->{"Device"})
    {
        if(my $Vnd = guessDeviceVendor($Device->{"Device"}))
        {
            $Device->{"Vendor"} = $Vnd;
            $Device->{"Device"} = duplVendor($Vnd, $Device->{"Device"});
        }
        
        my $FamilyVnd = undef;
        
        if($Device->{"Family"}=~/\A([^ ]+)\s+/) {
            $FamilyVnd = $1;
        }
        
        if($FamilyVnd)
        {
            if($Device->{"Device"}=~s/\A\Q$FamilyVnd\E([\s_\-]+|\Z)//i) {
                $Device->{"Vendor"} = $FamilyVnd;
            }
        }
        
        if(not $Device->{"Vendor"})
        {
            if($Device->{"Device"} eq "PLUS 480GB") {
                $Device->{"Vendor"} = "SanDisk";
            }
        }
        
        if(not $Device->{"Vendor"})
        {
            if(my $VndDr = guessDriveVendor($Device->{"Device"}))
            {
                $Device->{"Vendor"} = $VndDr;
                $Device->{"Device"} = duplVendor($Device->{"Vendor"}, $Device->{"Device"});
            }
        }
        
        if(not $Device->{"Vendor"})
        {
            if($Device->{"Device"}=~s/\A([A-Z]{5,})[\s_\-]+//i)
            {
                my $Vnd = $1;
                if(not nonVendor($Vnd)) {
                    $Device->{"Vendor"} = $Vnd;
                }
            }
        }
        
        if(not $Device->{"Vendor"} and $FamilyVnd) {
            $Device->{"Vendor"} = $FamilyVnd;
        }
    }
    
    if(not $Device->{"Vendor"} or grep {$Device->{"Vendor"} eq $_} ("Generic", "ZALMAN"))
    {
        if(my $VndS = guessSerialVendor($Device->{"Serial"})) {
            $Device->{"Vendor"} = $VndS;
        }
        elsif(my $VndF = guessFirmwareVendor($Device->{"Firmware"})) {
            $Device->{"Vendor"} = $VndF;
        }
    }
    
    if($Device->{"Kind"} ne "NVMe"
    and grep {uc($Device->{"Vendor"}) eq $_} ("OCZ", "CORSAIR", "CRUCIAL"))
    { # kind of several models is not detected properly by smartmontools
      # or smartmontools output is not collected
        $Device->{"Kind"} = "SSD";
    }
    
    if($Device->{"Kind"} eq "HDD")
    {
        if(uc($Device->{"Vendor"}) eq "KINGSTON" and $Device->{"Device"}=~/\ASV300/) {
            $Device->{"Kind"} = "SSD";
        }
        elsif(uc($Device->{"Vendor"}) eq "TRANSCEND" and $Device->{"Device"}=~/\ATS4/) {
            $Device->{"Kind"} = "SSD";
        }
        elsif(uc($Device->{"Vendor"}) eq "TOSHIBA" and $Device->{"Device"}=~/\ATHNS/) {
            $Device->{"Kind"} = "SSD";
        }
    }
}

sub nonVendor($) {
    return grep { $_[0] eq $_ } ("SSD", "mSata", "SATAIII", "PCIe");
}

sub fixDrive($)
{
    my $Device = $_[0];
    
    if($Device->{"Vendor"}=~/\A(WD|ST)\d+/)
    { # model name instead of vendor name
        $Device->{"Device"} = $Device->{"Vendor"}." ".$Device->{"Device"};
        
        if(defined $DiskVendor{$1}) {
            $Device->{"Vendor"} = $DiskVendor{$1};
        }
    }
    
    if(not $Device->{"Device"})
    { # no model name
        $Device->{"Device"} = $Device->{"Capacity"};
        $Device->{"Device"}=~s/\.\d+//g;
        
        if($Device->{"Kind"} eq "SSD") {
            $Device->{"Device"} = "SSD ".$Device->{"Device"};
        }
    }
    
    if($Device->{"Kind"} eq "SSD")
    {
        if($Device->{"Device"} eq "DISK") {
            $Device->{"Device"} = "SSD DISK";
        }
        elsif($Device->{"Device"}=~/\A(\d{3})\Z/) {
            $Device->{"Device"} = "SSD $1";
        }
        elsif($Device->{"Device"}=~/\A\d+\s*(GB|TB|G|T)\Z/) {
            $Device->{"Device"} = "SSD ".$Device->{"Device"};
        }
    }
    
    if($Device->{"Kind"} eq "SSD"
    or $Device->{"Kind"} eq "NVMe")
    {
        if(grep {$Device->{"Device"} eq $_} ("SSD", "SATA SSD", "SATA-III SSD", "Solid State Disk",
        "SSD Sata III", "DISK", "SSD DISK") or grep {uc($Device->{"Vendor"}) eq $_} ("OCZ", "ADATA", "A-DATA", "PATRIOT", "SPCC", "SAMSUNG", "CORSAIR", "HYPERDISK", "TOSHIBA"))
        {
            if($Device->{"Capacity"}=~/\A([\d\.]+)/)
            {
                my ($S1, $S2) = (int($1), ceilNum($1));
                if($S1 % 2 != 0) {
                    $S1 += 1;
                }
                if($S2 % 2 != 0) {
                    $S2 += 1;
                }
                my $S3 = $S2 + 2;
                if($Device->{"Device"}!~/[^1-9]+($S1|$S2|$S3|16|24|32|120|128|256|512|1024|2048)([^\d]+|\Z)/) { # TODO: fix expression (add '\A')
                    $Device->{"Device"} .= addCapacity($Device->{"Device"}, $Device->{"Capacity"});
                }
            }
        }
    }
    
    if($Device->{"Device"} eq "ZALMAN") {
        $Device->{"Device"} .= addCapacity($Device->{"Device"}, $Device->{"Capacity"});
    }
    
    if(not $Device->{"Vendor"})
    {
        if(grep {$Device->{"Device"} eq $_} ("T60", "T120")
        or $Device->{"Device"}=~/\A\d+(G|GB|T|TB) SSD\Z/ or $Device->{"Device"}=~/\ASSD\s*\d+(G|GB|T|TB)\Z/)
        { # SSD32G, SSD60G
          # 64GB SSD
            $Device->{"Vendor"} = $DEFAULT_VENDOR;
        }
    }
    
    if(not $Device->{"Vendor"} or $Device->{"Vendor"} eq $DEFAULT_VENDOR)
    {
        if(my $Oui = $Device->{"IEEE_OUI"})
        {
            if(defined $IeeeOui{$Oui}) {
                $Device->{"Vendor"} = $IeeeOui{$Oui};
            }
        }
    }
}

sub isUnknownRam($)
{
    my $Vendor = $_[0];
    
    if($Vendor=~/(Mfg |Manufacturer|A1_AssetTagNum)/) {
        return 1;
    }
    
    if($Vendor=~/\A(0x|)(0+|F+)\Z/) {
        return 1;
    }
    
    if(grep {$Vendor eq $_} ("8313", "7F7F", "ADCD", "M0", "M1", "K", "K1", "U", "6", "G  u", "Unknown")) {
        return 1;
    }
    
    return 0;
}

sub guessRamVendor($)
{
    my $Name = $_[0];
    
    if($Name=~/\A99[A-Z\d]{5}\-\d{3}\.[A-Z\d]{4,}\Z/) {
        return "Kingston";
    }
    
    foreach my $Len (reverse(2 .. 8))
    {
        my $Prefix = substr($Name, 0, $Len);
        if(defined $RamVendor{$Prefix}) {
            return $RamVendor{$Prefix};
        }
    }
    
    return undef;
}

sub guessDriveVendor($)
{
    my $Name = $_[0];
    
    foreach my $Len (6, 5, 4, 3)
    {
        if($Name=~/\A([A-Z\d\-\_]{$Len})[A-Z\d\-]+/
        and defined $DiskVendor{$1}) {
            return $DiskVendor{$1};
        }
    }
    
    if($Name=~/\A([A-Z]{2})[A-Z\d\-]+/
    and defined $DiskVendor{$1}) {
        return $DiskVendor{$1};
    }
    
    foreach my $Len (3, 2)
    {
        if($Name=~/\A[A-Z\d]{2,}\-([A-Z]{$Len})[A-Z\d]+/
        and defined $DiskVendor{$1})
        { # C400-MTFDDAT064MAM
          # M4-CT256M4SSD2
            return $DiskVendor{$1};
        }
    }
    
    foreach my $P (sort {$b cmp $a} keys(%DiskVendor))
    {
        if(length($P)>=4)
        {
            if($Name=~/\A$P/) {
                return $DiskVendor{$P};
            }
        }
    }
    
    if($Name=~/\A(MT|MSH|P3|P3D|T|PA25)\-(60|64|120|128|240|256|512|1TB|2TB)\Z/
    or grep { $Name eq $_ } ("V-32", "NT-256", "NT-512", "Q-360"))
    { # MT-64 MSH-256 P3-128 P3D-240 P3-2TB T-60 V-32 PA25-128
        return "KingSpec";
    }
    
    if($Name=~s/\A([a-z]{3,})[\-\_ ]//i)
    { # Crucial_CT240M500SSD3
      # OCZ-VERTEX
        my $Vnd = $1;
        if(not nonVendor($Vnd)) {
            return $Vnd;
        }
    }

    return;
}

sub guessSerialVendor($)
{
    my $Serial = $_[0];
    
    if(not $Serial) {
        return;
    }
    
    if($Serial=~/\A([A-Z]+)\-/)
    {
        if(defined $SerialVendor{$1}) {
            return $SerialVendor{$1};
        }
    }
    elsif($Serial=~/\A([A-Z]{3})/)
    {
        if(defined $SerialVendor{$1}) {
            return $SerialVendor{$1};
        }
    }

    return;
}

sub guessFirmwareVendor($)
{
    my $Firmware = $_[0];
    
    if(not $Firmware) {
        return;
    }
    
    if($Firmware=~/\A(\w{4})/)
    {
        if(defined $FirmwareVendor{$1}) {
            return $FirmwareVendor{$1};
        }
    }

    return;
}

sub guessDeviceVendor($)
{
    my $Device = $_[0];
    
    if($Device=~s/(\A|\s)(WDC|Western Digital|Seagate|Samsung Electronics|SAMSUNG|Hitachi|TOSHIBA|Maxtor|SanDisk|Kingston|ADATA|Lite-On|OCZ|Smartbuy|SK hynix|GOODRAM|LDLC|A\-DATA|KingFast|LDLC|INTENSO|ExcelStor Technology|i-FlashDisk|e2e4|Anobit|SandForce)([\s_\-\[]|\Z)//i)
    { # drives
        return $2;
    }
    
    if($Device=~/(\A|\s)(HP|Hewlett\-Packard|Epson|Kyocera|Brother|Samsung|Canon|Xerox)(\s|\Z)/i)
    { # printers
        return $2;
    }

    return;
}

sub computeInch($)
{
    my $Info = $_[0];
    
    my ($W, $H) = ();
    if($Info=~/(\A|\s)(\d+)x(\d+)mm(\s|\Z)/) {
        ($W, $H) = ($2, $3);
    }
    elsif($Info=~/(\A|\s)([\d\.]+)x([\d\.]+)cm(\s|\Z)/) {
        ($W, $H) = (10*$2, 10*$3);
    }
    
    if($W and $H) {
        return sprintf("%.1f", sqrt($W*$W + $H*$H)/25.4);
    }

    return;
}

sub getXRes($)
{
    if($_[0]=~/\A(\d+)/) {
        return $1;
    }

    return;
}

sub duplVendor($$)
{
    my ($Vendor, $Device) = @_;
    
    if($Vendor)
    { # do not duplicate vendor name
        if(not $Device=~s/\A\Q$Vendor\E([\s\-\_\[\.]+|\Z)//gi
        and not $Device=~s/\s+\Q$Vendor\E\s+/ /gi
        and not $Device=~s/\s+\Q$Vendor\E\Z//gi)
        {
            if(my $ShortVendor = nameID($Vendor))
            {
                if($ShortVendor ne $Vendor)
                {
                    $Device=~s/\A\Q$ShortVendor\E[\s\-\_\[\.]+//gi;
                    $Device=~s/\s+\Q$ShortVendor\E\s+/ /gi;
                    $Device=~s/\s+\Q$ShortVendor\E\Z//gi;
                }
            }
        }
    }
    
    return $Device;
}

sub roundToNearest($)
{
    my $Num = $_[0];
    
    my $Delta = $Num - int($Num);
    
    if($Delta*10>5) {
        return int($Num)+1;
    }
    
    return int($Num);
}

sub cleanValues($)
{
    my $Hash = $_[0];
    foreach my $Key (keys(%{$Hash}))
    {
        if(my $Val = $Hash->{$Key})
        {
            if(emptyVal($Val)) {
                delete($Hash->{$Key});
            }
        }
    }
}

sub emptyVal($)
{
    my $Val = $_[0];
    
    if($Val=~/\A[\[\(]*(not specified|not available|out of spec|not defined|No Device Manufacturer|No Device Part Number|invalid|error|unknown|undefined|unknow|uknown|empty|n\/a|none|default string)[\)\]]*\Z/i
    or $Val=~/(\A|\b|\d)(to be filled|unclassified device|not defined|bad index)(\b|\Z)/i
    or $Val=~/\A(vendor|device|unknown vendor|customer|model|_|unde|null|Unknown \(0\))\Z/i) {
        return 1;
    }
    
    return 0;
}

sub devSuffix($)
{
    my $Device = $_[0];
    
    my $Suffix = $Device->{"Device"};
    
    if($Device->{"Type"} eq "cpu")
    {
        if($Device->{"Vendor"} eq "Intel")
        { # short suffix
            my @Parts = ();
            
            if($Device->{"Device"}=~/ CPU /)
            {
                if($Device->{"Device"}=~/\A(.+?)\s+CPU/) {
                    push(@Parts, $1);
                }
                
                if($Device->{"Device"}=~/ CPU\s+(.+?)\s*\@/) {
                    push(@Parts, $1);
                }
            }
            elsif($Device->{"Device"}=~/ processor /)
            {
                if($Device->{"Device"}=~/\A(.+?)\s+processor/i) {
                    push(@Parts, $1);
                }
            }
            
            $Suffix = join("-", @Parts);
        }
        elsif($Device->{"Vendor"} eq "AMD") {
            $Suffix=~s/X2 Dual Core Processor/X2/;
        }
        elsif($Device->{"Vendor"} eq "ARM")
        {
            if($Device->{"Device"}=~/(.+)\s+Processor/) {
                $Suffix = $1;
            }
        }
    }
    elsif($Device->{"Type"} eq "memory"
    or $Device->{"Type"} eq "disk"
    or $Device->{"Type"} eq "battery")
    {
        if($Device->{"Serial"}) {
            $Suffix .= "-serial-".$Device->{"Serial"};
        }
    }
    
    return $Suffix;
}

sub fmtID($)
{
    my $ID = $_[0];
    
    $ID=~s/[\W]+\Z//g;
    $ID=~s/[\W\_]+/-/g;
    
    $ID=~s/\A[\-]+//g;
    $ID=~s/[\-]+\Z//g;
    
    return $ID;
}

sub nameID(@)
{
    my $Name = shift(@_);
    my $Type = undef;
    if(@_) {
        $Type = shift(@_);
    }
    
    if(not $Type or $Type ne "memory")
    {
        $Name=~s/\s*\([^()]*\)//g;
        $Name=~s/\s*\[[^\[\]]*\]//g;
    }
    
    while ($Name=~s/\s*(\,\s*|\s+)(Inc|Ltda|Ltd|Co|GmbH|Corp|Pte|LLC|Sdn|Bhd|BV|AG|RSS|PLC|s\.r\.l\.|srl|S\.P\.A\.|S\.p\.A\.|B\.V\.|S\.A\.)(\.|\Z)//ig) {}
    $Name=~s/,?\s+[a-z]{2,4}\.//ig;
    $Name=~s/,(.+)\Z//ig;
    
    while ($Name=~s/\s+(Corporation|Computer|Computers|Electric|Company|Electronics|Electronic|Elektronik|Technologies|Technology|Technolog)\Z//ig) {}
    
    $Name=~s/[\.\,]/ /g;
    $Name=~s/\s*\Z//g;
    $Name=~s/\A\s*//g;
    
    return $Name;
}

sub fixVendor($)
{
    my $Vendor = $_[0];
    $Vendor=~s/\s+\Z//g;
    return $Vendor;
}

sub fixModel($$$)
{
    my ($Vendor, $Model, $Version) = @_;
    
    $Model=~s/\A\-//;
    $Model=~s/\A\[(.+)\]\-\Z/$1/; # IBM
    
    $Model=~s/\A\Q$Vendor\E\s+//i;
    
    if($Vendor eq "Hewlett-Packard")
    {
        $Model=~s/\AHP\s+//g;
        $Model=~s/\s+Notebook PC\s*\Z//gi;
        $Model=~s/PAVILION/Pavilion/gi;
        $Model=~s/Envy/ENVY/gi;
    }
    elsif(uc($Vendor) eq "TOSHIBA") {
        $Model=~s/SATELLITE/Satellite/g;
    }
    elsif($Vendor=~/Fujitsu/)
    {
        $Model=~s/Amilo/AMILO/g;
        $Model=~s/LifeBook/LIFEBOOK/g;
        $Model=~s/Stylistic/STYLISTIC/g;
    }
    elsif($Vendor=~/\ADell(\s|\Z)/i)
    {
        $Model=~s/\A(MM061|MXC061|MP061|ME051)\Z/Inspiron $1/g;
        $Model=~s/\A(MXC062)\Z/XPS $1/g;
        $Model=~s/\ADell System //g; # Dell System Vostro 3450 by Dell Inc.
        $Model=~s/\ADell //g; # Dell 500 by Dell Inc.
    }
    elsif($Vendor eq "Micro-Star International")
    {
        $Model=~s/\AMSI\s+//gi;
        $Model=~s/\ANotebook\s+//gi;
    }
    elsif(uc($Vendor) eq "LENOVO")
    {
        if($Model=~/\A\s*INVALID\s*\Z/) {
            $Model = "";
        }
        
        if($Version=~/\A\s*INVALID\s*\Z/) {
            $Version = "";
        }
        
        if($Version=~/[A-Z]/i)
        {
            $Version=~s/\ALenovo-?\s*//i;
            
            if($Version and $Version!~/Rev \d/i)
            {
                while($Model=~s/\A\Q$Version\E\s+//i) {}

                if($Model!~/\Q$Version\E/i) {
                    $Model = $Version." ".$Model;
                }
            }
        }
        
        $Model=~s/Ideapad/IdeaPad/gi;
        $Model=~s/ideacentre/IdeaCentre/gi;
        $Model=~s/\AProduct\s+Lenovo\s+//i;
        $Model=~s/\AProduct\s+//i;
        $Model=~s/\ALenovo\s+//i;
    }
    elsif($Version=~/ThinkPad/i and $Model!~/ThinkPad/i) {
        $Model = $Version." ".$Model;
    }
    
    return $Model;
}

sub listDir($)
{
    my $Dir = $_[0];
    
    if(not $Dir) {
        return ();
    }
    
    opendir(my $DH, $Dir);
    
    if(not $DH) {
        return ();
    }
    
    my @Contents = grep { $_ ne "." && $_ ne ".." } readdir($DH);
    closedir($DH);
    
    @Contents = sort @Contents;
    
    return @Contents;
}

sub probeSys()
{
    my ($Distr, $Rel) = probeDistr();
    
    $Sys{"System"} = $Distr;
    $Sys{"Systemrel"} = $Rel;
    
    if(not $Sys{"System"})
    {
        printMsg("ERROR", "failed to detect Linux distribution");
        if($Opt{"Snap"})
        {
            warnSnapInterfaces();
            exitStatus(1);
        }
    }
    
    if(checkCmd("uname"))
    {
        $Sys{"Arch"} = runCmd("uname -m");
        $Sys{"Kernel"} = runCmd("uname -r");
    }
    else
    {
        require POSIX;
        $Sys{"Arch"} = (POSIX::uname())[4];
        $Sys{"Kernel"} = (POSIX::uname())[2];
    }
    
    if($Sys{"Arch"}=~/unknown/i)
    {
        require Config;
        $Sys{"Arch"} = $Config::Config{"archname"};
        $Sys{"Arch"}=~s/\-linux.*//;
    }
    
    if($Opt{"PC_Name"}) {
        $Sys{"Name"} = $Opt{"PC_Name"};
    }
    
    $Sys{"Probe_ver"} = $TOOL_VERSION;
    
    foreach (keys(%Sys)) {
        chomp($Sys{$_});
    }
}

sub probeDmi()
{
    listProbe("logs", "dmi_id");
    
    my $Dmi = "";
    foreach my $File ("sys_vendor", "product_name", "product_version", "chassis_type", "board_vendor", "board_name", "board_version", "bios_vendor", "bios_version", "bios_date")
    {
        my $Value = readFile("/sys/class/dmi/id/".$File);
        
        if(not $Value) {
            next;
        }
        
        $Value=~s/\s+\Z//g;
        $Value = fmtVal($Value);
        
        if($File eq "sys_vendor")
        {
            if(not emptyProduct($Value)) {
                $Sys{"Vendor"} = $Value;
            }
        }
        elsif($File eq "product_name")
        {
            if(not emptyProduct($Value)) {
                $Sys{"Model"} = $Value;
            }
        }
        elsif($File eq "product_version")
        {
            if(not emptyProduct($Value)) {
                $Sys{"Version"} = $Value;
            }
        }
        elsif($File eq "chassis_type")
        {
            if(my $CType = getChassisType($ChassisType{$Value})) {
                $Sys{"Type"} = $CType;
            }
        }
        
        if($Value ne "" and $Value=~/[A-Z0-9]/i) {
            $Dmi .= $File.": ".$Value."\n";
        }
    }
    
    if($Opt{"HWLogs"}) {
        writeLog($LOG_DIR."/dmi_id", $Dmi);
    }
    
    $Sys{"Vendor"} = fixVendor($Sys{"Vendor"});
    $Sys{"Model"} = fixModel($Sys{"Vendor"}, $Sys{"Model"}, $Sys{"Version"});
}

sub emptyProduct($)
{
    my $Val = $_[0];
    
    if(not $Val or $Val=~/\b(System manufacturer|System Manufacter|stem manufacturer|Name|Version|to be filled|empty|Not Specified|Default string|board version|Unknow)\b/i
    or $Val=~/\A([_0O\-\.\s]+|NA|N\/A|\-O)\Z/i or emptyVal($Val)) {
        return 1;
    }
    
    return 0;
}

sub getChassisType($)
{
    my $CType = lc($_[0]);
    $CType=~s/ chassis//i;
    
    if($CType!~/unknown|other/) {
        return $CType;
    }

    return;
}

sub fixProduct()
{
    foreach my $Attr ("Vendor", "Version", "Model")
    {
        if(emptyProduct($Sys{$Attr})) {
            $Sys{$Attr} = "";
        }
    }
}

sub fixFFByCPU($)
{
    my $CPU = $_[0];
    if($Sys{"Type"}!~/$DESKTOP_TYPE/)
    {
        if($CPU=~/Celeron CPU E\d+|Pentium (CPU G\d+|D CPU|Dual-Core CPU E\d+) |Core 2 CPU \d+ |Core 2 Duo CPU E\d+|Core 2 Quad CPU Q\d+|Core i\d CPU \d+ |Core i\d-\d+ CPU|CPU Q(9400|8200)|Athlon 64 X2 Dual Core Processor \d+|Athlon X4 \d+|Athlon 64 Processor \d+\+|Phenom II X[24] B?\d+|FX-\d+ Six-Core|A10\-\d+K|Xeon CPU \d+ /) {
            $Sys{"Type"} = "desktop";
        }
    }
    if($Sys{"Type"}!~/$SERVER_TYPE/)
    {
        if($CPU=~/Opteron X3216|Xeon Gold/) {
            $Sys{"Type"} = "server";
        }
    }
    if($Sys{"Type"}!~/$MOBILE_TYPE/)
    {
        if($CPU=~/Athlon Neo X2 .* L3/) {
            $Sys{"Type"} = "notebook";
        }
    }
}

sub fixFFByGPU($)
{
    my $GPU = $_[0];
    if($Sys{"Type"}!~/$DESKTOP_TYPE/)
    {
        if($GPU=~/\A((NV|G)\d+ \[GeForce|RV\d+ \[Radeon |GeForce4 MX|RV635 PRO|Radeon HD 3870)/) {
            $Sys{"Type"} = "desktop";
        }
    }
}

sub fixFFByCDRom($)
{
    my $CDRom = $_[0];
    if($Sys{"Type"}!~/$DESKTOP_TYPE/)
    {
        if($CDRom=~/(DVR-118L|DDU1615|SH-222AB|DVR-111D|GSA-H10N|CRX230EE)/) {
            $Sys{"Type"} = "desktop";
        }
    }
}

sub fixFFByTouchpad($)
{
    my $Id = $_[0];
    if($Sys{"Type"}!~/$MOBILE_TYPE/)
    {
        if($Id=~/ps\/2/) {
            $Sys{"Type"} = "notebook";
        }
    }
}

sub fixFFByMonitor($)
{
    my $Mon = $_[0];
    if($Sys{"Type"} ne "all in one")
    {
        if($Mon=~/(AIO PC)/) {
            $Sys{"Type"} = "all in one";
        }
    }
    
    if($Sys{"Type"}!~/$MOBILE_TYPE/)
    {
        if($Mon=~/LGD02E9|SEC3445/) {
            $Sys{"Type"} = "notebook";
        }
    }
}

sub fixFFByBoard($)
{
    my $Board = $_[0];
    if($Sys{"Type"}!~/$DESKTOP_TYPE/)
    {
        if($Board=~/\b(D510MO|GA-K8NMF-9|DG965RY|DG33BU|D946GZIS|N3150ND3V|D865GSA|DP55WG|H61MXT1|D875PBZ|F2A55|Z68XP-UD3|Z77A-GD65|M4A79T|775Dual-880Pro|P4Dual-915GL|P4i65GV|D5400XS|D201GLY|MicroServer|IPPSB-DB|MS-AA53|C2016-BSWI-D2|N3160TN|ZBOX-CI323NANO|D915PBL|Aptio CRB|EIRD-SAM)\b/) {
            $Sys{"Type"} = "desktop";
        }
    }
    if($Sys{"Type"}!~/$SERVER_TYPE/)
    {
        if($Board=~/X10DRT-P|X10DRW-i/) {
            $Sys{"Type"} = "server";
        }
    }
    if($Sys{"Type"}!~/$MOBILE_TYPE/)
    {
        if($Board=~/\b(W7430|Poyang)\b/) {
            $Sys{"Type"} = "notebook";
        }
    }
}

sub fixFFByModel($$)
{
    my ($V, $M) = @_;
    
    if($Sys{"Type"}!~/$MOBILE_TYPE/)
    {
        if($M=~/(Aspire (7720|5670)|EasyNote)/
        or ($V=~/Samsung/i and $M=~/R50\/R51/)
        or ($V=~/Clevo/i and $M=~/M740TU/)
        or ($V=~/Toshiba/i and $M=~/Satellite L300/)) {
            $Sys{"Type"} = "notebook";
        }
    }
    
    if($Sys{"Type"}=~/$MOBILE_TYPE/ and $Sys{"Type"} ne "convertible")
    {
        if($M=~/convertible/i) {
            $Sys{"Type"} = "convertible";
        }
    }
}

sub fixChassis()
{
    my (%Bios, %Board) = ();
    foreach my $L (split(/\n/, readFile($FixProbe_Logs."/dmi_id")))
    {
        if($L=~/\A(\w+?):\s+(.+?)\Z/)
        {
            my ($File, $Value) = ($1, $2);
            
            $Value = fmtVal($Value);
            
            if($File eq "chassis_type")
            {
                if(my $CType = getChassisType($ChassisType{$Value})) {
                    $Sys{"Type"} = $CType;
                }
            }
            elsif($File eq "sys_vendor")
            {
                if(not emptyProduct($Value)) {
                    $Sys{"Vendor"} = $Value;
                }
            }
            elsif($File eq "product_name")
            {
                if(not emptyProduct($Value)) {
                    $Sys{"Model"} = $Value;
                }
            }
            elsif($File eq "product_version")
            {
                if(not emptyProduct($Value)) {
                    $Sys{"Version"} = $Value;
                }
            }
            elsif($File eq "bios_vendor") {
                $Bios{"Vendor"} = fmtVal($Value);
            }
            elsif($File eq "bios_version") {
                $Bios{"Version"} = $Value;
            }
            elsif($File eq "bios_date") {
                $Bios{"Release Date"} = $Value;
            }
            elsif($File eq "board_vendor") {
                $Board{"Vendor"} = fmtVal($Value);
            }
            elsif($File eq "board_name") {
                $Board{"Device"} = fmtVal($Value);
            }
            elsif($File eq "board_version") {
                $Board{"Version"} = $Value;
            }
        }
    }
    
    detectBIOS(\%Bios);
    $Board_ID = detectBoard(\%Board);
    
    if($Sys{"Type"} eq "tablet")
    {
        if($Sys{"Model"}=~/Mini PC/i)
        { # tiny desktops
            $Sys{"Type"} = "desktop";
        }
    }
    
    if($Sys{"Type"} ne "tablet")
    { # TODO: check this by analysis of
      # particular devices on board
        if($Sys{"Vendor"}=~/Microsoft/
        and $Sys{"Model"}=~/Surface/) {
            $Sys{"Type"} = "tablet";
        }
    }
    
    if(not $Sys{"Type"} or $Sys{"Type"} eq "soc")
    {
        if($Sys{"Kernel"}=~/\-(sunxi|raspi2)\Z/i
        or $Sys{"Vendor"}=~/raspberry/i) {
            $Sys{"Type"} = "system on chip";
        }
        
        if($Sys{"Kernel"}=~/\-(tegra)\Z/i)
        {
            $Sys{"Type"} = "system on chip";
            $Sys{"Vendor"} = "NVIDIA";
            $Sys{"Model"} = "Tegra";
        }
    }
}

sub ipAddr2ifConfig($)
{
    my $IPaddr = $_[0];
    
    my $IFConfig = "";
    
    foreach my $Line (split(/\n/, $IPaddr))
    {
        if($Line=~s/\A\d+:\s+//) {
            $IFConfig .= "\n".$Line."\n";
        }
        else {
            $IFConfig .= $Line."\n";
        }
    }
    
    return $IFConfig;
}

sub probeHWaddr()
{
    my $IFConfig = undef;
    
    if($Opt{"FixProbe"})
    {
        $IFConfig = readFile($FixProbe_Logs."/ifconfig");
        
        if(not $IFConfig)
        {
            if(my $IPaddr = readFile($FixProbe_Logs."/ip_addr")) {
                $IFConfig = ipAddr2ifConfig($IPaddr);
            }
        }
        
        if($IFConfig)
        { # fix HWaddr
            my $EthtoolP = readFile($FixProbe_Logs."/ethtool_p");
            
            if($EthtoolP)
            {
                foreach my $E (split(/\n/, $EthtoolP))
                {
                    if($E=~/(.+)\=\>(.+)/) {
                        $PermanentAddr{$1} = $2;
                    }
                }
            }
            
            my $UAddr = $Sys{"HWaddr"};
            $UAddr=~s/\-/:/g;
            
            if($EthtoolP or $IFConfig=~/\Q$UAddr\E/i)
            {
                if(my $NewAddr = detectHWaddr($IFConfig)) {
                    $Sys{"HWaddr"} = $NewAddr;
                }
            }
        }
    }
    else
    {
        if(checkCmd("ifconfig"))
        {
            listProbe("logs", "ifconfig");
            $IFConfig = runCmd("ifconfig -a 2>&1");
            $IFConfig = hideIPs($IFConfig);
            $IFConfig = encryptMACs($IFConfig);
            
            if($Opt{"HWLogs"}) {
                writeLog($LOG_DIR."/ifconfig", $IFConfig);
            }
        }
        elsif(checkCmd("ip"))
        {
            listProbe("logs", "ip_addr");
            if(my $IPaddr = runCmd("ip addr 2>&1"))
            {
                $IPaddr = hideIPs($IPaddr);
                $IPaddr = encryptMACs($IPaddr);
                $IFConfig = ipAddr2ifConfig($IPaddr);
                
                if($Opt{"HWLogs"}) {
                    writeLog($LOG_DIR."/ip_addr", $IPaddr);
                }
            }
        }
        elsif(checkModule("IO/Socket.pm")
        and checkModule("IO/Interface.pm"))
        {
            require IO::Socket;
            require IO::Interface;
            
            my $Socket = IO::Socket::INET->new(Proto => "udp");
            my @Ifs = ();
            my %Addrs = ();
            foreach my $If ($Socket->if_list)
            {
                if(my $Mac = $Socket->if_hwaddr($If))
                {
                    $Mac = lc($Mac);
                    $Mac=~s/:/-/g;
                    $Mac = lc(clientHash(lc($Mac)));
                    
                    push(@Ifs, $If); # save order
                    $Addrs{$If} = $Mac;
                }
            }
            
            $Sys{"HWaddr"} = selectHWAddr(\@Ifs, \%Addrs);
        }
        else
        {
            printMsg("ERROR", "can't find 'ifconfig' or 'ip'");
            exitStatus(1);
        }
        
        if($IFConfig)
        {
            $Sys{"HWaddr"} = detectHWaddr($IFConfig);
            
            if($Opt{"HWLogs"})
            {
                my $EthtoolP = "";
                foreach my $E (sort keys(%PermanentAddr)) {
                    $EthtoolP .= $E."=>".$PermanentAddr{$E}."\n";
                }
                if($EthtoolP) {
                    writeLog($LOG_DIR."/ethtool_p", $EthtoolP);
                }
            }
        }
        
        if(not $Sys{"HWaddr"})
        {
            printMsg("ERROR", "failed to detect hwid");
            
            if($Opt{"Snap"}) {
                warnSnapInterfaces();
            }
            
            exitStatus(1);
        }
    }
    
    if($IFConfig)
    {
        foreach my $I (split(/\n\n/, $IFConfig))
        {
            if($I=~/\A([^:\s]+):?\s/)
            {
                my $F = $1;
                
                if(($I=~/packets\s*:?\s*(\d+)/ and $1) or ($I=~/valid_lft\s+(\d+)/ and $1)) {
                    $UsedNetworkDev{$F} = 1;
                }
            }
        }
    }
}

sub warnSnapInterfaces()
{
    print STDERR "\nERROR: Make sure required Snap interfaces are connected:\n\n";
    print STDERR "    for i in hardware-observe system-observe block-devices log-observe upower-observe physical-memory-observe network-observe raw-usb mount-observe opengl;do sudo snap connect hw-probe:\$i :\$i; done\n";
    
    # auto-connected:
    #
    #   hardware-observe
    #   mount-observe
    #   network-observe
    #   system-observe
    #   upower-observe
    #   log-observe
    #   opengl
}

sub countStr($$)
{
    my ($Str, $Target) = @_;
    
    my $Count = 0;
    while($Str=~s/$Target//) {
        $Count += 1;
    }
    return $Count;
}

sub detectHWaddr($)
{
    my $IFConfig = $_[0];
    
    my @Devs = ();
    my %Addrs = ();
    
    foreach my $Block (split(/[\n]\s*[\n]+/, $IFConfig))
    {
        my $Addr = undef;
        
        if($Block=~/\Adocker/) {
            next;
        }
        
        if($Block=~/ether\s+([^\s]+)/)
        { # Fresh
            $Addr = lc($1);
        }
        elsif($Block=~/HWaddr\s+([^\s]+)/)
        { # Marathon
            $Addr = lc($1);
        }
        
        if(not $Addr) {
            next;
        }
        
        if(index($Addr, ":")!=-1)
        { # Support for old probes
            $Addr=~s/:/-/g;
        }
        
        my $NetDev = undef;
        
        if($Block=~/\A([^:]+):?\s/) {
            $NetDev = $1;
        }
        else {
            next;
        }
        
        push(@Devs, $NetDev); # save order
        $Addrs{$NetDev} = $Addr;
    }
    
    return selectHWAddr(\@Devs, \%Addrs);
}

sub selectHWAddr($$)
{
    my $Devs = $_[0];
    my $Addrs = $_[1];
    
    my (@Eth, @Wlan, @Other, @Wrong) = ();
    
    foreach my $NetDev (@{$Devs})
    {
        my $Addr = $Addrs->{$NetDev};
        
        if(not $Opt{"FixProbe"})
        {
            if(my $RealMac = getRealHWaddr($NetDev)) {
                $PermanentAddr{$NetDev} = clientHash($RealMac);
            }
        }
        
        if(defined $PermanentAddr{$NetDev}) {
            $Addr = lc($PermanentAddr{$NetDev});
        }
        
        if(grep { uc($Addr) eq $_ } @WrongAddr)
        {
            push(@Wrong, $Addr);
            next;
        }
        
        if($NetDev=~/\Aenp\d+s\d+.*u\d+\Z/i)
        { # enp0s20f0u3, enp0s29u1u5, enp0s20u1, etc.
            push(@Other, $Addr);
        }
        elsif(index($Addr, "-")!=-1
        and (countStr($Addr, "00")>=5 or countStr($Addr, "88")>=5 or countStr($Addr, "ff")>=5))
        { # 00-dd-00-00-00-00, 88-88-88-88-87-88, ...
          # Support for old probes
            push(@Other, $Addr);
        }
        elsif($NetDev=~/\Ae/)
        {
            push(@Eth, $Addr);
        }
        elsif($NetDev=~/\Aw/)
        {
            $WLanInterface{$NetDev} = 1;
            push(@Wlan, $Addr);
        }
        else {
            push(@Other, $Addr);
        }
    }
    
    my $Sel = undef;
    
    if(@Eth) {
        $Sel = $Eth[0];
    }
    elsif(@Wlan) {
        $Sel = $Wlan[0];
    }
    elsif(@Other) {
        $Sel = $Other[0];
    }
    elsif(@Wrong) {
        $Sel = $Wrong[0];
    }
    
    return $Sel;
}

sub getRealHWaddr($)
{
    my $Dev = $_[0];
    
    if(checkCmd("ethtool"))
    {
        my $Info = runCmd("ethtool -P $Dev 2>/dev/null");
        
        if($Info=~/(\w\w:\w\w:\w\w:\w\w:\w\w:\w\w)/)
        {
            my $Mac = lc($1);
            $Mac=~s/:/-/g;
            
            if($Mac ne "00-00-00-00-00-00"
            and $Mac ne "ff-ff-ff-ff-ff-ff") {
                return $Mac;
            }
        }
    }

    return;
}

sub readFileHex($)
{
    my $Path = $_[0];
    local $/ = undef;
    open(FILE, "<", $Path);
    binmode FILE;
    my $Data = <FILE>;
    close FILE;
    return unpack('H*', $Data);
}

sub readFile($)
{
    my $Path = $_[0];
    open(FILE, "<", $Path);
    local $/ = undef;
    my $Content = <FILE>;
    close(FILE);
    return $Content;
}

sub readLine($)
{
    my $Path = $_[0];
    open(FILE, "<", $Path);
    my $Line = <FILE>;
    close(FILE);
    return $Line;
}

sub probeDistr()
{
    my $LSB_Rel = "";
    
    if($Opt{"FixProbe"}) {
        $LSB_Rel = readFile($FixProbe_Logs."/lsb_release");
    }
    else
    {
        if(not $Opt{"Docker"} and not $Opt{"Snap"} and not $Opt{"Flatpak"})
        {
            if(checkCmd("lsb_release"))
            {
                listProbe("logs", "lsb_release");
                $LSB_Rel = runCmd("lsb_release -i -d -r -c 2>/dev/null");
                
                if($Opt{"HWLogs"}) {
                    writeLog($LOG_DIR."/lsb_release", $LSB_Rel);
                }
            }
        }
    }
    
    my $OS_Rel = "";
    
    if($Opt{"FixProbe"}) {
        $OS_Rel = readFile($FixProbe_Logs."/os-release");
    }
    else
    {
        listProbe("logs", "os-release");
        $OS_Rel = readFile("/etc/os-release");
        if($Opt{"Snap"})
        { # Snap strict confinement
            my $OSRelHostFs = "/var/lib/snapd/hostfs/etc/os-release";
            if(-e $OSRelHostFs) {
                $OS_Rel = readFile($OSRelHostFs);
            }
        }
        elsif($Opt{"Flatpak"})
        {
            foreach my $OSRelHost ("/run/host/etc/os-release", "/run/host/usr/lib/os-release",
            "/var/run/host/etc/os-release", "/var/run/host/usr/lib/os-release")
            {
                if(-e $OSRelHost)
                {
                    $OS_Rel = readFile($OSRelHost);
                    last;
                }
            }
        }
        if($Opt{"HWLogs"}) {
            writeLog($LOG_DIR."/os-release", $OS_Rel);
        }
    }
    
    my $Sys_Rel = "";
    
    if($Opt{"FixProbe"}) {
        $Sys_Rel = readFile($FixProbe_Logs."/system-release");
    }
    else
    {
        listProbe("logs", "system-release");
        $Sys_Rel = readFile("/etc/system-release");
        if($Opt{"HWLogs"} and $Sys_Rel) {
            writeLog($LOG_DIR."/system-release", $Sys_Rel);
        }
    }
    
    my ($Name, $Release, $FName) = ();
    
    if($LSB_Rel)
    { # Desktop
        my $Descr = undef;
        if($LSB_Rel=~/ID:\s*(.*)/) {
            $Name = $1;
        }
        
        if(lc($Name) eq "n/a") {
            $Name = "";
        }
        
        if($LSB_Rel=~/Release:\s*(.*)/) {
            $Release = lc($1);
        }
        
        if($Release eq "n/a") {
            $Release = "";
        }
        
        if($Release and $Name) {
            $Release=~s/\A$Name[\s\-]+//i;
        }
        
        if($LSB_Rel=~/NAME:\s*(.*)/) {
            $FName = $1;
        }
        
        if($LSB_Rel=~/Description:\s*(.*)/) {
            $Descr = $1;
        }
        
        if($Name=~/\AROSAEnterpriseServer/i) {
            return ("rels-".$Release, "");
        }
        elsif($Name=~/\AROSAEnterpriseDesktop/i) {
            return ("red-".$Release, "");
        }
        elsif($Name=~/\ARosa\.DX/i)
        {
            if($Descr=~/(Chrome|Nickel|Cobalt)/i) {
                return ("rosa.dx-".lc($1)."-".$Release, "");
            }
        }
        elsif($Descr=~/\AROSA SX/i)
        {
            if($Descr=~/(CHROME|NICKEL|COBALT)/i) {
                return ("rosa.sx-".lc($1)."-".$Release, "");
            }
        }
        elsif($Name=~/\AROSA/i)
        {
            my $Rel = "";
            
            if($Descr=~/ R([\d\-\.]+)/i) {
                $Rel = "rosafresh-r".$1;
            }
            elsif($Descr=~/ Enterprise Desktop X([\d\-\.]+)/i) {
                $Rel = "red-x".$1;
            }
            elsif($OS_Rel=~/Fresh R(\d+) /) {
                $Rel = "rosafresh-r".$1;
            }
            
            return ("rosa-".$Release, $Rel);
        }
        elsif($Name=~/\AOpenMandriva/i) {
            return ("openmandriva-".$Release, "");
        }
        elsif($Name=~/\AopenSUSE Tumbleweed/i
        and $Release=~/\A\d\d\d\d\d\d\d\d\Z/) {
            return ("opensuse-".$Release, "");
        }
        elsif($Descr=~/\AMaui/i) {
            $Name = $Descr;
        }
    }
    
    if(grep { $Release eq $_ } ("amd64", "x86_64")) {
        $Release = undef;
    }
    
    if((not $Name or not $Release) and $OS_Rel)
    {
        if($OS_Rel=~/\bID=\s*[\"\']*([^"'\n]+)/) {
            $Name = $1;
        }
        
        if($OS_Rel=~/\bNAME=\s*[\"\']*([^"'\n]+)/)
        {
            my $RealName = $1;
            if(grep {$RealName eq $_} ("Peppermint")) {
                $Name = $RealName;
            }
        }
        
        if($OS_Rel=~/\bVERSION_ID=\s*[\"\']*([^"'\n]+)/) {
            $Release = lc($1);
        }
        
        if($Release eq "n/a") {
            $Release = "";
        }
    }
    
    if((not $Name or not $Release) and $Sys_Rel)
    {
        if($Sys_Rel=~/\A(.+?)\s+release\s+([\d\.]+)/ or $Sys_Rel=~/\A(.+?)\s+([\d\.]+)/)
        {
            $Name = $1;
            $Release = lc($2);
        }
    }
    
    if($Name=~/virtuozzo/i and (lc($Name) ne "virtuozzo"
    or not $FName or lc($FName) ne "virtuozzo"))
    {
        $Release = undef;
        $Name = "Virtuozzo";
    }
    
    $Name = shortOS($Name);
    
    if($Name and $Release) {
        return (lc($Name)."-".$Release, "");
    }
    elsif($Name) {
        return (lc($Name), "");
    }
    
    return ("", "");
}

sub devID(@)
{
    my @ID = grep { $_ } @_;
    return lc(join("-", @ID));
}

sub fNum($)
{
    my $N = $_[0];
    
    if(length($N)==1) {
        $N = "0".$N;
    }
    
    return $N;
}

sub devSort($$) {
    return ($_[0]=~/\A(pci|usb)/ cmp $_[1]=~/\A(pci|usb)/);
}

sub writeDevs()
{
    my $HWData = "";
    foreach my $ID (sort {devSort($b, $a)} sort keys(%HW))
    {
        foreach (keys(%{$HW{$ID}})) {
            $HW{$ID}{$_}=~s/;/ /g;
        }
        
        my @D = ();
        
        push(@D, $ID);
        push(@D, $HW{$ID}{"Class"});
        
        if(not $HW{$ID}{"Status"}) {
            $HW{$ID}{"Status"} = "detected";
        }
        
        push(@D, $HW{$ID}{"Status"}); # test result
        
        push(@D, $HW{$ID}{"Type"});
        push(@D, $HW{$ID}{"Driver"});
        
        push(@D, $HW{$ID}{"Vendor"});
        push(@D, $HW{$ID}{"Device"});
        
        if($HW{$ID}{"SVendor"} or $HW{$ID}{"SDevice"})
        {
            push(@D, $HW{$ID}{"SVendor"});
            
            if(defined $HW{$ID}{"SDevice"}
            and $HW{$ID}{"SDevice"} ne "Device") {
                push(@D, $HW{$ID}{"SDevice"});
            }
        }
        
        my $HWLine = join(";", @D)."\n";
        $HWData .= $HWLine;
        
        if(defined $HW_Count{$ID} and $HW_Count{$ID}>1)
        {
            foreach (2 .. $HW_Count{$ID}) {
                $HWData .= $HWLine;
            }
        }
    }
    
    if($Opt{"FixProbe"}) {
        writeFile($Opt{"FixProbe"}."/devices", $HWData);
    }
    else {
        writeFile($DATA_DIR."/devices", $HWData);
    }
}

sub writeHost()
{
    my $Host = "";
    if($Sys{"Probe_ver"}) {
        $Host .= "probe_ver:".$Sys{"Probe_ver"}."\n";
    }
    $Host .= "system:".$Sys{"System"}."\n";
    if($Sys{"Systemrel"}) {
        $Host .= "systemrel:".$Sys{"Systemrel"}."\n";
    }
    if($Sys{"Build"}) {
        $Host .= "build:".$Sys{"Build"}."\n"; # Live
    }
    $Host .= "arch:".$Sys{"Arch"}."\n";
    if($Sys{"Secureboot"}) {
        $Host .= "secureboot:".$Sys{"Secureboot"}."\n";
    }
    $Host .= "kernel:".$Sys{"Kernel"}."\n";
    
    if($Sys{"Vendor"}) {
        $Host .= "vendor:".$Sys{"Vendor"}."\n";
    }
    if($Sys{"Model"}) {
        $Host .= "model:".$Sys{"Model"}."\n";
    }
    if($Sys{"Year"}) {
        $Host .= "year:".$Sys{"Year"}."\n";
    }
    if($Sys{"HWaddr"}) {
        $Host .= "hwaddr:".$Sys{"HWaddr"}."\n";
    }
    if($Sys{"Type"}) {
        $Host .= "type:".$Sys{"Type"}."\n";
    }
    if($Sys{"Name"}) {
        $Host .= "id:".$Sys{"Name"}."\n";
    }
    
    # Host Info
    if($Opt{"FixProbe"}) {
        writeFile($Opt{"FixProbe"}."/host", $Host);
    }
    else {
        writeFile($DATA_DIR."/host", $Host);
    }
}

sub readHost($)
{
    my $Path = $_[0];
    
    my $Content = readFile($Path."/host");
    
    foreach my $Line (split(/\n/, $Content))
    {
        if($Line=~/\A(\w+)\:(.*)\Z/)
        {
            my ($K, $V) = ($1, $2);
            if($K eq "id") {
                $K = "Name";
            }
            elsif($K eq "hwaddr") {
                $K = "HWaddr";
            }
            else {
                $K = ucfirst($K);
            }
            
            $Sys{$K} = $V;
        }
    }
}

sub getUser()
{
    foreach my $Var ("SUDO_USER", "USERNAME", "USER")
    {
        if(defined $ENV{$Var} and $ENV{$Var} ne "root") {
            return $ENV{$Var};
        }
    }

    return;
}

sub writeLogs()
{
    print "Reading logs ... ";
    
    if($Opt{"ListProbes"}) {
        print "\n";
    }

    my $SessUser = getUser() || $ENV{"USER"};

    # level=minimal
    if(checkCmd("sensors"))
    {
        listProbe("logs", "sensors");
        my $Sensors = runCmd("sensors 2>/dev/null");
        writeLog($LOG_DIR."/sensors", $Sensors);
    }
    
    if(enabledLog("meminfo"))
    {
        listProbe("logs", "meminfo");
        my $Meminfo = readFile("/proc/meminfo");
        writeLog($LOG_DIR."/meminfo", $Meminfo);
    }
    
    if(enabledLog("cpuid")
    and checkCmd("cpuid"))
    {
        listProbe("logs", "cpuid");
        my $Cpuid = runCmd("cpuid -1 2>&1");
        $Cpuid = encryptSerials($Cpuid, "serial number");
        writeLog($LOG_DIR."/cpuid", $Cpuid);
    }
    elsif(enabledLog("cpuinfo")
    and -e "/proc/cpuinfo")
    {
        listProbe("logs", "cpuinfo");
        my $Cpuinfo = readFile("/proc/cpuinfo");
        $Cpuinfo=~s/\n\n(.|\n)+\Z/\n/g; # for one core
        writeLog($LOG_DIR."/cpuinfo", $Cpuinfo);
    }
    
    if($Admin)
    {
        if(not $Opt{"Docker"}
        and enabledLog("dmesg.1")
        and checkCmd("journalctl"))
        {
            listProbe("logs", "dmesg.1");
            my $Dmesg_Old = runCmd("journalctl -a -k -b -1 -o short-monotonic 2>/dev/null | grep -v systemd");
            $Dmesg_Old=~s/\]\s+.*?\s+kernel:/]/g;
            $Dmesg_Old = hideTags($Dmesg_Old, "SerialNumber");
            $Dmesg_Old = hideHostname($Dmesg_Old);
            $Dmesg_Old = hideIPs($Dmesg_Old);
            $Dmesg_Old = hideMACs($Dmesg_Old);
            $Dmesg_Old = hidePaths($Dmesg_Old);
            writeLog($LOG_DIR."/dmesg.1", $Dmesg_Old);
        }
    }
    
    if(enabledLog("xorg.log.1"))
    {
        listProbe("logs", "xorg.log.1");
        my $XLog_Old = readFile("/var/log/Xorg.0.log.old");
        
        if(not $XLog_Old)
        {
            if(my $SUser = getUser())
            { # Old Xorg log in XWayland (Ubuntu 18.04)
                $XLog_Old = readFile("/home/".$SUser."/.local/share/xorg/Xorg.0.log.old");
            }
        }
        
        $XLog_Old = hideTags($XLog_Old, "Serial#");
        $XLog_Old = hidePaths($XLog_Old);
        if(my $HostName = $ENV{"HOSTNAME"}) {
            $XLog_Old=~s/ $HostName / NODE /g;
        }
        writeLog($LOG_DIR."/xorg.log.1", $XLog_Old);
    }
    
    if(enabledLog("mcelog")
    and checkCmd("mcelog"))
    {
        listProbe("logs", "mcelog");
        my $Mcelog = runCmd("mcelog --client 2>&1");
        
        if($Mcelog=~/No such file or directory/) {
            $Mcelog = "";
        }
        
        writeLog($LOG_DIR."/mcelog", $Mcelog);
    }
    
    if(enabledLog("xorg.conf"))
    {
        listProbe("logs", "xorg.conf");
        my $XorgConf = readFile("/etc/X11/xorg.conf");
        
        if(not $XorgConf) {
            $XorgConf = readFile("/usr/share/X11/xorg.conf");
        }
        
        if(not $Opt{"Docker"} or $XorgConf) {
            writeLog($LOG_DIR."/xorg.conf", $XorgConf);
        }
    }
    
    if(enabledLog("grub")
    and -e "/etc/default/grub")
    {
        listProbe("logs", "grub");
        my $Grub = readFile("/etc/default/grub");
        writeLog($LOG_DIR."/grub", $Grub);
    }
    
    if(not $Opt{"Docker"})
    {
        if(enabledLog("grub.cfg")
        and -f "/boot/grub2/grub.cfg")
        {
            listProbe("logs", "grub.cfg");
            my $GrubCfg = readFile("/boot/grub2/grub.cfg");
            writeLog($LOG_DIR."/grub.cfg", $GrubCfg);
        }
    }
    
    if(enabledLog("boot.log")
    and -f "/var/log/boot.log")
    {
        listProbe("logs", "boot.log");
        my $BootLog = clearLog(readFile("/var/log/boot.log"));
        $BootLog=~s&(Mounted|Mounting)\s+/.+&$1 XXXXX&g;
        $BootLog=~s&(Setting hostname\s+).+:&$1XXXXX:&g;
        writeLog($LOG_DIR."/boot.log", $BootLog);
    }
    
    if(checkCmd("xrandr"))
    {
        listProbe("logs", "xrandr");
        my $XRandr = runCmd("xrandr --verbose 2>&1");
        writeLog($LOG_DIR."/xrandr", clearLog_X11($XRandr));
        
        listProbe("logs", "xrandr_providers");
        my $XRandrProviders = runCmd("xrandr --listproviders 2>&1");
        writeLog($LOG_DIR."/xrandr_providers", clearLog_X11($XRandrProviders));
    }
    
    if(checkCmd("glxinfo"))
    {
        listProbe("logs", "glxinfo");
        my $Glxinfo = runCmd("glxinfo 2>&1");
        $Glxinfo = clearLog_X11($Glxinfo);
        
        if(not clearLog_X11($Glxinfo)) {
            printMsg("WARNING", "X11-related logs are not collected (try to run 'xhost +local:' to enable access or run as root by su)");
        }
        
        writeLog($LOG_DIR."/glxinfo", $Glxinfo);
    }
    
    if(checkCmd("biosdecode"))
    {
        listProbe("logs", "biosdecode");
        my $BiosDecode = "";
        if($Admin)
        {
            $BiosDecode = runCmd("biosdecode 2>/dev/null");
            
            if(length($BiosDecode)<20) {
                $BiosDecode = "";
            }
        }
        writeLog($LOG_DIR."/biosdecode", $BiosDecode);
    }
    
    if(not $Opt{"Docker"}
    and enabledLog("df")
    and checkCmd("df"))
    {
        listProbe("logs", "df");
        my $Df = runCmd("df -h 2>&1");
        $Df = hidePaths($Df);
        $Df = hideIPs($Df);
        $Df = hideUrls($Df);
        writeLog($LOG_DIR."/df", $Df);
    }
    
    if(not $Opt{"Flatpak"})
    {
        if(checkCmd("lscpu"))
        {
            listProbe("logs", "lscpu");
            my $Lscpu = runCmd("lscpu 2>&1");
            writeLog($LOG_DIR."/lscpu", $Lscpu);
        }
    }
    
    # level=default
    if(enabledLog("uptime")
    and checkCmd("uptime"))
    {
        listProbe("logs", "uptime");
        my $Uptime = runCmd("uptime");
        writeLog($LOG_DIR."/uptime", $Uptime);
    }
    
    if(not $Opt{"AppImage"}
    and enabledLog("cpupower")
    and checkCmd("cpupower"))
    { # TODO: Why doesn't work in AppImage?
        listProbe("logs", "cpupower");
        my $CPUpower = "";
        $CPUpower .= "frequency-info\n--------------\n";
        $CPUpower .= runCmd("cpupower frequency-info 2>&1");
        $CPUpower .= "\n";
        $CPUpower .= "idle-info\n---------\n";
        $CPUpower .= runCmd("cpupower idle-info 2>&1");
        
        if($CPUpower=~/cpupower not found/) {
            $CPUpower = undef;
        }
        
        if($CPUpower) {
            writeLog($LOG_DIR."/cpupower", $CPUpower);
        }
    }
    
    if(enabledLog("dkms_status")
    and checkCmd("dkms"))
    {
        listProbe("logs", "dkms_status");
        my $DkmsStatus = "";
        if($Admin) {
            $DkmsStatus = runCmd("dkms status 2>&1");
        }
        writeLog($LOG_DIR."/dkms_status", $DkmsStatus);
    }
    
    if(enabledLog("xdpyinfo")
    and checkCmd("xdpyinfo"))
    {
        listProbe("logs", "xdpyinfo");
        if(my $Xdpyinfo = runCmd("xdpyinfo 2>&1")) {
            writeLog($LOG_DIR."/xdpyinfo", clearLog_X11($Xdpyinfo));
        }
    }
    
    if(enabledLog("xinput")
    and checkCmd("xinput"))
    {
        listProbe("logs", "xinput");
        my $XInput = runCmd("xinput list --long 2>&1");
        writeLog($LOG_DIR."/xinput", clearLog_X11($XInput));
    }
    
    if(enabledLog("rpms")
    and checkCmd("rpm"))
    {
        listProbe("logs", "rpms");
        my $Rpms = runCmd("rpm -qa 2>/dev/null | sort");
        
        if($Rpms) {
            writeLog($LOG_DIR."/rpms", $Rpms);
        }
    }
    
    if(enabledLog("dpkg")
    and checkCmd("dpkg"))
    {
        listProbe("logs", "debs");
        my $Dpkgs = runCmd("dpkg -l 2>/dev/null | awk '/^[hi]i/{print \$2,\$3,\$4}'");
        
        if($Dpkgs) {
            writeLog($LOG_DIR."/debs", $Dpkgs);
        }
    }
    
    if(enabledLog("apk") and $Sys{"System"}=~/alpine/i
    and checkCmd("apk"))
    {
        listProbe("logs", "apk");
        my $Apk = runCmd("apk info 2>/dev/null");
        
        if($Apk) {
            writeLog($LOG_DIR."/apk", $Apk);
        }
    }
    
    if(enabledLog("pkglist")
    and checkCmd("pacman"))
    { # Arch / Manjaro
        listProbe("logs", "pkglist");
        my $Pkglist = runCmd("pacman -Q 2>/dev/null");
        
        if($Pkglist) {
            writeLog($LOG_DIR."/pkglist", $Pkglist);
        }
    }
    
    if(enabledLog("pkglist") and $Sys{"System"}=~/solus/i
    and checkCmd("eopkg"))
    {
        listProbe("logs", "pkglist");
        my $Pkglist = runCmd("eopkg list-installed -l 2>/dev/null | grep Name:");
        
        if($Pkglist)
        {
            $Pkglist=~s/Name\: //g;
            $Pkglist=~s/, version: / /g;
            $Pkglist=~s/, release: / r/g;
            writeLog($LOG_DIR."/pkglist", $Pkglist);
        }
    }
    
    if(not $Opt{"Docker"})
    {
        if(enabledLog("rfkill")
        and checkCmd("rfkill"))
        {
            listProbe("logs", "rfkill");
            my $Rfkill = runCmd("rfkill list 2>&1");
            
            if($Opt{"Snap"} and $Rfkill=~/Permission denied/) {
                $Rfkill = "";
            }
            
            writeLog($LOG_DIR."/rfkill", $Rfkill);
        }
    }
    
    if(enabledLog("iw_list")
    and checkCmd("iw"))
    {
        listProbe("logs", "iw_list");
        my $IwList = runCmd("iw list 2>&1");
        
        if($Opt{"Snap"} and $IwList=~/Permission denied/) {
            $IwList = "";
        }
        
        if($IwList) {
            writeLog($LOG_DIR."/iw_list", $IwList);
        }
    }
    
    if(enabledLog("iwconfig")
    and checkCmd("iwconfig"))
    {
        listProbe("logs", "iwconfig");
        my $IwConfig = runCmd("iwconfig 2>&1");
        $IwConfig = hideMACs($IwConfig);
        $IwConfig = hideTags($IwConfig, "ESSID");
        writeLog($LOG_DIR."/iwconfig", $IwConfig);
    }
    
    if(enabledLog("nm-tool")
    and checkCmd("nm-tool"))
    {
        listProbe("logs", "nm-tool");
        my $NmTool = runCmd("nm-tool 2>&1");
        if($NmTool) {
            writeLog($LOG_DIR."/nm-tool", $NmTool);
        }
    }
    
    if(enabledLog("nmcli")
    and checkCmd("nmcli"))
    {
        listProbe("logs", "nmcli");
        my $NmCli = runCmd("nmcli c 2>&1");
        $NmCli=~s/.+\s+([^\s]+\s+[^\s]+\s+[^\s]+\s*\n)/XXX   $1/g;
        $NmCli=~s/\AXXX /NAME/g;
        if($NmCli) {
            writeLog($LOG_DIR."/nmcli", $NmCli);
        }
    }
    
    if($Admin)
    {
        if(enabledLog("fdisk")
        and checkCmd("fdisk"))
        {
            listProbe("logs", "fdisk");
            my $Fdisk = runCmd("fdisk -l 2>&1");
            if($Opt{"Snap"} and $Fdisk=~/Permission denied/) {
                $Fdisk = "";
            }
            $Fdisk = hidePaths($Fdisk);
            writeLog($LOG_DIR."/fdisk", $Fdisk);
        }
    }
    
    if(enabledLog("inxi")
    and my $InxiCmd = checkCmd("inxi"))
    {
        listProbe("logs", "inxi");
        my $Inxi = undef;
        
        if(readLine($InxiCmd)=~/perl/)
        { # The new Perl inxi
            $Inxi = runCmd("inxi -Fxxxz --no-host 2>&1");
        }
        else
        { # Old inxi
            $Inxi = runCmd("inxi -Fxz -c 0 -! 31 2>&1");
        }
        
        $Inxi=~s/\s+\w+\:\s*<filter>//g;
        writeLog($LOG_DIR."/inxi", $Inxi);
    }
    
    if(enabledLog("i2cdetect")
    and checkCmd("i2cdetect"))
    {
        listProbe("logs", "i2cdetect");
        my $I2cdetect = runCmd("i2cdetect -l 2>&1");
        writeLog($LOG_DIR."/i2cdetect", $I2cdetect);
    }
    
    if(-e "/sys/firmware/efi") # defined $KernMod{"efivarfs"}
    { # installed in EFI mode
        if(enabledLog("efivar")
        and checkCmd("efivar"))
        {
            listProbe("logs", "efivar");
            my $Efivar = runCmd("efivar -l 2>&1");
            
            if($Efivar=~/error listing variables/i) {
                $Efivar = "";
            }
            
            writeLog($LOG_DIR."/efivar", $Efivar);
        }
        
        if($Admin and $Sys{"Arch"} eq "x86_64")
        {
            if(enabledLog("efibootmgr")
            and checkCmd("efibootmgr"))
            {
                listProbe("logs", "efibootmgr");
                my $Efibootmgr = runCmd("efibootmgr -v 2>&1");
                if($Opt{"Snap"} and $Efibootmgr=~/Permission denied/) {
                    $Efibootmgr = "";
                }
                writeLog($LOG_DIR."/efibootmgr", $Efibootmgr);
            }
        }
        
        if(enabledLog("boot_efi")
        and -d "/boot/efi" and not $Opt{"Snap"})
        {
            listProbe("logs", "boot_efi");
            my $BootEfi = runCmd("find /boot/efi 2>/dev/null | sort");
            writeLog($LOG_DIR."/boot_efi", $BootEfi);
        }
    }
    
    my $Switch = "/sys/kernel/debug/vgaswitcheroo/switch";
    if(enabledLog("vgaswitcheroo")
    and -e $Switch)
    {
        listProbe("logs", "vgaswitcheroo");
        my $SInfo = readFile($Switch);
        writeLog($LOG_DIR."/vgaswitcheroo", $SInfo);
    }
    
    if(enabledLog("input_devices"))
    {
        listProbe("logs", "input_devices");
        my $InputDevices = readFile("/proc/bus/input/devices");
        writeLog($LOG_DIR."/input_devices", $InputDevices);
    }
    
    if(not $Opt{"Docker"})
    {
        if(enabledLog("systemctl")
        and checkCmd("systemctl"))
        {
            listProbe("logs", "systemctl");
            my $Sctl = runCmd("systemctl 2>/dev/null");
            $Sctl=~s/( of user)\s+\Q$SessUser\E/$1 USER/g;
            $Sctl = decorateSystemd($Sctl);
            writeLog($LOG_DIR."/systemctl", $Sctl);
        }
    }
    
    if(enabledLog("iostat")
    and checkCmd("iostat"))
    {
        listProbe("logs", "iostat");
        my $Iostat = runCmd("iostat 2>&1");
        $Iostat=~s/\(.+\)/(...)/;
        writeLog($LOG_DIR."/iostat", $Iostat);
    }
    
    if(enabledLog("acpi")
    and checkCmd("acpi"))
    {
        listProbe("logs", "acpi");
        my $Acpi = runCmd("acpi -V 2>/dev/null");
        writeLog($LOG_DIR."/acpi", $Acpi);
    }
    
    if(defined $KernMod{"fglrx"} and $KernMod{"fglrx"}!=0)
    {
        if(enabledLog("fglrxinfo")
        and checkCmd("fglrxinfo"))
        {
            listProbe("logs", "fglrxinfo");
            my $Fglrxinfo = runCmd("fglrxinfo -t 2>&1");
            writeLog($LOG_DIR."/fglrxinfo", $Fglrxinfo);
        }
        
        if(enabledLog("amdconfig")
        and checkCmd("amdconfig"))
        {
            listProbe("logs", "amdconfig");
            my $AMDconfig = runCmd("amdconfig --list-adapters 2>&1");
            writeLog($LOG_DIR."/amdconfig", $AMDconfig);
        }
    }
    elsif(defined $KernMod{"nvidia"} and $KernMod{"nvidia"}!=0)
    {
        if(enabledLog("nvidia-smi"))
        {
            foreach ("64", "")
            {
                my $NvidiaSmi_Path = "/usr/lib".$_."/nvidia/bin/nvidia-smi";
                
                if(-e $NvidiaSmi_Path)
                {
                    listProbe("logs", "nvidia-smi");
                    my $NvidiaSmi = runCmd("$NvidiaSmi_Path -q 2>&1");
                    writeLog($LOG_DIR."/nvidia-smi", $NvidiaSmi);
                    last;
                }
            }
        }
    }
    
    if(enabledLog("vulkaninfo")
    and checkCmd("vulkaninfo"))
    {
        listProbe("logs", "vulkaninfo");
        my $Vulkaninfo = runCmd("vulkaninfo 2>&1");
        if($Vulkaninfo!~/Cannot create/i) {
            writeLog($LOG_DIR."/vulkaninfo", $Vulkaninfo);
        }
    }
    
    if(enabledLog("vdpauinfo")
    and checkCmd("vdpauinfo"))
    {
        listProbe("logs", "vdpauinfo");
        my $Vdpauinfo = runCmd("vdpauinfo 2>&1");
        if($Vdpauinfo=~/Failed to open/i) {
            $Vdpauinfo = undef;
        }
        if($Vdpauinfo) {
            writeLog($LOG_DIR."/vdpauinfo", clearLog_X11($Vdpauinfo));
        }
    }
    
    if(enabledLog("vainfo")
    and checkCmd("vainfo"))
    {
        listProbe("logs", "vainfo");
        my $Vainfo = runCmd("vainfo 2>&1");
        if($Vainfo=~/failed with error/i) {
            $Vainfo = undef;
        }
        if($Vainfo) {
            writeLog($LOG_DIR."/vainfo", clearLog_X11($Vainfo));
        }
    }
    
    if(enabledLog("lsblk")
    and checkCmd("lsblk"))
    {
        listProbe("logs", "lsblk");
        my $LsblkCmd = "lsblk -al -o NAME,SIZE,TYPE,FSTYPE,UUID,MOUNTPOINT,MODEL,PARTUUID";
        if($Opt{"Flatpak"}) {
            $LsblkCmd .= " 2>/dev/null";
        }
        else {
            $LsblkCmd .= " 2>&1";
        }
        my $Lsblk = runCmd($LsblkCmd);
        
        if($Lsblk=~/unknown column/)
        { # CentOS 6: no PARTUUID column
            $LsblkCmd=~s/\,PARTUUID//g;
            $Lsblk = runCmd($LsblkCmd);
        }
        
        if($Opt{"Snap"} and $Lsblk=~/Permission denied/) {
            $Lsblk = "";
        }
        $Lsblk = hideByRegexp($Lsblk, qr/(.+?)\s+[^\s]+?\s+crypt\s+/);
        $Lsblk = hidePaths($Lsblk);
        writeLog($LOG_DIR."/lsblk", $Lsblk);
    }
    
    if(not $Opt{"Docker"}
    and enabledLog("fstab"))
    {
        listProbe("logs", "fstab");
        my $Fstab = readFile("/etc/fstab");
        $Fstab = hidePaths($Fstab);
        $Fstab = hideIPs($Fstab);
        $Fstab = hideUrls($Fstab);
        $Fstab = hidePass($Fstab);
        $Fstab=~s/LABEL=[^\s]+/LABEL=XXXX/g;
        writeLog($LOG_DIR."/fstab", $Fstab);
    }
    
    if(enabledLog("scsi"))
    {
        listProbe("logs", "scsi");
        my $Scsi = readFile("/proc/scsi/scsi");
        if($Scsi)
        { # list all devices in RAID
            writeLog($LOG_DIR."/scsi", $Scsi);
        }
    }
    
    if(enabledLog("ioports"))
    {
        listProbe("logs", "ioports");
        my $IOports = readFile("/proc/ioports");
        writeLog($LOG_DIR."/ioports", $IOports);
    }
    
    if(enabledLog("interrupts"))
    {
        listProbe("logs", "interrupts");
        my $Interrupts = readFile("/proc/interrupts");
        writeLog($LOG_DIR."/interrupts", $Interrupts);
    }
    
    my $Aplay = undef;
    if(enabledLog("aplay")
    and checkCmd("aplay"))
    {
        listProbe("logs", "aplay");
        $Aplay = runCmd("aplay -l 2>&1");
        if(length($Aplay)<80
        and $Aplay=~/no soundcards found|not found/i) {
            $Aplay = "";
        }
        writeLog($LOG_DIR."/aplay", $Aplay);
    }
    
    if(enabledLog("arecord")
    and checkCmd("arecord"))
    {
        listProbe("logs", "arecord");
        my $Arecord = runCmd("arecord -l 2>&1");
        if(length($Arecord)<80
        and $Arecord=~/no soundcards found|not found/i) {
            $Arecord = "";
        }
        writeLog($LOG_DIR."/arecord", $Arecord);
    }
    
    if(enabledLog("amixer")
    and checkCmd("amixer"))
    {
        listProbe("logs", "amixer");
        
        if(not defined $Aplay) {
            $Aplay = runCmd("aplay -l");
        }
        
        my %CardNums = ();
        while($Aplay=~/card\s+(\d+)/g) {
            $CardNums{$1} = 1;
        }
        
        my $Amixer = "";
        foreach my $ACard (sort {int($a)<=>int($b)} keys(%CardNums))
        {
            $Amixer .= runCmd("amixer -c$ACard info 2>&1");
            $Amixer .= runCmd("amixer -c$ACard 2>&1");
            $Amixer .= "\n";
        }
        writeLog($LOG_DIR."/amixer", $Amixer);
    }
    
    if(enabledLog("alsactl")
    and checkCmd("alsactl"))
    {
        listProbe("logs", "alsactl");
        system("alsactl store -f $TMP_DIR/alsactl 2>/dev/null");
        if(-f "$TMP_DIR/alsactl") {
            move("$TMP_DIR/alsactl", $LOG_DIR."/alsactl");
        }
    }
    
    if(enabledLog("systemd-analyze")
    and checkCmd("systemd-analyze"))
    {
        listProbe("logs", "systemd-analyze");
        my $SystemdAnalyze = runCmd("systemd-analyze 2>/dev/null");
        $SystemdAnalyze .= "\n";
        $SystemdAnalyze .= runCmd("systemd-analyze blame 2>/dev/null");
        $SystemdAnalyze = decorateSystemd($SystemdAnalyze);
        writeLog($LOG_DIR."/systemd-analyze", $SystemdAnalyze);
    }
    
    if(enabledLog("gpu-manager.log")
    and -f "/var/log/gpu-manager.log")
    { # Ubuntu
        listProbe("logs", "gpu-manager.log");
        if(my $GpuManager = readFile("/var/log/gpu-manager.log")) {
            writeLog($LOG_DIR."/gpu-manager.log", $GpuManager);
        }
    }
    
    if(not $Opt{"Docker"}
    and enabledLog("modprobe.d"))
    {
        listProbe("logs", "modprobe.d");
        my @Modprobe = listDir("/etc/modprobe.d/");
        my $Mprobe = "";
        foreach my $Mp (@Modprobe)
        {
            if($Mp eq "00_modprobe.conf"
            or $Mp eq "01_mandriva.conf") {
                next;
            }
            $Mprobe .= $Mp."\n";
            foreach (1 .. length($Mp)) {
                $Mprobe .= "-";
            }
            $Mprobe .= "\n";
            my $Content = readFile("/etc/modprobe.d/".$Mp);

            $Content=~s{http(s|)://[^ ]+}{}g;

            $Mprobe .= $Content;
            $Mprobe .= "\n\n";
        }
        writeLog($LOG_DIR."/modprobe.d", $Mprobe);
    }
    
    if(enabledLog("xorg.conf"))
    {
        listProbe("logs", "xorg.conf.d");
        my $XConfig = "";
        
        foreach my $XDir ("/etc/X11/xorg.conf.d", "/usr/share/X11/xorg.conf.d")
        {
            if(not -d $XDir) {
                next;
            }
            
            my @XorgConfD = listDir($XDir);
            foreach my $Xc (@XorgConfD)
            {
                if($Xc!~/\.conf\Z/) {
                    next;
                }
                $XConfig .= $Xc."\n";
                foreach (1 .. length($Xc)) {
                    $XConfig .= "-";
                }
                $XConfig .= "\n";
                $XConfig .= readFile($XDir."/".$Xc);
                $XConfig .= "\n\n";
            }
        }
        
        if(not $Opt{"Docker"} or $XConfig) {
            writeLog($LOG_DIR."/xorg.conf.d", $XConfig);
        }
    }
    
    if($Opt{"Scanners"})
    {
        if(enabledLog("sane-find-scanner")
        and checkCmd("sane-find-scanner"))
        {
            listProbe("logs", "sane-find-scanner");
            my $FindScanner = runCmd("sane-find-scanner -q 2>/dev/null");
            writeLog($LOG_DIR."/sane-find-scanner", $FindScanner);
        }
        
        if(enabledLog("scanimage")
        and checkCmd("scanimage"))
        {
            listProbe("logs", "scanimage");
            my $Scanimage = runCmd("scanimage -L 2>/dev/null | grep -v v4l");
            if($Scanimage=~/No scanners were identified/i) {
                $Scanimage = "";
            }
            writeLog($LOG_DIR."/scanimage", $Scanimage);
        }
    }
    
    # level=maximal

    if(not $Opt{"Docker"})
    {
        if(enabledLog("findmnt")
        and checkCmd("findmnt"))
        {
            listProbe("logs", "findmnt");
            my $FindmntCmd = "findmnt";
            if($Opt{"Flatpak"}) {
                $FindmntCmd .= " 2>/dev/null";
            }
            else {
                $FindmntCmd .= " 2>&1";
            }
            
            my $Findmnt = runCmd($FindmntCmd);
            if($Opt{"Snap"} and $Findmnt=~/Permission denied/) {
                $Findmnt = "";
            }
            
            $Findmnt=~s/\[[^\s]+\]/[XXXXX]/g;
            $Findmnt = hidePaths($Findmnt);
            $Findmnt = hideIPs($Findmnt);
            $Findmnt = hideUrls($Findmnt);
            writeLog($LOG_DIR."/findmnt", $Findmnt);
        }
        
        if(enabledLog("mount")
        and checkCmd("mount"))
        {
            listProbe("logs", "mount");
            
            my $Mount = runCmd("mount -v 2>&1 | column -t");
            if($Opt{"Snap"} and $Mount=~/Permission denied/) {
                $Mount = "";
            }
            
            $Mount = hidePaths($Mount);
            $Mount = hideIPs($Mount);
            $Mount = hideUrls($Mount);
            writeLog($LOG_DIR."/mount", $Mount);
        }
    }
    
    if(enabledLog("firmware")
    and -d "/lib/firmware")
    {
        listProbe("logs", "firmware");
        my $Firmware = runCmd("find /lib/firmware -type f | sort");
        $Firmware=~s{/lib/firmware/}{}g;
        writeLog($LOG_DIR."/firmware", $Firmware);
    }
    
    if(enabledLog("top")
    and checkCmd("top"))
    {
        listProbe("logs", "top");
        my $TopInfo = runCmd("top -n 1 -b 2>&1");
        if($SessUser) {
            $TopInfo=~s/ \Q$SessUser\E / USER /g;
        }
        writeLog($LOG_DIR."/top", $TopInfo);
    }
    
    if(enabledLog("pstree")
    and checkCmd("pstree"))
    {
        listProbe("logs", "pstree");
        my $Pstree = runCmd("pstree 2>&1");
        writeLog($LOG_DIR."/pstree", $Pstree);
    }
    
    if(enabledLog("numactl")
    and checkCmd("numactl"))
    {
        listProbe("logs", "numactl");
        my $Numactl = runCmd("numactl -H");
        
        if($Numactl) {
            writeLog($LOG_DIR."/numactl", $Numactl);
        }
    }
    
    if(enabledLog("slabtop")
    and checkCmd("slabtop"))
    {
        listProbe("logs", "slabtop");
        my $Slabtop = runCmd("slabtop -o");
        writeLog($LOG_DIR."/slabtop", $Slabtop);
    }
    
    # scan for available WiFi networks
    if(enabledLog("iw_scan")
    and checkCmd("iw"))
    {
        listProbe("logs", "iw_scan");
        my $IwScan = "";
        if($Admin)
        {
            foreach my $I (sort keys(%WLanInterface))
            {
                $IwScan .= $I."\n";
                foreach (1 .. length($I)) {
                    $IwScan .= "-";
                }
                $IwScan .= "\n";
                $IwScan .= runCmd("iw dev $I scan 2>&1");
                $IwScan .= "\n";
            }
        }
        $IwScan = hideTags($IwScan, "SSID|UUID|Serial Number");
        $IwScan = hideMACs($IwScan);
        writeLog($LOG_DIR."/iw_scan", $IwScan);
    }
    
    # scan for available bluetooth connections
    if(enabledLog("hcitool_scan")
    and checkCmd("hcitool"))
    {
        listProbe("logs", "hcitool_scan");
        my $HciScan = runCmd("hcitool scan --class 2>&1");
        if($HciScan=~/No such device/i) {
            $HciScan = "";
        }
        $HciScan = hideMACs($HciScan);
        if($HciScan) {
            writeLog($LOG_DIR."/hcitool_scan", $HciScan);
        }
    }
    
    if(enabledLog("route")
    and checkCmd("route"))
    {
        listProbe("logs", "route");
        my $Route = runCmd("route 2>&1");
        $Route = hideIPs($Route);
        writeLog($LOG_DIR."/route", $Route);
    }
    
    if(enabledLog("xvinfo")
    and checkCmd("xvinfo"))
    {
        listProbe("logs", "xvinfo");
        my $XVInfo = runCmd("xvinfo 2>&1");
        writeLog($LOG_DIR."/xvinfo", clearLog_X11($XVInfo));
    }
    
    if(enabledLog("lsinitrd")
    and checkCmd("lsinitrd"))
    {
        listProbe("logs", "lsinitrd");
        my $Lsinitrd = runCmd("lsinitrd 2>&1");
        $Lsinitrd=~s/.*?(\w+\s+\d+\s+\d\d\d\d\s+)/$1/g;
        writeLog($LOG_DIR."/lsinitrd", $Lsinitrd);
    }
    
    if(enabledLog("update-alternatives")
    and checkCmd("update-alternatives"))
    {
        listProbe("logs", "update-alternatives");
        my $Alternatives = runCmd("update-alternatives --list 2>/dev/null");
        writeLog($LOG_DIR."/update-alternatives", $Alternatives);
    }
    
    if($Opt{"Printers"})
    {
        if($Admin)
        {
            my $ELog = "/var/log/cups/error_log";
            if(enabledLog("cups_error_log") and -e $ELog)
            {
                listProbe("logs", "cups_error_log");
                my $CupsError = readFile($ELog);
                writeLog($LOG_DIR."/cups_error_log", $CupsError);
            }
            
            my $ALog = "/var/log/cups/access_log";
            if(enabledLog("cups_access_log") and -e $ALog)
            {
                listProbe("logs", "cups_access_log");
                my $CupsAccess = readFile($ALog);
                writeLog($LOG_DIR."/cups_access_log", $CupsAccess);
            }
        }
    }
        
    # Disabled as it can hang the system
    # my $SuperIO = "";
    # if($Admin) {
    #     $SuperIO = runCmd("superiotool -d 2>/dev/null");
    # }
    # writeLog($LOG_DIR."/superiotool", $SuperIO);
    
    if($Opt{"DumpACPI"})
    {
        listProbe("logs", "acpidump");
        my $AcpiDump = "";
        
        # To decode acpidump:
        #  1. acpixtract -a acpidump
        #  2. iasl -d ECDT.dat
        
        if($Admin)
        {
            if(checkCmd("acpidump")) {
                $AcpiDump = runCmd("acpidump 2>/dev/null");
            }
        }
        writeLog($LOG_DIR."/acpidump", $AcpiDump);
        
        if($Opt{"DecodeACPI"})
        {
            if(-s "$LOG_DIR/acpidump")
            {
                if(decodeACPI("$LOG_DIR/acpidump", "$LOG_DIR/acpidump_decoded")) {
                    unlink("$LOG_DIR/acpidump");
                }
            }
        }
    }
    
    print "Ok\n";
}

sub checkCmd(@)
{
    my $Cmd = shift(@_);
    my $Verify = undef;
    if(@_) {
        $Verify = shift(@_);
    }
    
    if(index($Cmd, "/")!=-1 and -x $Cmd)
    { # relative or absolute path
        return $Cmd;
    }
    
    foreach my $Dir (sort {length($a)<=>length($b)} split(/:/, $ENV{"PATH"}))
    {
        if(-x "$Dir/$Cmd")
        {
            if($Verify)
            {
                if(not `$Dir/$Cmd --version 2>/dev/null`) {
                    next;
                }
            }
            return "$Dir/$Cmd";
        }
    }
    
    return;
}

sub findCmd($)
{
    my $Cmd = $_[0];
    if(my $Path = checkCmd($Cmd, 1)) {
        return $Path;
    }
    return $Cmd;
}

sub decodeACPI($$)
{
    my ($Dump, $Output) = @_;
    $Dump = abs_path($Dump);
    
    if(not checkCmd("acpixtract")
    or not checkCmd("iasl")) {
        return 0;
    }
    
    my $TmpDir = $TMP_DIR."/acpi";
    mkpath($TmpDir);
    chdir($TmpDir);
    
    # list data
    my $DSL = runCmd("acpixtract -l \"$Dump\" 2>&1");
    $DSL .= "\n";
    
    # extract *.dat
    system("acpixtract -a \"$Dump\" >/dev/null 2>&1");
    
    # decode *.dat
    my @Files = listDir(".");
    
    foreach my $File (@Files)
    {
        if($File=~/\A(.+)\.dat\Z/)
        {
            my $Name = $1;
            
            if($Name=~/dsdt/i) {
                # next;
            }

            runCmd("iasl -d \"$File\" 2>&1");

            my $DslFile = $Name.".dsl";
            if(-f $DslFile)
            {
                $DSL .= uc($Name)."\n";
                foreach (1 .. length($Name)) {
                    $DSL .= "-";
                }
                $DSL .= "\n";
                my $Data = readFile($DslFile);
                $Data=~s{\A\s*/\*.*?\*/\s*}{}sg;
                $DSL .= $Data;
                
                $DSL .= "\n";
                $DSL .= "\n";
            }
            
            unlink($File);
            unlink($DslFile);
        }
    }
    chdir($ORIG_DIR);
    
    writeFile($Output, $DSL);
    
    if($DSL) {
        unlink($Dump);
    }
    
    rmtree($TmpDir);
    
    return 1;
}

sub clearLog_X11($)
{
    if(length($_[0])<$EMPTY_LOG_SIZE
    and $_[0]=~/No protocol specified|Can't open display|unable to open display|Unable to connect to|cannot connect to/i) {
        return "";
    }
    
    return $_[0];
}

sub clearLog($)
{
    my $Log = $_[0];
    
    my $Sc = chr(27);
    $Log=~s/$Sc\[.*?m//g;
    $Log=~s/$Sc%G//g;
    return $Log;
}

sub showInfo()
{
    my $ShowDir = $DATA_DIR;
    
    if($Opt{"Source"})
    {
        if(-f $Opt{"Source"})
        {
            if(isPkg($Opt{"Source"}))
            {
                my $Pkg = abs_path($Opt{"Source"});
                chdir($TMP_DIR);
                system("tar", "-m", "-xf", $Pkg);
                chdir($ORIG_DIR);
                
                if($?)
                {
                    printMsg("ERROR", "failed to extract package (".$?.")");
                    exitStatus(1);
                }
                
                if(my @Dirs = listDir($TMP_DIR)) {
                    $ShowDir = $TMP_DIR."/".$Dirs[0];
                }
                else
                {
                    printMsg("ERROR", "failed to extract package");
                    exitStatus(1);
                }
            }
            else
            {
                printMsg("ERROR", "not a package");
                exitStatus(1);
            }
        }
        elsif(-d $Opt{"Source"})
        {
            $ShowDir = $Opt{"Source"};
        }
        else
        {
            printMsg("ERROR", "can't access '".$Opt{"Source"}."'");
            exitStatus(1);
        }
    }
    else
    {
        if(not -d $DATA_DIR)
        {
            printMsg("ERROR", "'".$DATA_DIR."' is not found, please make probe first");
            exitStatus(1);
        }
    }
    
    my %Tbl;
    my %STbl;
    
    foreach my $L (split(/\s*\n\s*/, readFile($ShowDir."/devices")))
    {
        my @Info = split(/;/, $L);

        my %Dev = (
            "ID"      => $Info[0],
            "Class"   => $Info[1],
            "Status"  => $Info[2],
            "Type"    => $Info[3],
            "Driver"  => $Info[4],
            "Vendor"  => $Info[5],
            "Device"  => $Info[6],
            "SVendor" => $Info[7],
            "SDevice" => $Info[8]
        );
        
        if($Dev{"ID"}=~s/\A([^:]+)\://)
        {
            $Dev{"Bus"} = uc($1);
            
            if($Dev{"Bus"}=~/BAT|BIOS|BOARD|CPU|MEM/) {
                $Dev{"Bus"} = "SYS";
            }
        }
        
        foreach my $Attr (keys(%Dev))
        {
            if(not defined $Tbl{$Attr}) {
                $Tbl{$Attr} = [];
            }
            
            my $Val = $Dev{$Attr};
            
            if($Attr eq "ID")
            {
                if(index($Val, "-serial-")!=-1) {
                    $Val=~s/\-serial\-(.+?)\Z//;
                }
            }
            
            if($Opt{"Compact"})
            {
                if($Attr eq "ID") {
                    $Val = shortStr($Val, 19);
                }
                elsif($Attr eq "Vendor") {
                    $Val = shortStr($Val, 22);
                }
                elsif($Attr eq "Device") {
                    $Val = shortStr($Val, 40);
                }
                elsif($Attr eq "Type") {
                    $Val = shortStr($Val, 14);
                }
            }
            
            push(@{$Tbl{$Attr}}, $Val);
        }
    }
    
    foreach my $L (split(/\s*\n\s*/, readFile($ShowDir."/host")))
    {
        if($L=~/(\w+):(.*)/)
        {
            my ($Attr, $Val) = ($1, $2);
            
            if($Opt{"Compact"})
            {
                if($Attr eq "id") {
                    $Val = shortStr($Val, 25);
                }
            }
            
            $STbl{$Attr} = $Val;
        }
    }
    
    print "\n";
    
    if($Opt{"Show"})
    {
        print "Host Info\n";
        print "=========\n\n";
        foreach my $Attr ("system", "arch", "kernel", "vendor", "model", "year", "type", "id")
        {
            if($STbl{$Attr})
            {
                print ucfirst($Attr).": ";
                print " " x (length("kernel")-length($Attr));
                print $STbl{$Attr}."\n";
            }
        }
        print "\n\n";
    }
    
    if($Opt{"ShowDevices"})
    {
        my $Rows = $#{$Tbl{"ID"}};
        my $DevsTitle = "Devices (".($Rows + 1).")";
        
        print $DevsTitle."\n";
        print "=" x (length($DevsTitle));
        print "\n\n";
        
        if(defined $Opt{"Verbose"}) {
            showTable(\%Tbl, $Rows, "Bus", "ID", "Class", "Vendor", "Device", "Type", "Status");
        }
        else {
            showTable(\%Tbl, $Rows, "Bus", "ID", "Vendor", "Device", "Type");
        }
        print "\n";
    }
    
    
}

sub shortStr($$)
{
    my ($Str, $Len) = @_;
    
    if(length($Str)>$Len) {
        return substr($Str, 0, $Len-3)."...";
    }
    
    return $Str;
}

sub showTable(@)
{
    my ($Tbl, $Num, @Columns) = @_;
    
    my %Max;
    
    foreach my $Col (sort keys(%{$Tbl}))
    {
        if(not defined $Max{$Col}) {
            $Max{$Col} = 0;
        }
        
        foreach my $El (@{$Tbl->{$Col}})
        {
            if(length($El) > $Max{$Col}) {
                $Max{$Col} = length($El);
            }
        }
    }
    
    my $Br = "";
    my $Hd = "";
    
    foreach my $Col (@Columns)
    {
        my $Hd_T = $Col;
        if(not $Hd) {
            $Hd_T = "| ".$Hd_T;
        }
        $Hd .= "| ".$Col;
        $Hd .= mulCh(" ", $Max{$Col} - length($Col) + 1);
        
        $Br .= "+";
        $Br .= mulCh("-", $Max{$Col} + 2);
    }
    
    $Br .= "+";
    $Hd .= "|";
    
    print $Br."\n";
    print $Hd."\n";
    print $Br."\n";
    
    foreach my $Row (0 .. $Num)
    {
        foreach my $Col (@Columns)
        {
            my $El = $Tbl->{$Col}[$Row];
            print "| ".$El;
            print alignStr($El, $Max{$Col} + 1);
        }
        print "|\n";
    }
    
    print $Br."\n";
}

sub mulCh($$)
{
    my $Str = "";
    foreach (1 .. $_[1]) {
        $Str .= $_[0];
    }
    return $Str;
}

sub alignStr($$)
{
    my $Align = "";
    
    foreach (1 .. ($_[1] - length($_[0]))) {
        $Align .= " ";
    }
    
    return $Align;
}

sub checkGraphics()
{
    print "Check graphics ... ";
    my $Glxgears = getGears();
    
    listProbe("tests", "glxgears");
    my $Out_I = runCmd("vblank_mode=0 $Glxgears");
    $Out_I=~s/(\d+ frames)/\n$1/;
    $Out_I=~s/GL_EXTENSIONS =.*?\n//;
    writeLog($TEST_DIR."/glxgears", $Out_I);
    
    my $Out_D = undef;
    
    if(grep {defined $WorkMod{$_}} @G_DRIVERS_INTEL)
    {
        if(defined $WorkMod{"nvidia"})
        { # check NVidia Optimus with proprietary driver
            if(checkCmd("optirun"))
            {
                listProbe("tests", "glxgears (Nvidia)");
                $Out_D = runCmd("optirun $Glxgears");
            }
        }
        elsif(defined $WorkMod{"nouveau"})
        { # check NVidia Optimus with free driver
            listProbe("tests", "glxgears (Nouveau)");
            system("xrandr --setprovideroffloadsink 1 0"); # nouveau Intel
            if($?) {
                printMsg("ERROR", "failed to run glxgears test on discrete card");
            }
            else {
                $Out_D = runCmd("DRI_PRIME=1 vblank_mode=0 $Glxgears");
            }
        }
        elsif(defined $WorkMod{"radeon"} or defined $WorkMod{"amdgpu"})
        { # check Radeon Hybrid graphics with free driver
            listProbe("tests", "glxgears (Radeon)");
            $Out_D = runCmd("DRI_PRIME=1 vblank_mode=0 $Glxgears");
        }
    }
    
    if($Out_D)
    {
        $Out_D=~s/(\d+ frames)/\n$1/;
        $Out_D=~s/GL_EXTENSIONS =.*?\n//;
        writeLog($TEST_DIR."/glxgears_discrete", $Out_D);
    }
    
    checkGraphicsCardOutput($Out_I, $Out_D);
    
    print "Ok\n";
}

sub checkGraphicsCardOutput($$)
{
    my ($Int, $Discrete) = @_;
    
    my $Success = "frames in";
    
    if(grep {defined $WorkMod{$_}} @G_DRIVERS_INTEL)
    {
        if(defined $WorkMod{"nvidia"})
        {
            if($Discrete=~/$Success/) {
                setCardStatus("nvidia", "works");
            }
        }
        elsif(defined $WorkMod{"nouveau"})
        {
            if($Discrete=~/$Success/ and $Discrete=~/GL_VENDOR.+nouveau/i) {
                setCardStatus("nouveau", "works");
            }
        }
        elsif(defined $WorkMod{"radeon"} or defined $WorkMod{"amdgpu"})
        {
            if($Discrete=~/$Success/) {
                setCardStatus("radeon", "works");
            }
        }
        
        if($Int=~/$Success/ and $Int=~/GL_VENDOR.+Intel/i)
        {
            foreach (@G_DRIVERS_INTEL) {
                setCardStatus($_, "works");
            }
        }
    }
    elsif(defined $WorkMod{"nouveau"} or defined $WorkMod{"nvidia"})
    {
        if($Int=~/$Success/) {
            setCardStatus("nouveau", "works");
        }
    }
    elsif(defined $WorkMod{"radeon"} or defined $WorkMod{"amdgpu"} or defined $WorkMod{"fglrx"})
    {
        if($Int=~/$Success/) {
            setCardStatus("radeon", "works");
        }
    }
}

sub setCardStatus($$)
{
    my ($Dr, $Status) = @_;
    
    my $V = $DriverVendor{$Dr};
    
    if(defined $GraphicsCards{$V})
    {
        foreach my $ID (sort keys(%{$GraphicsCards{$V}}))
        {
            if($GraphicsCards{$V}{$ID} eq $Dr or $Status eq "detected")
            {
                $HW{$ID}{"Status"} = $Status;
                
                if($Status eq "works") {
                    setAttachedStatus($ID, $Status);
                }
            }
        }
    }
}

sub checkHW()
{ # TODO: test operability, set status to "works", "malfunc" or "failed"
    if($Opt{"CheckGraphics"} and checkCmd("glxgears"))
    {
        if(defined $ENV{"WAYLAND_DISPLAY"} or $ENV{"XDG_SESSION_TYPE"} eq "wayland" or defined $ENV{"DISPLAY"}) {
            checkGraphics();
        }
    }
    
    if($Opt{"CheckMemory"} and checkCmd("memtester"))
    {
        print "Check memory ... ";
        my $Memtester = runCmd("memtester 8 1");
        $Memtester=~s/\A(.|\n)*(Loop)/$2/g;
        while($Memtester=~s/[^\cH]\cH//g) {}
        writeLog($TEST_DIR."/memtester", $Memtester);
        print "Ok\n";
    }
    
    if($Opt{"CheckHdd"} and checkCmd("hdparm"))
    {
        print "Check HDDs ... ";
        my $HDD_Read = "";
        my $HDD_Num = 0;
        foreach my $Dr (sort keys(%HDD))
        {
            my $Hdd_Info = $HW{$HDD{$Dr}};
            my $Cmd = "hdparm -t $Dr";
            my $Out = runCmd($Cmd);
            $Out=~s/\A\n\Q$Dr\E\:\n//;
            $HDD_Read .= $Hdd_Info->{"Vendor"}." ".$Hdd_Info->{"Device"}."\n";
            $HDD_Read .= "$Cmd\n";
            $HDD_Read .= $Out."\n";
            
            if(defined $Opt{"LimitCheckHdd"}
            and $HDD_Num++>=$Opt{"LimitCheckHdd"})
            {
                last;
            }
        }
        
        if($HDD_Read) {
            writeLog($TEST_DIR."/hdd_read", $HDD_Read);
        }
        print "Ok\n";
    }
    
    if($Opt{"CheckCpu"} and checkCmd("dd") and checkCmd("md5sum"))
    {
        if(my @CPUs = grep { /\Acpu:/ } keys(%HW))
        {
            print "Check CPU ... ";
            my $CPU_Info = $HW{$CPUs[0]};
            runCmd("dd if=/dev/zero bs=1M count=512 2>$TMP_DIR/cpu_perf | md5sum");
            my $CPUPerf = $CPU_Info->{"Vendor"}." ".$CPU_Info->{"Device"}."\n";
            $CPUPerf .= "dd if=/dev/zero bs=1M count=512 | md5sum\n";
            $CPUPerf .= readFile("$TMP_DIR/cpu_perf");
            writeLog($TEST_DIR."/cpu_perf", $CPUPerf);
            print "Ok\n";
        }
    }
}

sub getGears() {
    return "glxgears -info 2>/dev/null & sleep 17 ; killall glxgears 2>/dev/null";
}

sub listProbe($$)
{
    if($Opt{"ListProbes"}) {
        print $_[0]."/".$_[1]."\n";
    }
}

my %EnabledLog = (
    "minimal" => [
        "arcconf",
        "cpuinfo",
        "df",
        "dmesg.1",
        "grub",
        "mcelog",
        "megacli",
        "megactl",
        "meminfo",
        "xorg.log.1"
    ],
    "default" => [
        "acpi",
        "amdconfig",
        "amixer",
        "apk",
        "aplay",
        "arecord",
        "boot.log",
        "boot_efi",
        "cpuid",
        "cpupower",
        "dkms_status",
        "dpkg",
        "efibootmgr",
        "efivar",
        "fdisk",
        "fglrxinfo",
        "gpu-manager.log",
        "grub.cfg",
        "hp-probe",
        "i2cdetect",
        "input_devices",
        "interrupts",
        "inxi",
        "ioports",
        "iostat",
        "iw_list",
        "iwconfig",
        "lsblk",
        "lspnp",
        "modprobe.d",
        "nm-tool",
        "nmcli",
        "nvidia-smi",
        "pkglist",
        "rfkill",
        "rpms",
        "sane-find-scanner",
        "scanimage",
        "scsi",
        "smart-log",
        "systemctl",
        "systemd-analyze",
        "uptime",
        "vainfo",
        "vdpauinfo",
        "vgaswitcheroo",
        "vulkaninfo",
        "xdpyinfo",
        "xinput",
        "xorg.conf"
    ],
    "maximal" => [
        "alsactl",
        "cups_access_log",
        "cups_error_log",
        "findmnt",
        "firmware",
        "fstab",
        "hcitool_scan",
        "iw_scan",
        "modinfo",
        "mount",
        "numactl",
        "route",
        "slabtop",
        "udev-db",
        "update-alternatives",
        "xvinfo"
    ],
    "optional" => [
        "avahi",
        "lsinitrd",
        "pstree",
        "top"
    ]
);

foreach my $LL ("minimal", "default")
{
    foreach my $L (@{$EnabledLog{$LL}}) {
        push(@{$EnabledLog{"maximal"}}, $L);
    }
}

foreach my $L (@{$EnabledLog{"minimal"}}) {
    push(@{$EnabledLog{"default"}}, $L);
}

sub enabledLog($)
{
    my $Name = $_[0];
    
    if(defined $Opt{"Disable"})
    {
        if(grep { $_ eq $Name } split(/,/, $Opt{"Disable"})) {
            return 0;
        }
    }
    
    if(defined $Opt{"Enable"})
    {
        if(grep { $_ eq $Name } split(/,/, $Opt{"Enable"})) {
            return 1;
        }
    }
    
    if(grep { $_ eq $Name } @{$EnabledLog{$Opt{"LogLevel"}}}) {
        return 1;
    }
    
    if(defined $Sys{"System"} and $Sys{"System"}=~/ROSA/i)
    {
        if($Opt{"LogLevel"} eq "default")
        {
            if($Name eq "fstab") {
                return 1;
            }
        }
    }
    
    return 0;
}

sub getMaxLogSize($)
{
    my $Log = $_[0];
    my $MaxSize = 2*$MAX_LOG_SIZE;
    
    if(grep {$Log eq $_} @LARGE_LOGS) {
        $MaxSize = $MAX_LOG_SIZE;
    }
    
    if($Log eq "boot.log") {
        $MaxSize = $MAX_LOG_SIZE/8;
    }
    
    return $MaxSize;
}

sub writeLog($$)
{
    my ($Path, $Content) = @_;
    my $Log = basename($Path);
    
    if(not grep {$Log eq $_} @ProtectedLogs)
    {
        my $MaxSize = getMaxLogSize($Log);
        
        if(length($Content)>$MaxSize)
        {
            if($Log eq "boot.log")
            { # Save end of log
                $Content = substr($Content, -$MaxSize+4);
                $Content=~s/\A.*?\n//;
                $Content = "...\n".$Content;
            }
            else {
                $Content = substr($Content, 0, $MaxSize-3)."...";
            }
        }
    }
    
    writeFile($Path, $Content);
}

sub appendFile($$)
{
    my ($Path, $Content) = @_;
    if(my $Dir = dirname($Path)) {
        mkpath($Dir);
    }
    open(FILE, ">>", $Path) || die ("can't open file \'$Path\': $!\n");
    print FILE $Content;
    close(FILE);
}

sub writeFile($$)
{
    my ($Path, $Content) = @_;
    return if(not $Path);
    if(my $Dir = dirname($Path)) {
        mkpath($Dir);
    }
    open(FILE, ">", $Path) || die ("can't open file \'$Path\': $!\n");
    print FILE $Content;
    close(FILE);
}

sub readPciIds($$$)
{
    my $List = readFile($_[0]);
    
    my $Info = $_[1];
    my $Info_D = $_[2];
    
    my ($V, $D, $SV, $SD, $C, $SC, $SSC) = ();
    
    foreach (split(/\n/, $List))
    {
        if(/\A(\t*)([a-f\d]{4}) /)
        {
            my $L = length($1);
            
            if($L==0)
            {
                $V = $2;
                
                if(/[a-f\d]{4}\s+(.*?)\Z/) {
                    $PciVendor{$V} = $1;
                }
            }
            elsif($L==1)
            {
                $D = $2;
                
                if(/\t[a-f\d]{4}\s+(.*?)\Z/) {
                    $Info->{$V}{$D} = $1;
                }
            }
            elsif($L==2)
            {
                if(/\t([a-f\d]{4}) ([a-f\d]{4})\s+(.*?)\Z/)
                {
                    $SV = $1;
                    $SD = $2;
                    
                    $Info_D->{$V}{$D}{$SV}{$SD} = $3;
                }
            }
        }
        elsif(/\AC ([a-f\d]{2})  (.+)/)
        {
            $C = $1;
            $PciClass{$C} = $2;
            $PciClass{$C."00"} = $2;
        }
        elsif(/\A(\t+)([a-f\d]{2})  (.+)/)
        {
            my $L = length($1);
            if($L==1)
            {
                $SC = $2;
                $PciClass{$C.$SC} = $3;
            }
            elsif($L==2)
            {
                $SSC = $2;
                $PciClass{$C.$SC.$SSC} = $3;
            }
        }
    }
}

sub readUsbIds($$)
{
    my $List = readFile($_[0]);
    
    my $Info = $_[1];
    
    my ($V, $D) = ();
    
    foreach (split(/\n/, $List))
    {
        if(/\A(\t*)([a-f\d]{4}) /)
        {
            my $L = length($1);
            
            if($L==0)
            {
                $V = $2;
                
                if(/[a-f\d]{4}\s+(.*?)\Z/) {
                    $UsbVendor{$V} = $1;
                }
            }
            elsif($L==1)
            {
                $D = $2;
                
                if(/\t[a-f\d]{4}\s+(.*?)\Z/) {
                    $Info->{$V}{$D} = $1;
                }
            }
        }
    }
}

sub readSdioIds_Sys() {
    readSdioIds("/usr/share/hwdata/sdio.ids", \%SdioInfo, \%SdioVendor);
}

sub readSdioIds($$$)
{
    my ($Path, $Info, $Vnds) = @_;

    if(not -e $Path) {
        return;
    }

    my $List = readFile($Path);

    my ($V, $D);

    foreach (split(/\n/, $List))
    {
        if(/\A(\t*)(\w{4}) /)
        {
            my $L = length($1);
            
            if($L==0)
            {
                $V = $2;
                
                if(/\A\w{4}\s+(.*?)\Z/) {
                    $Vnds->{$V} = $1;
                }
            }
            elsif($L==1)
            {
                $D = $2;
                
                if(/\t\w{4}\s+(.*?)\Z/) {
                    $Info->{$V}{$D} = $1;
                }
            }
        }
    }
}

sub downloadProbe($$)
{
    my ($ID, $Dir) = @_;
    
    my $Page = downloadFileContent("$URL/index.php?probe=$ID");
    
    if(index($Page, "ERROR(3):")!=-1) {
        return -1;
    }
    
    if(index($Page, "ERROR(1):")!=-1)
    {
        printMsg("ERROR", "You are not allowed temporarily to download probes");
        rmtree($Dir."/logs");
        exitStatus(1);
    }
    
    if(not $Page)
    {
        printMsg("ERROR", "Internet connection is required");
        exitStatus(1);
    }
    
    print "Importing probe $ID\n";
    
    my %LogDir = ("log"=>$Dir."/logs", "test"=>$Dir."/tests");
    mkpath($LogDir{"log"});
    mkpath($LogDir{"test"});
    
    my $NPage = "";
    foreach my $Line (split(/\n/, $Page))
    {
        if($Line=~/(href|src)=['"]([^"']+?)['"]/)
        {
            my $Url = $2;

            if($Url=~/((css|js|images)\/[^?]+)/)
            {
                my ($SPath, $Subj) = ($1, $2);
                my $Content = downloadFileContent($URL."/".$Url);
                writeFile($Dir."/".$SPath, $Content);
                
                if($Subj eq "css")
                {
                    while($Content=~s{url\(['"]([^'"]+)['"]\)}{})
                    {
                        my $FPath = dirname($SPath)."/".$1;
                        mkpath($Dir."/".dirname($FPath));
                        downloadFile($URL."/".$FPath, $Dir."/".$FPath);
                    }
                }
            }
            elsif($Url=~/(log|test)\=([^&?]+)/)
            {
                my ($LogType, $LogName) = ($1, $2);
                my $LogPath = $LogDir{$LogType}."/".$LogName.".html";
                my $Log = downloadFileContent($URL."/".$Url);
                
                if(index($Log, "ERROR(1):")!=-1)
                {
                    printMsg("ERROR", "You are not allowed temporarily to download probes");
                    rmtree($Dir."/logs");
                    exitStatus(1);
                }

                $Log = preparePage($Log);
                $Log=~s{(['"])(css|js|images)/}{$1../$2/}g;
                $Log=~s{index.php\?probe=$ID}{../index.html};

                writeFile($LogPath, $Log);
                
                my $LogD = basename($LogDir{$LogType});
                $Line=~s/\Q$Url\E/$LogD\/$LogName.html/;
            }
            elsif($Url eq "index.php?probe=$ID") {
                $Line=~s/\Q$Url\E/index.html/;
            }
            else {
                $Line=~s/\Q$Url\E/$URL\/$Url/g;
            }
        }
        
        $NPage .= $Line."\n";
    }
    $NPage=~s&\Q<!-- descr -->\E(.|\n)+\Q<!-- descr end -->\E\n&This probe is available online by <a href=\'$URL/?probe=$ID\'>this URL</a> in the <a href=\'$URL\'>Hardware Database</a>.<p/>&;
    writeFile($Dir."/index.html", preparePage($NPage));
    
    return 0;
}

sub preparePage($)
{
    my $Content = $_[0];
    $Content=~s&\Q<!-- meta -->\E(.|\n)+\Q<!-- meta end -->\E\n&&;
    $Content=~s&\Q<!-- menu -->\E(.|\n)+\Q<!-- menu end -->\E\n&&;
    $Content=~s&\Q<!-- sign -->\E(.|\n)+\Q<!-- sign end -->\E\n&<hr/>\n<div align='right'><a class='sign' href=\'$GITHUB\'>Linux Hardware Project</a></div><br/>\n&;
    return $Content;
}

sub downloadFileContent($)
{
    my $Url = $_[0];
    $Url=~s/&amp;/&/g;
    if(checkCmd("curl"))
    {
        my $Cmd = getCurlCmd($Url);
        return `$Cmd`;
        
    }
    else {
        return getRequest($Url, "NoSSL");
    }
}

sub downloadFile($$)
{
    my ($Url, $Output) = @_;
    $Url=~s/&amp;/&/g;
    if(checkCmd("curl"))
    {
        my $Cmd = getCurlCmd($Url)." --output \"$Output\"";
        return `$Cmd`;
        
    }
    else {
        writeFile($Output, getRequest($Url, "NoSSL"));
    }
}

sub getCurlCmd($)
{
    my $Url = $_[0];
    my $Cmd = "curl -s -L \"$Url\"";
    $Cmd .= " --ipv4 --compressed";
    $Cmd .= " --connect-timeout 5";
    $Cmd .= " --retry 1";
    $Cmd .= " -A \"Mozilla/5.0 (X11; Linux x86_64; rv:50.0) Gecko/20100101 Firefox/50.123\"";
    return $Cmd;
}

sub importProbes($)
{
    my $Dir = $_[0];
    
    if($Opt{"Snap"}) {
        $Dir = $ENV{"SNAP_USER_COMMON"}."/".$Dir;
    }
    elsif($Opt{"Flatpak"}) {
        $Dir = $ENV{"XDG_DATA_HOME"}."/".$Dir;
    }
    
    if(not -d $Dir)
    {
        mkpath($Dir);
        setPublic($Dir);
    }

    my ($Imported, $OneProbe) = (undef, undef);

    my $IndexInfo = eval ( readFile($Dir."/index.info") ) || {};

    my @Paths = ();
    if(-d $PROBE_DIR)
    {
        foreach my $P (listDir($PROBE_DIR)) {
            push(@Paths, $PROBE_DIR."/".$P);
        }
    }
    
    my $OldProbes = getOldProbeDir();
    if($OldProbes and -d $OldProbes)
    { # ROSA: changed probe place in 1.3
        foreach my $P (listDir($OldProbes)) {
            push(@Paths, $OldProbes."/".$P);
        }
    }
    
    foreach my $D (@Paths)
    {
        my $P = basename($D);
        if($P eq "LATEST" or not -d $D or not listDir($D)) {
            next;
        }
        
        if(defined $IndexInfo->{"SkipProbes"}{$P}) {
            next;
        }
        
        my $To = $Dir."/".$P;
        if(not -e $To or not -e "$To/logs")
        {
            if(downloadProbe($P, $To)!=-1)
            {
                my $TmpDir = $TMP_DIR."/hw.info";
                system("tar -xf $D/* -C $TMP_DIR");
                
                my %Prop = ();
                foreach my $Line (split(/\n/, readFile($TmpDir."/host")))
                {
                    if($Line=~/(\w+):(.*)/) {
                        $Prop{$1} = $2;
                    }
                }
                
                my @DStat = stat($TmpDir);
                $Prop{"date"} = $DStat[9]; # last modify time
                $Prop{"hwaddr"} = lc($Prop{"hwaddr"});
                writeFile($To."/probe.info", Data::Dumper::Dumper(\%Prop));
                $Imported = $P;
                setPublic($To, "-R");
                rmtree($TmpDir);
            }
            else {
                $IndexInfo->{"SkipProbes"}{$P} = 1;
            }
        }
    }
    
    writeFile($Dir."/index.info", Data::Dumper::Dumper($IndexInfo));
    setPublic($Dir."/index.info");
    
    if(not $Imported) {
        print "No probes to import\n";
    }
    
    my %Indexed = ();
    foreach my $P (listDir($Dir))
    {
        if(not -d "$Dir/$P") {
            next;
        }
        my $D = $Dir."/".$P;
        my $Prop = eval ( readFile($D."/probe.info") ) || {};
        $Indexed{lc($Prop->{"hwaddr"})}{$P} = $Prop;
        $OneProbe = $P;
    }
    
    if(not $OneProbe) {
        return -1;
    }
    
    my $LIST = "";
    foreach my $HWaddr (sort keys(%Indexed))
    {
        my @Probes = sort {$Indexed{$HWaddr}{$b}->{"date"} cmp $Indexed{$HWaddr}{$a}->{"date"}} keys(%{$Indexed{$HWaddr}});
        my $Hw = $Indexed{$HWaddr}{$Probes[0]};
        my $Title = undef;
        if($Hw->{"vendor"} and $Hw->{"model"}) {
            $Title = join(" ", $Hw->{"vendor"}, $Hw->{"model"});
        }
        elsif($Hw->{"type"})
        {
            if($Hw->{"vendor"}) {
                $Title = $Hw->{"vendor"}." ".ucfirst($Hw->{"type"})." (".getShortHWid($Hw->{"hwaddr"}).")";
            }
            else {
                $Title = ucfirst($Hw->{"type"})." (".getShortHWid($Hw->{"hwaddr"}).")";
            }
        }
        else
        {
            if($Hw->{"vendor"}) {
                $Title = $Hw->{"vendor"}." Computer (".getShortHWid($Hw->{"hwaddr"}).")";
            }
            else {
                $Title = "Computer (".getShortHWid($Hw->{"hwaddr"}).")";
            }
        }
        
        $LIST .= "<h2>$Title</h2>\n";
        $LIST .= "<table class='tbl highlight local_timeline'>\n";
        $LIST .= "<tr>\n";
        $LIST .= "<th>Probe</th><th>Arch</th><th>System</th><th>Date</th><th>Desc</th>\n";
        $LIST .= "</tr>\n";
        foreach my $P (@Probes)
        {
            my $System = $Indexed{$HWaddr}{$P}->{"system"};
            my $SystemClass = $System;
            if($System=~s/\A(\w+)-/$1 /) {
                $SystemClass = $1;
            }
            
            $LIST .= "<tr class='pointer' onclick=\"document.location='$P/index.html'\">\n";
            
            $LIST .= "<td>\n";
            $LIST .= "<a href='$P/index.html'>$P</a>\n";
            $LIST .= "</td>\n";
            
            $LIST .= "<td>\n";
            $LIST .= $Indexed{$HWaddr}{$P}->{"arch"};
            $LIST .= "</td>\n";
            
            $LIST .= "<td>\n";
            $LIST .= "<span class=\'$SystemClass\'>&nbsp;</span> ".ucfirst($System);
            $LIST .= "</td>\n";
            
            $LIST .= "<td title='".getTimeStamp($Indexed{$HWaddr}{$P}->{"date"})."'>\n";
            $LIST .= getDateStamp($Indexed{$HWaddr}{$P}->{"date"});
            $LIST .= "</td>\n";
            
            $LIST .= "<td>\n";
            $LIST .= $Indexed{$HWaddr}{$P}->{"id"};
            $LIST .= "</td>\n";
            
            $LIST .= "</tr>\n";
        }
        $LIST .= "</table>\n";
        $LIST .= "<br/>\n";
    }
    
    my $Descr = "This is your collection of probes. See more probes and computers online in the <a href=\'$URL\'>Hardware Database</a>.";
    my $INDEX = readFile($Dir."/".$OneProbe."/index.html");
    $INDEX=~s{\Q<!-- body -->\E(.|\n)+\Q<!-- body end -->\E\n}{<h1>Probes Timeline</h1>\n$Descr\n$LIST\n};
    $INDEX=~s{(\Q<title>\E)(.|\n)+(\Q</title>\E)}{$1 Probes Timeline $3};
    $INDEX=~s{(['"])(css|js|images)/}{$1$OneProbe/$2/}g;

    writeFile($Dir."/index.html", $INDEX);
    setPublic($Dir."/index.html");
    
    print "Created index: $Dir/index.html\n";
}

sub getShortHWid($)
{
    my $HWid = $_[0];
    if(length($HWid) eq $HASH_LEN_CLIENT) {
        $HWid = substr($HWid, 0, 5);
    }
    else {
        $HWid=~s/\A(\w+\-\w+).+\-(\w+)\Z/$1...$2/;
    }
    return $HWid;
}

sub getDateStamp($)
{
    my $Date = localtime($_[0]);
    if($Date=~/\w+ (\w+ \d+) \d+:\d+:\d+ (\d+)/) {
        return "$1, $2";
    }
    return $Date;
}

sub getTimeStamp($)
{
    my $Date = localtime($_[0]);
    if($Date=~/\w+ \w+ \d+ (\d+:\d+):\d+ \d+/) {
        return $1;
    }
    return $Date;
}

sub setPublic(@)
{
    my $Path = shift(@_);
    my $R = undef;
    if(@_) {
        $R = shift(@_);
    }
    
    if(not checkCmd("chmod")) {
        return;
    }
    
    my @Chmod = ("chmod", "777");
    if($R) {
        push(@Chmod, $R);
    }
    push(@Chmod, $Path);
    system(@Chmod);
    
    if(not $Opt{"Snap"} and not $Opt{"Flatpak"})
    {
        if(my $SessUser = getUser())
        {
            my @Chown = ("chown", $SessUser.":".$SessUser);
            if($R) {
                push(@Chown, $R);
            }
            push(@Chown, $Path);
            system(@Chown);
        }
    }
}

sub fixLsUsb($)
{
    my $Content = $_[0];
    my @Content_New = ();
    
    foreach my $Block (split(/\n\n/, $Content))
    {
        if($Block=~/: ID (\w{4}):(\w{4})/)
        {
            my ($V, $D) = ($1, $2);
            if(defined $UsbVendor{$V})
            {
                my $Vendor = $UsbVendor{$V};
                
                if(defined $UsbInfo{$V}{$D})
                {
                    my $Product = $UsbInfo{$V}{$D};
                    
                    $Block=~s{(:\s+ID\s+$V:$D)[ ]+\n}{$1 $Vendor $Product\n};
                    $Block=~s{(idVendor\s+0x$V)[ ]+\n}{$1 $Vendor\n};
                    $Block=~s{(idProduct\s+0x$D)[ ]+\n}{$1 $Product\n};
                }
            }
        }
        push(@Content_New, $Block);
    }
    
    return join("\n\n", @Content_New);
}

sub fixLsPci_All($)
{
    my $Content = $_[0];
    my @Content_New = ();
    
    foreach my $Block (split(/\n\n/, $Content))
    {
        if($Block=~/ Class \[([a-f\d]+)\]: Device \[(\w{4}):(\w{4})\]/)
        {
            my ($C, $V, $D) = ($1, $2, $3);
            
            if(defined $PciVendor{$V})
            {
                my $Vendor = $PciVendor{$V};
                
                if(defined $PciInfo{$V}{$D})
                {
                    my $Product = $PciInfo{$V}{$D};
                    $Block=~s{(\]:) Device (\[$V:$D\])}{$1 $Vendor $Product $2};
                    
                    if($Block=~/Subsystem: Device \[(\w{4}):(\w{4})\]/)
                    {
                        my ($SV, $SD) = ($1, $2);
                        if(my $SubVendor = $PciVendor{$SV})
                        {
                            my $Subsystem = "Device";
                            if(defined $PciInfo_D{$V}{$D}{$SV}{$SD}) {
                                $Subsystem = $PciInfo_D{$V}{$D}{$SV}{$SD};
                            }
                            elsif($V eq $SV and $D eq $SD) {
                                $Subsystem = $Product;
                            }
                            
                            $Block=~s{(Subsystem:) Device (\[$SV:$SD\])}{$1 $SubVendor $Subsystem $2};
                        }
                    }
                }
            }
            
            if(defined $PciClass{$C})
            {
                my $Class = $PciClass{$C};
                $Block=~s{ Class (\[$C\]:)}{ $Class $1};
            }
        }
        
        push(@Content_New, $Block);
    }
    
    return join("\n\n", @Content_New);
}

sub fixLsPci($)
{
    my $Content = $_[0];
    my @Content_New = ();
    
    my %Dev = ();
    
    foreach my $Block (split(/\n\n/, $Content))
    {
        foreach my $Attr ("Class", "Vendor", "Device", "SVendor", "SDevice")
        {
            if($Block=~/$Attr:.*\[([a-f\d]{4})\]/) {
                $Dev{$Attr} = $1;
            }
        }
        
        my $C = $Dev{"Class"};
        
        if(defined $PciClass{$C})
        {
            my $Class = $PciClass{$C};
            $Block=~s{(Class:\s+)Class(\s+\[$C\])}{$1$Class$2};
        }
        
        my ($V, $D) = ($Dev{"Vendor"}, $Dev{"Device"});
        
        if(defined $PciVendor{$V})
        {
            my $Vendor = $PciVendor{$V};
            $Block=~s{(Vendor:\s+)Vendor(\s+\[$V\])}{$1$Vendor$2};
            
            if(defined $PciInfo{$V}{$D})
            {
                my $Product = $PciInfo{$V}{$D};
                $Block=~s{(Device:\s+)Device(\s+\[$D\])}{$1$Product$2};
                
                my ($SV, $SD) = ($Dev{"SVendor"}, $Dev{"SDevice"});
                
                if(my $SubVendor = $PciVendor{$SV})
                {
                    $Block=~s{(SVendor:\s+)Unknown vendor(\s+\[$SV\])}{$1$SubVendor$2};
                    
                    my $Subsystem = undef;
                    if(defined $PciInfo_D{$V}{$D}{$SV}{$SD}) {
                        $Subsystem = $PciInfo_D{$V}{$D}{$SV}{$SD};
                        
                    }
                    elsif($V eq $SV and $D eq $SD) {
                        $Subsystem = $Product;
                    }
                    
                    if($Subsystem) {
                        $Block=~s{(SDevice:\s+)Device(\s+\[$SD\])}{$1$Subsystem$2};
                    }
                }
            }
        }
        
        push(@Content_New, $Block);
    }
    
    return join("\n\n", @Content_New);
}

sub fixLogs($)
{
    my $Dir = $_[0];

    if(-f "$Dir/hwinfo"
    and -s "$Dir/hwinfo" < 2*$EMPTY_LOG_SIZE)
    { # Support for HW Probe 1.4
        if(readFile("$Dir/hwinfo")=~/unrecognized arguments|error while loading shared libraries/)
        { # hwinfo: error: unrecognized arguments: --all
          # hwinfo: error while loading shared libraries: libhd.so.21: cannot open shared object file: No such file or directory
            writeFile("$Dir/hwinfo", "");
        }
    }

    if(-f "$Dir/iostat"
    and -s "$Dir/iostat" < 50)
    { # Support for HW Probe 1.3
      # iostat: command not found
        unlink($Dir."/iostat");
    }

    foreach my $L ("glxinfo", "xdpyinfo", "xinput", "vdpauinfo", "xrandr")
    {
        if(-e "$Dir/$L"
        and -s "$Dir/$L" < $EMPTY_LOG_SIZE)
        {
            if(not clearLog_X11(readFile("$Dir/$L"))) {
                writeFile("$Dir/$L", "");
            }
        }
    }

    if(-f "$Dir/vulkaninfo")
    { # Support for HW Probe 1.3
        if(readFile("$Dir/vulkaninfo")=~/Cannot create/i) {
            unlink("$Dir/vulkaninfo");
        }
    }

    if(-f "$Dir/vainfo"
    and -s "$Dir/vainfo" < $EMPTY_LOG_SIZE)
    { # Support for HW Probe 1.4
      # error: failed to initialize display
        if(readFile("$Dir/vainfo")=~/failed to initialize/) {
            writeFile("$Dir/vainfo", "");
        }
    }

    if(-f "$Dir/cpupower"
    and -s "$Dir/cpupower" < $EMPTY_LOG_SIZE)
    { # Support for HW Probe 1.3
        if(readFile("$Dir/cpupower")=~/cpupower not found/) {
            unlink("$Dir/cpupower");
        }
    }

    if(-f "$Dir/rfkill"
    and -s "$Dir/rfkill" < 70)
    { # Support for HW Probe 1.4
      # Can't open RFKILL control device: No such file or directory
        if(readFile("$Dir/rfkill")=~/No such file or directory/) {
            writeFile("$Dir/rfkill", "");
        }
    }

    foreach my $L ("aplay", "arecord")
    {
        if(-e "$Dir/$L"
        and -s "$Dir/$L" < 50)
        {
            if(readFile("$Dir/$L")=~/command not found/) {
                writeFile("$Dir/$L", "");
            }
        }
    }

    foreach my $L ("lsusb", "usb-devices", "lspci", "lspci_all", "dmidecode")
    {
        if(-f "$Dir/$L"
        and -s "$Dir/$L" < 2*$EMPTY_LOG_SIZE)
        { # Support for HW Probe 1.4
          # sh: XXX: command not found
          # pcilib: Cannot open /proc/bus/pci
          # lspci: Cannot find any working access method.
          # lsusb: error while loading shared libraries: libusb-1.0.so.0: cannot open shared object file: No such file or directory
          # ERROR: ld.so: object '/usr/lib/arm-linux-gnueabihf/libarmmem.so' from /etc/ld.so.preload cannot be preloaded
          # /dev/mem: Permission denied
          # dmidecode: command not found
          # No SMBIOS nor DMI entry point found
            writeFile("$Dir/$L", "");
        }
    }
    
    foreach my $L ("pstree")
    { # Support for HW Probe 1.4
        if(-f "$Dir/$L"
        and -s "$Dir/$L" < $EMPTY_LOG_SIZE)
        { # sh: XXX: command not found
          # lsblk: Permission denied
            writeFile("$Dir/$L", "");
        }
    }
    
    foreach my $L ("efibootmgr", "lsblk")
    { # Support for HW Probe 1.4
        if(-f "$Dir/$L"
        and -s "$Dir/$L" < $EMPTY_LOG_SIZE/2) {
            writeFile("$Dir/$L", "");
        }
    }
    
    foreach my $L ("lsusb", "usb-devices", "lspci", "lspci_all", "dmidecode", "hwinfo")
    { # Support for old probes
        if(-e "$Dir/$L")
        {
            my $Content = readFile("$Dir/$L");
            
            if($L eq "lsusb")
            {
                if(index($Content, "Resource temporarily unavailable")!=-1)
                {
                    $Content=~s/can't get device qualifier: Resource temporarily unavailable\n//g;
                    $Content=~s/cannot read device status, Resource temporarily unavailable \(11\)\n//g;
                    $Content=~s/can't get debug descriptor: Resource temporarily unavailable\n//g;
                    writeFile("$Dir/$L", $Content);
                }
                
                if(index($Content, "some information will be missing")!=-1)
                {
                    $Content=~s/Couldn't open device, some information will be missing\n//g;
                    $Content=~s/Couldn't get configuration descriptor 0, some information will be missing\n//g;
                    writeFile("$Dir/$L", $Content);
                }
                
                if($Opt{"UsbIDs"})
                {
                    if(index($Content, "HW_PROBE_USB_")!=-1 or $Content=~/: ID [a-f\d]{4}:[a-f\d]{4}  \n/)
                    {
                        $Content=~s{lsusb: cannot open "/tmp/HW_PROBE_USB_", Permission denied\n\n}{}g;
                        if($Opt{"UsbIDs"}) {
                            $Content = fixLsUsb($Content);
                        }
                        writeFile("$Dir/$L", $Content);
                    }
                }
            }
            elsif($L eq "lspci" or $L eq "lspci_all")
            {
                if(index($Content, "lspci: Unable to load libkmod resources: error -12")!=-1)
                {
                    $Content=~s/lspci: Unable to load libkmod resources: error -12\n//g;
                    writeFile("$Dir/$L", $Content);
                }
                
                if($Opt{"PciIDs"})
                {
                    if($L eq "lspci" and index($Content, "Class:\tClass [")!=-1) {
                        writeFile("$Dir/$L", fixLsPci($Content));
                    }
                    
                    if($L eq "lspci_all" and index($Content, "]: Device [")!=-1) {
                        writeFile("$Dir/$L", fixLsPci_All($Content));
                    }
                }
            }
            elsif($L eq "dmidecode")
            {
                if(index($Content, "Table is unreachable, sorry")!=-1)
                {
                    $Content=~s{/dev/mem: Bad address\nTable is unreachable, sorry.\n}{}g;
                    $Content=~s{/dev/mem: lseek: Value too large for defined data type\nTable is unreachable, sorry.\n}{}g;
                    writeFile("$Dir/$L", $Content);
                }
            }
            elsif($L eq "hwinfo")
            {
                if(index($Content, "sh: /dev/null: Permission denied")!=-1)
                {
                    $Content=~s{sh: /dev/null: Permission denied\n}{}g;
                    writeFile("$Dir/$L", $Content);
                }
            }
            
            if(index($Content, "ERROR: ld.so:")!=-1)
            { # ERROR: ld.so: object '/usr/lib/arm-linux-gnueabihf/libarmmem.so' from /etc/ld.so.preload cannot be preloaded (cannot open shared object file): ignored.
              # ERROR: ld.so: object 'libesets_pac.so' from /etc/ld.so.preload cannot be preloaded (cannot open shared object file): ignored.
                $Content=~s/ERROR: ld\.so:.+?: ignored\.\n//g;
                writeFile("$Dir/$L", $Content);
            }
        }
    }

    if(-e "$Dir/inxi"
    and -s "$Dir/inxi" < $EMPTY_LOG_SIZE)
    { # Support for HW Probe 1.4
        if(readFile("$Dir/inxi")=~/Unsupported option/) {
            writeFile("$Dir/inxi", "");
        }
    }
    
    foreach my $L (@LARGE_LOGS)
    {
        if(-s "$FixProbe_Logs/$L" > getMaxLogSize($L))
        {
            if(my $Content = readFile("$FixProbe_Logs/$L")) {
                writeLog("$FixProbe_Logs/$L", $Content);
            }
        }
    }
    
    if($Sys{"Probe_ver"} eq "1.4" or not $Sys{"Probe_ver"})
    { # HW Probe <= 1.4
        if(-e "$FixProbe_Logs/boot.log"
        and my $Content = readFile("$FixProbe_Logs/boot.log")) {
            writeLog("$FixProbe_Logs/boot.log", clearLog($Content));
        }
        
        if(-e "$FixProbe_Logs/rpms"
        and my $Content = readFile("$FixProbe_Logs/rpms"))
        {
            my @Rpms = sort { "\L$a" cmp "\L$b" } split(/\n/, $Content);
            writeLog("$FixProbe_Logs/rpms", join("\n", @Rpms));
        }
        
        if(-f "$Dir/mcelog")
        {
            if(readFile("$Dir/mcelog")=~/No such file or directory/) {
                writeFile("$Dir/mcelog", "");
            }
        }
    }
}

sub createIDsLink($)
{
    my $Type = $_[0];
    my $Type_U = uc($Type);
    
    my $Link = "/tmp/HW_PROBE_".$Type_U."_";
    if($Opt{"Flatpak"}) {
        $Link = "/var/tmp/P_".$Type_U;
    }
    
    if(-e $Link) {
        return undef;
    }
    
    if($Opt{"Snap"})
    {
        if(my $SNAP_Dir = $ENV{"SNAP"})
        {
            symlink("$SNAP_Dir/usr/share/$Type.ids", $Link);
            return $Link;
        }
    }
    elsif($Opt{"Flatpak"})
    {
        symlink("/app/share/$Type.ids", $Link);
        return $Link;
    }
    
    return undef;
}

sub scenario()
{
    if($Opt{"Help"})
    {
        print $HelpMessage;
        exitStatus(0);
    }
    
    if($Opt{"DumpVersion"})
    {
        print $TOOL_VERSION."\n";
        exitStatus(0);
    }
    
    if($Opt{"ShowVersion"})
    {
        print $ShortUsage;
        exitStatus(0);
    }
    
    if(checkModule("Digest/SHA.pm"))
    {
        $USE_DIGEST = 1;
        require Digest::SHA;
    }
    
    if(checkModule("Data/Dumper.pm"))
    {
        $USE_DUMPER = 1;
        require Data::Dumper;
        $Data::Dumper::Sortkeys = 1;
    }
    
    if($Opt{"DecodeACPI"}) {
        $Opt{"DumpACPI"} = 1;
    }
    
    if(not $Opt{"Compact"}) {
        $Opt{"Compact"} = 1;
    }
    
    if($Opt{"Show"}) {
        $Opt{"ShowDevices"} = 1;
    }
    
    if($Opt{"Maximal"}) {
        $Opt{"LogLevel"} = "maximal";
    }
    
    if($Opt{"Minimal"}) {
        $Opt{"LogLevel"} = "minimal";
    }
    
    if($Opt{"LogLevel"})
    {
        if($Opt{"LogLevel"}=~/\A(min|mini|minimum)\Z/i) {
            $Opt{"LogLevel"} = "minimal";
        }
        elsif($Opt{"LogLevel"}=~/\A(max|maxi|maximum)\Z/i) {
            $Opt{"LogLevel"} = "maximal";
        }
        
        if($Opt{"LogLevel"}!~/\A(minimal|default|maximal)\Z/i)
        {
            printMsg("ERROR", "unknown log level '".$Opt{"LogLevel"}."'");
            exitStatus(1);
        }
        
        $Opt{"LogLevel"} = lc($Opt{"LogLevel"});
        $Opt{"Logs"} = 1;
    }
    else {
        $Opt{"LogLevel"} = "default";
    }
    
    foreach my $LogStatus ("Enable", "Disable")
    {
        if(not defined $Opt{$LogStatus}) {
            next;
        }
        
        foreach my $L (split(/,/, $Opt{$LogStatus}))
        {
            if(not grep { $_ eq $L } @{$EnabledLog{"minimal"}}
            and not grep { $_ eq $L } @{$EnabledLog{"default"}}
            and not grep { $_ eq $L } @{$EnabledLog{"maximal"}}
            and not grep { $_ eq $L } @{$EnabledLog{"optional"}})
            {
                printMsg("ERROR", "logging of \'$L\' cannot be enabled or disabled");
                exitStatus(1);
            }
        }
    }
    
    if($Opt{"HWInfoPath"})
    {
        if(not -f $Opt{"HWInfoPath"})
        {
            printMsg("ERROR", "can't access file '".$Opt{"HWInfoPath"}."'");
            exitStatus(1);
        }
    }
    
    if($Opt{"IdentifyDrive"} or $Opt{"IdentifyMonitor"})
    {
        if(not $USE_DUMPER)
        {
            printMsg("ERROR", "requires perl-Data-Dumper module");
            exitStatus(1);
        }
    }
    
    if($Opt{"IdentifyDrive"})
    {
        if(not -f $Opt{"IdentifyDrive"})
        {
            printMsg("ERROR", "can't access file '".$Opt{"IdentifyDrive"}."'");
            exitStatus(1);
        }
        
        my $DriveDesc = readFile($Opt{"IdentifyDrive"});
        my $DriveDev = "";
        
        if($DriveDesc=~/\A(.+)\n/) {
            $DriveDev = $1;
        }
        
        detectDrive($DriveDesc, $DriveDev);
        print Data::Dumper::Dumper(\%HW);
        exitStatus(0);
    }
    
    if($Opt{"IdentifyMonitor"})
    {
        if(not -f $Opt{"IdentifyMonitor"})
        {
            printMsg("ERROR", "can't access file '".$Opt{"IdentifyMonitor"}."'");
            exitStatus(1);
        }
        
        detectMonitor(readFile($Opt{"IdentifyMonitor"}));
        print Data::Dumper::Dumper(\%HW);
        exitStatus(0);
    }
    
    if($Opt{"DecodeACPI_From"} and $Opt{"DecodeACPI_To"})
    {
        if(not -f $Opt{"DecodeACPI_From"})
        {
            printMsg("ERROR", "can't access file '".$Opt{"DecodeACPI_From"}."'");
            exitStatus(1);
        }
        decodeACPI($Opt{"DecodeACPI_From"}, $Opt{"DecodeACPI_To"});
        exitStatus(0);
    }
    
    if($Opt{"Logs"}) {
        $Opt{"Probe"} = 1;
    }
    
    if($Opt{"All"})
    {
        $Opt{"Probe"} = 1;
        $Opt{"Logs"} = 1;
    }
    
    if($Opt{"Check"})
    {
        $Opt{"Probe"} = 1;
        $Opt{"Logs"} = 1;
    }
    
    if($Opt{"Probe"}) {
        $Opt{"HWLogs"} = 1;
    }
    
    if($Opt{"Probe"} and not $Opt{"FixProbe"})
    {
        if(-d $DATA_DIR)
        {
            if(not -w $DATA_DIR)
            {
                printMsg("ERROR", "can't write to '".$DATA_DIR."', please run as root");
                exitStatus(1);
            }
            rmtree($DATA_DIR);
        }
    }
    
    if($Opt{"Probe"})
    {
        if(not $Admin
        and not $SNAP_DESKTOP and not $FLATPAK_DESKTOP)
        {
            printMsg("ERROR", "you should run as root (sudo or su)");
            exitStatus(1);
        }
    }
    
    if($Opt{"FixProbe"})
    {
        $Opt{"Probe"} = 0;
        $Opt{"HWLogs"} = 0;
        $Opt{"Logs"} = 0;
    }
    
    if($Opt{"Check"})
    {
        $Opt{"CheckGraphics"} = 1;
        $Opt{"CheckMemory"} = 1;
        $Opt{"CheckHdd"} = 1;
        $Opt{"CheckCpu"} = 1;
    }
    
    if($Opt{"CheckGraphics"} or $Opt{"CheckMemory"}
    or $Opt{"CheckHdd"} or $Opt{"CheckCpu"})
    {
        $Opt{"Check"} = 1;
        $Opt{"Logs"} = 1;
    }
    
    if(my $PciIDs = $Opt{"PciIDs"})
    {
        if(not -e $PciIDs)
        {
            printMsg("ERROR", "can't access '".$PciIDs."'");
            exitStatus(1);
        }
        readPciIds($PciIDs, \%PciInfo, \%PciInfo_D);

        if(-e "$PciIDs.add") {
            readPciIds("$PciIDs.add", \%AddPciInfo, \%AddPciInfo_D);
        }
    }
    
    if(my $UsbIDs = $Opt{"UsbIDs"})
    {
        if(not -e $UsbIDs)
        {
            printMsg("ERROR", "can't access '".$UsbIDs."'");
            exitStatus(1);
        }
        readUsbIds($UsbIDs, \%UsbInfo);

        if(-e "$UsbIDs.add") {
            readUsbIds("$UsbIDs.add", \%AddUsbInfo);
        }
    }
    
    if(my $SdioIDs = $Opt{"SdioIDs"})
    {
        if(not -e $SdioIDs)
        {
            printMsg("ERROR", "can't access '".$SdioIDs."'");
            exitStatus(1);
        }
        readSdioIds($SdioIDs, \%SdioInfo, \%SdioVendor);

        if(-e "$SdioIDs.add") {
            readSdioIds("$SdioIDs.add", \%AddSdioInfo, \%AddSdioVendor);
        }
    }
    
    if($Opt{"PnpIDs"})
    {
        if(not -e $Opt{"PnpIDs"})
        {
            printMsg("ERROR", "can't access '".$Opt{"PnpIDs"}."'");
            exitStatus(1);
        }
    }
    
    if($Opt{"FixProbe"})
    {
        if(not -e $Opt{"FixProbe"})
        {
            printMsg("ERROR", "can't access '".$Opt{"FixProbe"}."'");
            exitStatus(1);
        }
        
        if(isPkg($Opt{"FixProbe"}))
        { # package
            my $PName = basename($Opt{"FixProbe"});
            $FixProbe_Pkg = abs_path($Opt{"FixProbe"});
            $Opt{"FixProbe"} = $FixProbe_Pkg;
            
            copy($Opt{"FixProbe"}, $TMP_DIR."/".$PName);
            chdir($TMP_DIR);
            system("tar", "-m", "-xf", $PName);
            chdir($ORIG_DIR);
            
            $Opt{"FixProbe"} = $TMP_DIR."/hw.info";
        }
        elsif(-f $Opt{"FixProbe"})
        {
            printMsg("ERROR", "unsupported probe format '".$Opt{"FixProbe"}."'");
            exitStatus(1);
        }
        
        $Opt{"FixProbe"}=~s/[\/]+\Z//g;
        $FixProbe_Logs = $Opt{"FixProbe"}."/logs";
        $FixProbe_Tests = $Opt{"FixProbe"}."/tests";
        
        if(-d $Opt{"FixProbe"})
        {
            if(not listDir($FixProbe_Logs))
            {
                printMsg("ERROR", "can't find logs in '".$Opt{"FixProbe"}."'");
                exitStatus(1);
            }
        }
        else
        {
            printMsg("ERROR", "can't access '".$Opt{"FixProbe"}."'");
            exitStatus(1);
        }

        if(-f "$FixProbe_Logs/media_urls")
        { # support for old probes
            foreach my $File ("journalctl", "journalctl.1", "lib_modules",
            "ld.so.cache", "sys_module", "media_active", "media_urls",
            "lspcidrake", "lpstat", "lpinfo", "systemctl_status",
            "ps", "cups_access_log", "cups_error_log", "sane-find-scanner",
            "scanimage", "codec", "sys_class", "lsinitrd", "xmodmap",
            "avahi", "dmesg.old", "asound_modules", "syslog", "lib",
            "parted", "gdisk")
            {
                unlink($FixProbe_Logs."/".$File);
            }
            
            my $Udevadm = $FixProbe_Logs."/udevadm";
            
            if(-f $Udevadm)
            {
                if(readFile($Udevadm)!~/sdio/i) {
                    unlink($Udevadm);
                }
            }
        }

        if(my $RmLog = $Opt{"RmLog"})
        {
            if(-f "$FixProbe_Logs/$RmLog"
            and not grep {$RmLog eq $_} @ProtectedLogs
            and not grep {$RmLog eq $_} @ProtectFromRm) {
                writeFile("$FixProbe_Logs/$RmLog", "");
            }
        }

        if(my $TrLog = $Opt{"TruncateLog"})
        {
            if(-f "$FixProbe_Logs/$TrLog"
            and not grep {$TrLog eq $_} @ProtectedLogs)
            {
                if(my $Content = readFile("$FixProbe_Logs/$TrLog")) {
                    writeLog("$FixProbe_Logs/$TrLog", $Content);
                }
            }
        }
        
        $Opt{"Logs"} = 0;
    }
    
    if($Opt{"Save"})
    {
        if(not -d $Opt{"Save"})
        {
            printMsg("ERROR", "please create directory first");
            exitStatus(1);
        }
    }
    
    if($Opt{"Upload"})
    {
        if(not checkCmd("curl"))
        {
            if(not $Opt{"Snap"} and not $Opt{"Flatpak"}) {
                printMsg("WARNING", "'curl' package is not installed");
            }
        }
    }
    
    if($Opt{"Probe"} or $Opt{"Check"})
    {
        probeSys();
        probeDmi();
        probeHWaddr();
        probeHW();
        
        writeDevs();
        writeHost();
        
        if($Opt{"Logs"}) {
            writeLogs();
        }
        
        if($Opt{"Check"})
        {
            checkHW();
            
            # Update
            writeDevs();
        }
        
        if($Opt{"Key"}) {
            writeFile($DATA_DIR."/key", $Opt{"Key"});
        }
        
        if(not $Opt{"Upload"} and not $Opt{"Show"} and not $Opt{"ShowDevices"}) {
            print "Local probe path: $DATA_DIR\n";
        }
    }
    elsif($Opt{"FixProbe"})
    {
        readHost($Opt{"FixProbe"}); # instead of probeSys
        fixLogs($FixProbe_Logs);
        
        fixProduct();
        fixChassis();
        probeHWaddr();
        probeHW();
        
        checkGraphicsCardOutput(readFile($FixProbe_Tests."/glxgears"), readFile($FixProbe_Tests."/glxgears_discrete"));
        
        if($Opt{"PC_Name"}) {
            $Sys{"Name"} = $Opt{"PC_Name"}; # fix PC name
        }
        
        my ($Distr, $Rel) = probeDistr();
        
        if(not $Distr)
        {
            if(-f "$FixProbe_Logs/issue")
            { # Support for old HW Probe
                my $Issue = readLine("$FixProbe_Logs/issue");
                if($Issue=~/ROSA Enterprise Linux Server release ([\d\.]+)/i) {
                    $Distr = "rels-".$1;
                }
            }
        }
        
        if(not $Distr or grep {$Distr eq $_} ("virtuozzo-7"))
        { # Support for old HW Probe
            if(-f "$FixProbe_Logs/rpms")
            {
                my $Rpm = readLine("$FixProbe_Logs/rpms");
                if($Rpm=~/\.([a-z]\w+)\.\w+\Z/i)
                {
                    if(defined $DistSuffix{$1}) {
                        $Distr = $DistSuffix{$1};
                    }
                }
            }
        }
        
        if($Distr)
        { # fix system name
            $Sys{"System"} = $Distr;
        }
        
        if($Rel)
        { # fix system name
            $Sys{"Systemrel"} = $Rel;
        }
        
        if($Sys{"Kernel"}=~/\drosa\b/)
        {
            if(not $Sys{"System"})
            {
                if($Sys{"Kernel"}=~/\A3\.0\./) {
                    $Sys{"System"} = "rosa-2012lts";
                }
                elsif($Sys{"Kernel"}=~/\A3\.(8|10)\./) {
                    $Sys{"System"} = "rosa-2012.1";
                }
                elsif($Sys{"Kernel"}=~/\A3\.(14|17|18|19)\./) {
                    $Sys{"System"} = "rosa-2014.1";
                }
                elsif($Sys{"Kernel"}=~/\A4\./) {
                    $Sys{"System"} = "rosa-2014.1";
                }
                else
                {
                    printMsg("ERROR", "failed to fix 'system' attribute (kernel is '".$Sys{"Kernel"}."')");
                }
            }
            
            if(not $Sys{"Systemrel"})
            {
                if($Sys{"System"} eq "rosa-2012.1")
                {
                    if($Sys{"Kernel"}=~/\A3\.10\.(3\d|4\d)\-/) {
                        $Sys{"Systemrel"} = "rosafresh-r3";
                    }
                    elsif($Sys{"Kernel"}=~/\A3\.10\.19\-/) {
                        $Sys{"Systemrel"} = "rosafresh-r2";
                    }
                    elsif($Sys{"Kernel"}=~/\A3\.8\.12\-/) {
                        $Sys{"Systemrel"} = "rosafresh-r1";
                    }
                }
            }
        }
        
        $Sys{"Vendor"} = fixVendor($Sys{"Vendor"});
        $Sys{"Model"} = fixModel($Sys{"Vendor"}, $Sys{"Model"}, $Sys{"Version"});
        
        if($Opt{"DecodeACPI"})
        {
            if(-s "$FixProbe_Logs/acpidump")
            {
                if(decodeACPI("$FixProbe_Logs/acpidump", "$FixProbe_Logs/acpidump_decoded")) {
                    unlink("$FixProbe_Logs/acpidump");
                }
            }
        }

        if(-s "$FixProbe_Logs/acpidump"
        and -s "$FixProbe_Logs/acpidump_decoded") {
            unlink("$FixProbe_Logs/acpidump");
        }
        
        writeDevs();
        writeHost();
        
        if($FixProbe_Pkg)
        { # package
            my $PName = basename($FixProbe_Pkg);
            chdir($TMP_DIR);
            
            my $Compress = "";
            
            if($PName=~/gz\Z/) {
                $Compress .= "tar -czf ".$PName." hw.info";
            }
            else
            { # XZ
                if($Opt{"LowCompress"})
                { # low CPU/RAM, high SPACE
                    $Compress .= "XZ_OPT=-0 ";
                    
                    # high CPU, low RAM/SPACE
                    # $Compress .= "XZ_OPT='--memlimit=15MiB' ";
                }
                elsif($Opt{"HighCompress"})
                { # high CPU/RAM, low SPACE
                    $Compress .= "XZ_OPT=-9 ";
                }
                else {
                    # default is -9
                }
                $Compress .= "tar -cJf ".$PName." hw.info";
            }
            
            qx/$Compress/;
            
            if($?)
            {
                printMsg("ERROR", "can't create a package");
                chdir($ORIG_DIR);
                exitStatus(1);
            }
            
            move($PName, $FixProbe_Pkg);
            chdir($ORIG_DIR);
            
            rmtree($TMP_DIR."/hw.info");
        }
    }
    
    if($Admin and $Opt{"Flatpak"})
    { # Allow to mix root and non-root runs
        setPublic($PROBE_DIR, "-R");
    }
    
    if($Opt{"Show"} or $Opt{"ShowDevices"}) {
        showInfo();
    }
    
    if($Opt{"Upload"})
    {
        uploadData();
        cleanData();
    }
    elsif($Opt{"Save"}) {
        saveProbe($Opt{"Save"});
    }
    
    if($Opt{"GetGroup"}) {
        getGroup();
    }
    
    if($Opt{"ImportProbes"})
    {
        if(not $Admin)
        {
            printMsg("ERROR", "you should run as root (sudo or su)");
            exitStatus(1);
        }
        
        if(not $USE_DUMPER)
        {
            printMsg("ERROR", "requires perl-Data-Dumper module");
            exitStatus(1);
        }
        
        importProbes($Opt{"ImportProbes"});
    }
    
    exitStatus(0);
}

scenario();
