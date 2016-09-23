#!/usr/bin/perl
#########################################################################
# Hardware Probe Tool 1.1
# A tool to probe for hardware and upload result to the Linux Hardware DB
#
# WWW: https://linux-hardware.org
#
# Copyright (C) 2014-2016 Andrey Ponomarenko's Linux Hardware Project
#
# Written by Andrey Ponomarenko
# LinkedIn: https://www.linkedin.com/in/andreyponomarenko
#
# PLATFORMS
# =========
#  Linux (Fedora, Ubuntu, Debian, Gentoo, ROSA, Mandriva ...)
#
# REQUIREMENTS
# ============
#  Perl 5
#  cURL
#  hwinfo
#  dmidecode
#  pciutils (lspci)
#  usbutils (lsusb)
#
# SUGGESTIONS
# ===========
#  hdparm
#  smartmontools (smartctl)
#  inxi
#  pnputils (lspnp)
#  rfkill
#  edid-decode
#
# SUGGESTIONS (MORE)
# ==================
#  hplip (hp-probe)
#  avahi
#  xinput
#  systemd-tools (systemd-analyze)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License or the GNU Lesser
# General Public License as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# and the GNU Lesser General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.
#########################################################################
use Getopt::Long;
Getopt::Long::Configure ("posix_default", "no_ignore_case");
use File::Path qw(mkpath rmtree);
use File::Temp qw(tempdir);
use File::Copy qw(copy move);
use File::Basename qw(basename dirname);
use Cwd qw(abs_path cwd);
use Config;

use strict;

my $TOOL_VERSION = "1.1";
my $CmdName = basename($0);

my $URL = "https://linux-hardware.org";

my $PROBE_DIR = getProbeDir();
my $DATA_DIR = $PROBE_DIR."/LATEST/hw.info";
my $LOG_DIR = $DATA_DIR."/logs";
my $TEST_DIR = $DATA_DIR."/tests";

my $ORIG_DIR = cwd();

my ($Help, $ShowVersion, $Probe, $Check, $Logs, $Show, $Compact, $Verbose,
$All, $PC_Name, $Key, $Upload, $FixProbe, $Printers, $DumpVersion, $Source,
$Debug, $PciIDs, $UsbIDs, $SdioIDs, $LogLevel, $ListProbes, $DumpACPI,
$DecodeACPI, $Clean, $Scanners, $Group, $GetGroup, $PnpIDs);

my $TMP_DIR = tempdir(CLEANUP=>1);

my $ShortUsage = "Hardware Probe Tool $TOOL_VERSION
A tool to probe for hardware and upload result to the Linux hardware DB
License: GNU GPL or GNU LGPL

Usage: (run as root) $CmdName [options]
Example: (run as root) $CmdName -all -upload -id PC_NAME

PC_NAME — any name of the computer.\n\n";

if($#ARGV==-1)
{
    print $ShortUsage;
    exit(0);
}

GetOptions("h|help!" => \$Help,
  "v|version!" => \$ShowVersion,
  "dumpversion!" => \$DumpVersion,
# general options
  "all!" => \$All,
  "probe!" => \$Probe,
  "logs!" => \$Logs,
  "log-level=s" => \$LogLevel,
  "printers!" => \$Printers,
  "scanners!" => \$Scanners,
  "check!" => \$Check,
  "id|name=s" => \$PC_Name,
  "upload!" => \$Upload,
# other
  "src|source=s" => \$Source,
  "fix=s" => \$FixProbe,
  "show!" => \$Show,
  "compact!" => \$Compact,
  "verbose!" => \$Verbose,
  "pci-ids=s" => \$PciIDs,
  "usb-ids=s" => \$UsbIDs,
  "sdio-ids=s" => \$SdioIDs,
  "pnp-ids=s" => \$PnpIDs,
  "list!" => \$ListProbes,
  "clean!" => \$Clean,
  "debug|d!" => \$Debug,
  "group|g=s" => \$Group,
  "get-group!" => \$GetGroup,
# private
  "dump-acpi!" => \$DumpACPI,
  "decode-acpi!" => \$DecodeACPI,
# security
  "key=s" => \$Key
) or errMsg();

sub errMsg()
{
    print "\n".$ShortUsage;
    exit(1);
}

my $HelpMessage="
NAME:
  Hardware Probe Tool ($CmdName)
  A tool to probe for hardware and upload result to the Linux hardware DB

DESCRIPTION:
  Hardware Probe Tool (HW Probe) is a tool to probe for hardware,
  check its operability and upload result to the Linux hardware DB.

  This tool is free software: you can redistribute it and/or modify it
  under the terms of the GNU GPL or GNU LGPL.

USAGE:
  (run as root) $CmdName [options]

EXAMPLES:
  (run as root) $CmdName -all -upload -id PC_NAME
  
  PC_NAME — any name of the computer.

INFORMATION OPTIONS:
  -h|-help
      Print this help.
  
  -v|-version
      Print version info.

  -dumpversion
      Print the tool version ($TOOL_VERSION) and don't do anything else.

GENERAL OPTIONS:
  -all
      Enable all probes. Please run as root for
      better results, i.e. execute \"su\" first.
  
  -probe
      Probe for hardware.
  
  -logs
      Collect system logs.
  
  -log-level N
      Set the logging level to N.
      Available values:
      
        - minimal
        - default
        - maximal
  
  -printers
      Probe for printers.
  
  -scanners
      Probe for scanners.
  
  -check
      Check devices operability.
  
  -id|-name PC_NAME
      The name of the PC to sign the result.
  
  -upload
      Upload result to the Linux hardware DB. You will get an URL
      to view the probe.
  
OTHER OPTIONS
  -src|-source PATH
      A probe to upload.
  
  -fix PATH
      Update list of devices and host info
      in the probe using probe data.
  
  -show
      Show devices info.
  
  -compact
      Use with -show option for compact view.
  
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
  
  -group|-g GROUP
      Set group id of the probe. You can get this id
      by the -get-group option.
  
  -get-group
      Get group id.

DATA LOCATION:
  You can find created probes in the \"<HOME>/HW_PROBE\" directory.

";

sub helpMsg() {
    print $HelpMessage;
}

# Hardware
my %HW;
my %KernMod = ();
my %WLanInterface = ();
my %PermanentAddr = ();

# Tests
my %TestRes;

# System
my %Sys;

# Settings
my $Admin = ($>==0);

# Fixing
my $FixProbe_Pkg;
my $FixProbe_Logs;

# PCI and USB IDs
my %PciInfo;
my %PciInfo_D;
my %UsbInfo;

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

my %MonVendor = (
    "HSD" => "HannStar",
    "CMN" => "Chimei Innolux",
    "LGD" => "LG Display",
    "CMO" => "Chi Mei Optoelectronics",
    "BNQ" => "BenQ",
    "AUO" => "AU Optronics",
    "ACR" => "Acer",
    "SAM" => "Samsung",
    "LEN" => "Lenovo",
    "LPL" => "LG Philips",
    "VSC" => "ViewSonic",
    "SNY" => "Sony",
    "PHL" => "Philips"
);

my %PciClassType = (
    "01" => "storage",
    "02" => "network",
    "03" => "graphics card",
    "04" => "multimedia",
    "04-00" => "video",
    "04-01" => "sound",
    "04-03" => "sound",
    "05" => "memory controller",
    "05-00" => "ram memory",
    "06" => "bridge",
    "07" => "communication controller",
    "07-03" => "modem",
    "08" => "system peripheral",
    "08-05" => "sd host controller",
    "09" => "input",
    "0a" => "docking station",
    "0b" => "processor",
    "0b-40" => "co-processor",
    "0c" => "serial bus controller",
    "0c-00" => "firewire controller",
    "0c-03" => "usb controller",
    "0c-02" => "ssa",
    "0c-05" => "smbus",
    "0c-06" => "infiniband",
    "0c-09" => "canbus",
    "0d" => "wireless controller",
    "0d-00" => "irda",
    "0d-11" => "bluetooth",
    "0e" => "intelligent controller",
    "0f" => "communications controller",
    "10" => "encryption controller",
    "11" => "signal processing",
    "12" => "processing accelerators"
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

sub getProbeDir()
{
    my $Dir = "HW_PROBE";
    
    if(my $Home = $ENV{"HOME"}) {
        $Dir = $Home."/".$Dir;
    }
    
    return $Dir;
}

sub getGroup()
{
    my $CurlCmd = "curl -s -S -f -POST -F get=group -H \"Expect:\" --http1.0 $URL/get_group.php";
    my $Log = qx/$CurlCmd 2>&1/;
    print $Log;
    if($?)
    {
        my $ECode = $?>>8;
        print STDERR "ERROR: failed to get group, curl error code \"".$ECode."\"\n";
        exit(1);
    }
    
    if($Log=~/Group ID: (\w+)/)
    {
        my $ID = $1;
        my $GroupLog = "GROUP\n=====\n".localtime(time)."\nGroup ID: $ID\n";
        appendFile($PROBE_DIR."/LOG", $GroupLog."\n");
    }
}

sub uploadData()
{
    my ($Pkg, $HWaddr) = createPackage();
    
    if($Pkg)
    {
        # upload package
        my @Cmd = ("curl", "-s", "-S", "-f", "-POST", "-F file=\@".$Pkg."", "-F hwaddr=$HWaddr");
        
        if($Debug) {
            @Cmd = (@Cmd, "-F debug=1");
        }
        
        if($PC_Name) {
            @Cmd = (@Cmd, "-F id=\'$PC_Name\'");
        }
        
        if($Group) {
            @Cmd = (@Cmd, "-F group=\'$Group\'");
        }
        
        # fix curl error 22: "The requested URL returned error: 417 Expectation Failed"
        @Cmd = (@Cmd, "-H", "Expect:");
        @Cmd = (@Cmd, "--http1.0");
        
        @Cmd = (@Cmd, $URL."/upload_result.php");
        
        my $CurlCmd = join(" ", @Cmd);
        my $Log = qx/$CurlCmd 2>&1/;
        print $Log;
        if($?)
        {
            my $ECode = $?>>8;
            print STDERR "ERROR: failed to upload data, curl error code \"".$ECode."\"\n";
            exit(1);
        }
        
        # save uploaded probe and its ID to $HOME
        my ($ID, $Token) = ();
        if($Log=~/probe\=(\w+)/) {
            $ID = $1;
        }
        if($Log=~/token\=(\w+)/) {
            $Token = $1;
        }
        
        if($ID)
        {
            my $NewProbe = $PROBE_DIR."/".$ID;
            
            if(-d $NewProbe)
            {
                print STDERR "ERROR: the probe with ID \'$ID\' already exists, overwriting ...\n";
                unlink($NewProbe."/hw.info.txz");
            }
            else {
                mkpath($NewProbe);
            }
            
            copy($Pkg, $NewProbe);
            
            my $ProbeUrl = "$URL/index.php?probe=$ID";
            my $ProbeLog = "PROBE\n=====\n".localtime(time)."\n";
            
            if($Token) {
                $ProbeLog .= "Private URL: $ProbeUrl&token=$Token\n";
            }
            $ProbeLog .= "Public URL: $ProbeUrl\n";
            
            appendFile($PROBE_DIR."/LOG", $ProbeLog."\n");
        }
    }
}

sub cleanData()
{
    if($Clean)
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
    
    if($Source)
    {
        if(-f $Source)
        {
            if(isPkg($Source))
            {
                $Pkg = $Source;
                
                system("tar", "--directory", $TMP_DIR, "-xf", $Pkg);
                if($?)
                {
                    print STDERR "ERROR: failed to extract package (".$?.")\n";
                    exit(1);
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
                    
                    if(updateHost($TMP_DIR."/hw.info", "id", $PC_Name)) {
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
                            print STDERR "ERROR: failed to create a package (".$?.")\n";
                            exit(1);
                        }
                        
                        $Pkg = $TMP_DIR."/hw.info.txz";
                    }
                }
            }
            else
            {
                print STDERR "ERROR: not a package\n";
                exit(1);
            }
        }
        elsif(-d $Source)
        {
            copyFiles($Source, $TMP_DIR."/hw.info");
            updateHost($TMP_DIR."/hw.info", "id", $PC_Name);
            
            $HWaddr = readHostAttr($TMP_DIR."/hw.info", "hwaddr");
            
            chdir($TMP_DIR);
            system("tar", "-cJf", "hw.info.txz", "hw.info");
            chdir($ORIG_DIR);
            
            if($?)
            {
                print STDERR "ERROR: failed to create a package (".$?.")\n";
                exit(1);
            }
            
            $Pkg = $TMP_DIR."/hw.info.txz";
        }
        else
        {
            print STDERR "ERROR: can't access \'$Source\'\n";
            exit(1);
        }
    }
    else
    {
        if(-d $DATA_DIR)
        {
            if(not -f $DATA_DIR."/devices")
            {
                print STDERR "ERROR: \'./".$DATA_DIR."/devices\' file is not found, please make probe first\n";
                exit(1);
            }
            
            updateHost($DATA_DIR, "id", $PC_Name);
            $HWaddr = readHostAttr($DATA_DIR, "hwaddr");
            
            $Pkg = $TMP_DIR."/hw.info.txz";
            
            chdir(dirname($DATA_DIR));
            system("tar", "-cJf", $Pkg, basename($DATA_DIR));
            chdir($ORIG_DIR);
        }
        else
        {
            print STDERR "ERROR: \'./".$DATA_DIR."\' directory is not found, please make probe first\n";
            exit(1);
        }
    }
    
    return ($Pkg, $HWaddr);
}

sub copyFiles($$)
{
    my ($P1, $P2) = @_;
    
    mkpath($P2);
    
    foreach my $Top (listDir($P1))
    {
        if(-d $P1."/".$Top)
        { # copy subdirectory
            foreach my $Sub (listDir($P1."/".$Top))
            {
                if($Sub=~/~\Z/) {
                    next;
                }
                mkpath($P2."/".$Top);
                copy($P1."/".$Top."/".$Sub, $P2."/".$Top."/".$Sub);
            }
        }
        else
        { # copy file
            if($Top=~/~\Z/) {
                next;
            }
            copy($P1."/".$Top, $P2."/".$Top);
        }
    }
}

sub isPkg($) {
    return ($_[0]=~/\.(tar\.xz|txz)\Z/);
}

sub updateHost($$$)
{
    my ($Path, $Attr, $Val) = @_;
    
    if($Val)
    {
        if(not -f $Path."/host")
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
    
    $Val=~s/\((R|TM)\)/ /ig;
    
    $Val=~s/\A[_\-\? ]//ig;
    $Val=~s/[_\-\? ]\Z//ig;
    
    $Val=~s/[ ]{2,}/ /g;
    
    return $Val;
}

sub bytesToHuman($)
{
    my $Bytes = $_[0];
    
    $Bytes/=1000000; # MB
    
    if($Bytes>=1000)
    {
        $Bytes/=1000; # GB
        $Bytes = round_to_nearest($Bytes);
        if($Bytes>=1000)
        {
            $Bytes/=1000; # TB
            $Bytes = round_to_nearest($Bytes);
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
    
    if(not keys(%PnpVendor)) {
        readPnpIds();
    }
    
    if(defined $PnpVendor{$V}) {
        return $PnpVendor{$V};
    }
    
    return undef;
}

sub readPnpIds()
{
    my $Path = undef;
    
    if($PnpIDs) {
        $Path = $PnpIDs;
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
    
    foreach (split(/\n/, readFile($Path)))
    {
        if(/\A([A-Z]+)\s+(.*?)\Z/) {
            $PnpVendor{$1} = $2;
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
            elsif($Name=~/USB Scanner/i) {
                return "scanner";
            }
            elsif($Name=~/bluetooth/i) {
                return "bluetooth";
            }
            elsif($Name=~/(\A| )WLAN( |\Z)|Wireless Adapter/i) {
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
    
    if($Capacity)
    {
        if($Device!~/(\A|\s)[\d\.]+\s*(MB|GB|TB)(\s|\Z)/ and $Device!~/reader|bridge|\/sd\/|adapter/i) {
            return " ".$Capacity;
        }
    }
    
    return "";
}

sub probeHW()
{
    if($FixProbe) {
        print "Fixing probe ... ";
    }
    else
    {
        if(not check_Cmd("hwinfo"))
        {
            print STDERR "ERROR: 'hwinfo' is not installed\n";
            exit(1);
        }
        
        print "Probe for hardware ... ";
        
        if($ListProbes) {
            print "\n";
        }
    }
    
    # Loaded modules
    my $Lsmod = "";
    
    if($FixProbe) {
        $Lsmod = readFile($FixProbe_Logs."/lsmod");
    }
    else
    {
        listProbe("logs", "lsmod");
        $Lsmod = `lsmod 2>&1`;
        
        # Sort, but save title
        my $FL = "";
        if($Lsmod=~s/\A(.*?)\n//) {
            $FL = $1;
        }
        
        $Lsmod = $FL."\n".join("\n", sort split(/\n/, $Lsmod));
        
        if($Logs) {
            writeLog($LOG_DIR."/lsmod", $Lsmod);
        }
    }
    
    foreach my $Line (split(/\n/, $Lsmod))
    {
        if($Line=~/(\w+)\s+(\d+)\s+(\d+)/) {
            $KernMod{$1} = $3;
        }
    }
    
    my $RpmLst = "/run/initramfs/live/rpm.lst";
    if(-f $RpmLst)
    { # Live
        my $Build = `head -n 1 $RpmLst 2>&1`; # iso build No.11506
        
        if($Build=~/(\d+)/) {
            $Sys{"Build"} = $1;
        }
        
        if($Logs) {
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
            
            if($Logs) {
                writeLog($LOG_DIR."/revision.info", $Build);
            }
        }
    }
    
    my $Cpu_ID = undef;
    
    # HW Info
    my $HWInfo = "";
    
    if($FixProbe) {
        $HWInfo = readFile($FixProbe_Logs."/hwinfo");
    }
    else
    {
        listProbe("logs", "hwinfo");
        
        my @Items = qw(bluetooth bridge
        camera cdrom chipcard cpu disk dvb fingerprint floppy
        framebuffer gfxcard hub ide isapnp isdn joystick keyboard
        modem monitor mouse netcard network pci
        pcmcia scanner scsi smp sound
        tape tv usb usb-ctrl vbe wlan zip);
        
        my $Items = "--".join(" --", @Items);
        
        $HWInfo = `hwinfo $Items 2>/dev/null`;
        
        if(not $HWInfo)
        { # incorrect option
            $HWInfo = `hwinfo --all 2>&1`;
        }
        
        if($Logs) {
            writeLog($LOG_DIR."/hwinfo", $HWInfo);
        }
    }

    my %Mon = ();
    
    my %LongID = ();
    
    my %HDD = ();
    
    foreach my $Info (split(/\n\n/, $HWInfo))
    {
        my %Device = ();
        my ($Num, $Bus) = ();
        
        my ($V, $D, $SV, $SD, $C) = ();
        
        if($Info=~s/(\d+):\s*([^ ]+)//)
        { # 37: PCI 700.0: 0200 Ethernet controller
            $Num = $1;
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
        
        $Info=~s/[ ]{2,}/ /g;
        
        my $ID = "";
        
        while($Info=~s/[ \t]*([\w ]+?):[ \t]*(.*)//)
        {
            my ($Key, $Val) = ($1, $2);
            
            if($Key eq "Device" or $Key eq "Vendor" or $Key eq "SubVendor" or $Key eq "SubDevice")
            {
                $Key=~s/\ASub/S/; # name mapping
                
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
                my @Dr = ();
                while($Val=~s/\"([\w\-]+)\"//)
                {
                    my $Dr = $1;
                    $Dr=~s/\-/_/g;
                    $Device{"ActiveDriver_Common"}{$Dr} = keys(%{$Device{"ActiveDriver_Common"}});
                }
            }
            elsif($Key eq "Driver Modules")
            {
                my @Dr = ();
                while($Val=~s/\"([\w\-]+)\"//) {
                    push(@Dr, $1);
                }
                # $Device{"Driver"} = join(",", @Dr);
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
                if($Bus eq "ide")
                {
                    # FIXME: check for PATA
                    if($Val=~/SATA/)
                    {
                        # $Bus = "sata";
                    }
                }
            }
            elsif($Key eq "Device Files")
            {
                if($Val=~/by-id\/(.*?),/) {
                    $Device{"FsId"} = $1;
                }
            }
            elsif($Key eq "Device File")
            {
                if($Device{"Type"} eq "disk"
                and $Bus eq "ide")
                {
                    $Val=~s/\s*\(.*\)//g;
                    $HDD{$Val} = 1;
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
        }
        
        cleanValues(\%Device);
        
        if(my $Model = $Device{"Model"})
        {
            if(not $Device{"Device"}) {
                $Device{"Device"} = $Device{"Model"};
            }
        }
        
        if($Device{"Type"} eq "cpu") {
            $Bus = "cpu";
        }
        
        if($Device{"Type"} eq "framebuffer")
        {
            $Bus = "fb";
            
            next; # disabled
        }
        
        if($Bus eq "none") {
            next;
        }
        
        if(defined $Device{"ActiveDriver"}) {
            $Device{"Driver"} = join(", ", sort {$Device{"ActiveDriver"}{$a} <=> $Device{"ActiveDriver"}{$b}} keys(%{$Device{"ActiveDriver"}}));
        }
        elsif(defined $Device{"ActiveDriver_Common"}) {
            $Device{"Driver"} = join(", ", sort {$Device{"ActiveDriver_Common"}{$a} <=> $Device{"ActiveDriver_Common"}{$b}} keys(%{$Device{"ActiveDriver_Common"}}));
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
            elsif($Bus eq "sata" or $Bus eq "ide")
            {
                my %DiskVendor = (
                    "HT" => "Hitachi",
                    "ST" => "Seagate",
                    "WD" => "WDC",
                    "CT" => "Crucial",
                    "TS" => "Transcend"
                );
                
                if($Device{"Device"}=~/\A([A-Z]{2})[A-Z\d]+/
                and defined $DiskVendor{$1}) {
                    $Device{"Vendor"} = $DiskVendor{$1};
                }
                elsif($Device{"Device"}=~s/\A([a-z]{3,})[\-\_ ]//i)
                { # Crucial_CT240M500SSD3
                    $Device{"Vendor"} = $1;
                }
            }
        }
        
        $Device{"Device"} = duplVendor($Device{"Vendor"}, $Device{"Device"});
        
        if($Bus eq "usb" or $Bus eq "pci")
        {
            $ID = devID($V, $D, $SV, $SD);
            
            if($SV, $SD) {
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
            
            if($Device{"Device"})
            {
                if($Device{"Type"} eq "disk")
                {
                    if(my $FsId = $Device{"FsId"})
                    {
                        if(my $Serial = $Device{"Serial"})
                        {
                            my $N = $Device{"Device"};
                            $N=~s/ /_/g;
                            
                            if($FsId=~/\Q$N\E(.*?)_\Q$Serial\E/)
                            {
                                my $Suffix = $1;
                                $Suffix=~s/[_]+/ /g;
                                $Device{"Device"} .= $Suffix;
                            }
                        }
                    }
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
                    else
                    {
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
                }
                elsif($Device{"Type"} eq "disk") {
                    $Device{"Device"} .= addCapacity($Device{"Device"}, $Device{"Capacity"});
                }
                elsif($Device{"Type"} eq "cpu") {
                    $Device{"Status"} = "works";
                }
                elsif($Device{"Type"} eq "framebuffer") {
                    $Device{"Device"} .= " ".$Device{"Memory Size"};
                }
            }
            else {
                next;
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
        
        if($Device{"Type"} eq "monitor") {
            $Mon{uc($V.$D)} = $ID;
        }
        
        if($Device{"Type"}=~/touchpad/
        and $Bus eq "ps/2")
        {
            if(not $Sys{"Type"}
            or $Sys{"Type"} eq "desktop"
            or $Sys{"Type"} eq "other") {
                $Sys{"Type"} = "notebook";
            }
        }
        
        if(not $HW{$Bus.":".$ID}) {
            $HW{$Bus.":".$ID} = \%Device;
        }
        else
        { # double entry
            if($Device{"Type"} and not $HW{$Bus.":".$ID}{"Type"}) {
                $HW{$Bus.":".$ID} = \%Device;
            }
        }
        
        if($Device{"Type"} eq "cpu") {
            $Cpu_ID = $ID;
        }
    }
    
    my %HDD_Serial = ();
    
    # UDEV
    my $Udevadm = "";
    
    if($FixProbe)
    {
        $Udevadm = readFile($FixProbe_Logs."/udev-db");
        if(not $Udevadm)
        { # support for old probes
            $Udevadm = readFile($FixProbe_Logs."/udevadm");
        }
    }
    else
    {
        if($LogLevel eq "maximal")
        {
            listProbe("logs", "udev-db");
            $Udevadm = `udevadm info --export-db 2>/dev/null`;
            
            if($Logs) {
                writeLog($LOG_DIR."/udev-db", $Udevadm);
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
    if(not $Admin and keys(%HDD_Serial))
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
                        }
                        
                        delete($HW{$ID});
                    }
                }
            }
        }
    }
    
    # PCI (all)
    my $Lspci_A = "";
    
    if($FixProbe) {
        $Lspci_A = readFile($FixProbe_Logs."/lspci_all");
    }
    else
    {
        listProbe("logs", "lspci_all");
        $Lspci_A = `lspci -vvnn 2>&1`;
        
        if($Logs) {
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
        
        if($V and $D) {
            $LongID{devID($V, $D)}{$ID} = 1;
        }
    }
    
    # PCI
    my $Lspci = "";
    
    if($FixProbe) {
        $Lspci = readFile($FixProbe_Logs."/lspci");
    }
    else
    {
        listProbe("logs", "lspci");
        $Lspci = `lspci -vmnnk 2>&1`;
        
        if($Logs) {
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
        
        if($PciIDs)
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
        
        #if(defined $HW{"pci:".$ID}{"Class"}) {
        #    delete($Device{"Class"});
        #}
        
        if($Device{"Module"})
        {
            $Device{"Driver"} = $Device{"Module"};
            delete($Device{"Module"});
        }
        
        if(my $Dr = $Device{"Driver"})
        {
            $Dr=~s/\-/_/g;
            if(not defined $HW{"pci:".$ID}{"Driver"}) {
                $HW{"pci:".$ID}{"Driver"} = $Dr;
            }
        }
        
        if(not $HW{"pci:".$ID}{"Type"})
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
                if($_ eq "Driver") {
                    next;
                }
                $HW{"pci:".$ID}{$_} = $Val;
            }
        }
    }
    
    # USB
    my $Lsusb = "";
    
    if($FixProbe) {
        $Lsusb = readFile($FixProbe_Logs."/lsusb");
    }
    else
    {
        listProbe("logs", "lsusb");
        $Lsusb = `lsusb -v 2>&1`;
        
        if($Logs) {
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
        
        if($UsbIDs)
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
                    
                    my $V1 = nameID($Vendor);
                    my $V2 = nameID($SubVendor);
                    
                    if($Vendor
                    and $SubVendor!~/usb/i and $SubVendor!~/generic/
                    and $SubVendor ne $Device{"SDevice"}
                    and $SubVendor ne $FinalName)
                    {
                        #if($V1!~/\Q$V2\E/i and $V2!~/\Q$V1\E/i) {
                            $Device{"SVendor"} = $SubVendor;
                        #}
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
    
    if($FixProbe) {
        $Usb_devices = readFile($FixProbe_Logs."/usb-devices");
    }
    else
    {
        listProbe("logs", "usb-devices");
        $Usb_devices = `usb-devices -v 2>&1`;
        
        if($Logs) {
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
        
        if(defined $Drivers{"radeon"}
        and defined $Drivers{"fglrx"})
        {
            if($KernMod{"radeon"}==0) {
                delete($Drivers{"radeon"});
            }
            elsif($KernMod{"fglrx"}==0) {
                delete($Drivers{"fglrx"});
            }
        }
        elsif(defined $Drivers{"nouveau"})
        {
            if($KernMod{"nouveau"}==0
            and $KernMod{"nvidia"}!=0)
            {
                delete($Drivers{"nouveau"});
                $Drivers{"nvidia"} = 1;
            }
        }
        elsif(defined $Drivers{"wl"}
        and $Driver ne "wl")
        {
            if($KernMod{"wl"}==0)
            {
                delete($Drivers{"wl"});
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
    
    # DMI
    my $Dmidecode = "";
    
    if($FixProbe) {
        $Dmidecode = readFile($FixProbe_Logs."/dmidecode");
    }
    else
    {
        listProbe("logs", "dmidecode");
        $Dmidecode = `dmidecode 2>&1`;
        
        if($Logs) {
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
                my $CType = lc($1);
                $CType=~s/ chassis//i;
                
                if($CType!~/unknown|other/) {
                    $Sys{"Type"} = $CType;
                }
            }
        }
        elsif($Info=~/System Information\n/)
        {
            if($Info=~/Version:[ ]*(.+?)[ ]*(\n|\Z)/) {
                $Sys{"Version"} = $1;
            }
            
            if($Info=~/Family:[ ]*(.+?)[ ]*(\n|\Z)/) {
                $Sys{"Family"} = $1;
            }
        }
        elsif($Info=~/Memory Device\n/) # $Info=~/Memory Module Information\n/
        {
            my @Add = ();
            
            while($Info=~s/([\w ]+):[ \t]*(.+?)[ \t]*(\n|\Z)//)
            {
                my ($Key, $Val) = ($1, fmtVal($2));
                
                if(lc($Val) eq "unknown") {
                    next;
                }
                
                if($Key eq "Manufacturer")
                {
                    $Device{"Vendor"} = $Val;
                    $Device{"Vendor"}=~s/0{4,}/0/;
                }
                elsif($Key eq "Part Number") {
                    $Device{"Device"} = $Val;
                }
                elsif($Key eq "Serial Number") {
                    $Device{"Serial"} = $Val;
                }
                elsif($Key eq "Type") {
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
                    $Val=~s/ //g;
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
            
            $Device{"Type"} = "memory";
            $Device{"Status"} = "works";
            
            my $Inc = 0;
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
            
            if($Inc) {
                $MemIndex++;
            }
            
            $ID = devID(nameID($Device{"Vendor"}), devSuffix(\%Device));
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
            
            $Device{"Device"} = "RAM ".$Device{"Device"};
            
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
                elsif($Key eq "Version")
                {
                    if($Val!~/\b(n\/a|Not)\b/i) {
                        $Device{"Version"} = $Val;
                    }
                }
            }
            
            $Device{"Vendor"}=~s&\Ahttp://www.&&i; # http://www.abit.com.tw as vendor
            
            cleanValues(\%Device);
            
            if($Device{"Version"}=~/board version/i) {
                delete($Device{"Version"});
            }
            
            if($Device{"Device"}=~/\bName\d*\b/i)
            { # no info
                next;
            }
            
            if(not $Device{"Vendor"})
            {
                if($Device{"Device"}=~/\AConRoe[A-Z\d]/)
                { # ConRoe1333, ConRoeXFire
                    $Device{"Vendor"} = "ASRock";
                }
            }
            
            if(my $Ver = $Device{"Version"}) {
                $Device{"Device"} .= " ".$Device{"Version"};
            }
            
            if(my $Vendor = $Device{"Vendor"}) {
                $Device{"Device"}=~s/\A\Q$Vendor\E\s+//ig;
            }
            
            $Device{"Type"} = "motherboard";
            $Device{"Status"} = "works";
            
            $ID = devID(nameID($Device{"Vendor"}), devSuffix(\%Device));
            $ID = fmtID($ID);
            
            $Device{"Device"} = "Motherboard ".$Device{"Device"};
            
            if($ID) {
                $HW{"board:".$ID} = \%Device;
            }
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
            
            cleanValues(\%Device);
            
            my @Name = ();
            
            if($Device{"Version"}) {
                push(@Name, $Device{"Version"});
            }
            
            if(my $BiosDate = $Device{"Release Date"})
            {
                push(@Name, $Device{"Release Date"});
                
                if($BiosDate=~/\b(\d\d\d\d)\b/) {
                    $Sys{"Year"} = $1;
                }
            }
            
            $Device{"Device"} = join(" ", @Name);
            $Device{"Type"} = "bios";
            $Device{"Status"} = "works";
            
            $ID = devID(nameID($Device{"Vendor"}), devSuffix(\%Device));
            $ID = fmtID($ID);
            
            $Device{"Device"} = "BIOS ".$Device{"Device"};
            
            if($ID) {
                $HW{"bios:".$ID} = \%Device;
            }
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
            
            if(not $Cpu_ID)
            {
                $ID = devID(nameID($Device{"Vendor"}), $D, devSuffix(\%Device));
                $ID = fmtID($ID);
                
                if($ID) {
                    $HW{"cpu:".$ID} = \%Device;
                }
            }
            else
            { # add info
                foreach (keys(%Device))
                {
                    my $Val1 = $HW{"cpu:".$Cpu_ID}{$_};
                    my $Val2 = $Device{$_};
                    
                    if($Val2
                    and not $Val1) {
                        $HW{"cpu:".$Cpu_ID}{$_} = $Val2;
                    }
                }
            }
        }
    }
    
    # Printers
    my %Pr;
    
    my $Hpprobe = "";
    
    if($FixProbe) {
        $Hpprobe = readFile($FixProbe_Logs."/hp-probe");
    }
    else
    {
        if($Printers)
        {
            listProbe("logs", "hp-probe");
            
            # Net
            $Hpprobe = `hp-probe -bnet -g 2>&1`;
            $Hpprobe .= "\n";
            
            # Usb
            $Hpprobe .= `hp-probe -busb -g 2>&1`;
            
            $Hpprobe = clearLog($Hpprobe);
            
            if($Logs) {
                writeLog($LOG_DIR."/hp-probe", $Hpprobe);
            }
        }
    }
    
    foreach my $Line (split(/\n/, $Hpprobe))
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
                if($Device{"Device"}=~/\A(HP|Hewlett\-Packard|Epson|Kyocera|Brother|Samsung|Canon|Xerox) /i) {
                    $Device{"Vendor"} = $1;
                }
            }
            
            if(my $Vendor = $Device{"Vendor"})
            {
                $Device{"Device"}=~s/\A\Q$Vendor\E(\s+|\-)//ig;
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
    
    if($FixProbe)
    {
        if(-f $FixProbe_Logs."/hp-probe")
        { # i.e. executed with -printers option
            $Avahi = readFile($FixProbe_Logs."/avahi");
        }
    }
    else
    {
        if($Printers or $LogLevel eq "maximal")
        {
            if(check_Cmd("avahi-browse"))
            {
                listProbe("logs", "avahi-browse");
                $Avahi = `avahi-browse -a -t 2>&1`;
                
                if($Logs) {
                    writeLog($LOG_DIR."/avahi", $Avahi);
                }
            }
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
                if($Device{"Device"}=~/\A(HP|Hewlett\-Packard|Epson|Kyocera|Brother|Samsung|Canon|Xerox) /i) {
                    $Device{"Vendor"} = $1;
                }
            }
            
            if(my $Vendor = $Device{"Vendor"}) {
                $Device{"Device"}=~s/\A\Q$Vendor\E(\s+|\-)//ig;
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
    
    if($FixProbe) {
        $Edid = readFile($FixProbe_Logs."/edid");
    }
    else
    { # NOTE: works for KMS video drivers only
        listProbe("logs", "edid");
        
        my $EdidDecode = check_Cmd("edid-decode");
        my $MonEdid = check_Cmd("monitor-get-edid");
        
        if($EdidDecode)
        {
            my $MDir = "/sys/class/drm";
            foreach my $Dir (listDir($MDir))
            {
                my $Path = $MDir."/".$Dir."/edid";
                
                if(-f $Path)
                {
                    my $Dec = `edid-decode \"$Path\" 2>/dev/null`;
                    
                    if($Dec!~/No header found/i)
                    {
                        $Edid .= "edid-decode \"$Path\"\n".$Dec."\n\n";
                    }
                }
            }
        }
        
        if(not $Edid)
        { # for nvidia, fglrx
            if($MonEdid)
            {
                if($Admin)
                {
                    if($EdidDecode) {
                        $Edid .= `monitor-get-edid 2>/dev/null | edid-decode 2>&1`;
                    }
                    else
                    { # LTS
                        $Edid .= `monitor-get-edid 2>/dev/null | monitor-parse-edid 2>/dev/null`;
                    }
                    $Edid=~s/\n\n/\n/g;
                }
            }
        }
        
        if($Edid=~/EDID block does not conform at all/i) {
            $Edid = "";
        }
        
        if($Logs) {
            writeLog($LOG_DIR."/edid", $Edid);
        }
    }
    
    foreach my $Info (split(/\n\n/, $Edid))
    {
        my ($V, $D) = ();
        my %Device = ();
        
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
        elsif($Info=~/EISA ID:\s*(\w{3})(\w+)/)
        {
            ($V, $D) = (uc($1), uc($2));
        }

        if(not $V or not $D) {
            next;
        }
        
        if($V eq "\@\@\@") {
            next;
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
        
        if($Info=~/(Maximum image size|Screen size):(.+?)\n/i)
        {
            my $MonSize = $2;
            
            if($MonSize=~/(\d+)\s*mm\s*x\s*(\d+)\s*mm/) {
                $Device{"Size"} = $1."x".$2."mm";
            }
            elsif($MonSize=~/([\d\.]+)\s*cm\s*x\s*([\d\.]+)\s*cm/) {
                $Device{"Size"} = $1."x".$2."cm";
            }
        }
        
        my %Resolutions = ();
        
        while($Info=~s/(\d+)x(\d+)\@\d+//)
        {
            $Resolutions{$1} = $1."x".$2;
        }
        
        if(my @Res = sort {int($b)<=>int($a)} keys(%Resolutions))
        {
            $Device{"Resolution"} = $Resolutions{$Res[0]};
        }
        
        if(not $Device{"Resolution"})
        { # monitor-parse-edid
            if($Info=~s/"(\d+x\d+)"//) {
                $Device{"Resolution"} = $1;
            }
        }
        
        if(not $Device{"Resolution"})
        {
            my ($W, $H) = ();
            if($Info=~/\n\s+(\d+)\s+.+?\s+hborder/) {
                $W = $1;
            }
            if($Info=~/\n\s+(\d+)\s+.+?\s+vborder/) {
                $H = $1;
            }
            
            if($W and $H) {
                $Device{"Resolution"} = $W."x".$H;
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
        
        if(my $OldID = $Mon{uc($V.$D)})
        {
            my $Name = $Device{"Device"};
            if($Name ne "LCD Monitor")
            {
                if($HW{"eisa:".$OldID}{"Vendor"}!~/\Q$Name\E/i) {
                    $HW{"eisa:".$OldID}{"Device"}=~s/LCD Monitor/$Name/;
                }
            }
            next;
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
        
        $Device{"Type"} = "monitor";
        
        if($ID)
        {
            if(not defined $HW{"eisa:".$ID}) {
                $HW{"eisa:".$ID} = \%Device;
            }
        }
    }
    
    # Battery
    my $Upower = "";
    
    if($FixProbe) {
        $Upower = readFile($FixProbe_Logs."/upower");
    }
    else
    {
        listProbe("logs", "upower");
        $Upower = `upower -d 2>/dev/null`;
        if($Logs) {
            writeLog($LOG_DIR."/upower", $Upower);
        }
    }
    
    if($Upower)
    {
        foreach my $UPInfo (split(/\n\n/, $Upower))
        {
            if($UPInfo=~/devices\/battery_/)
            {
                my %Device = ();
                
                $Device{"Type"} = "battery";
                
                foreach my $Line (split(/\n/, $UPInfo))
                {
                    if($Line=~/vendor:[ ]*(.+?)[ ]*\Z/) {
                        $Device{"Vendor"} = fmtVal($1);
                    }
                    
                    if($Line=~/model:[ ]*(.+?)[ ]*\Z/) {
                        $Device{"Device"} = fmtVal($1);
                    }
                    
                    if($Line=~/energy-full-design:[ ]*(.+?)[ ]*\Z/)
                    {
                        $Device{"Size"} = $1;
                        $Device{"Size"}=~s/\,/\./g;
                    }
                    
                    if($Line=~/technology:[ ]*(.+?)[ ]*\Z/) {
                        $Device{"Technology"} = $1;
                    }
                }
                
                cleanValues(\%Device);
                
                if($Device{"Vendor"}=~/customer/i
                or length($Device{"Vendor"})>20 and $Device{"Vendor"}!~/\s/)
                {
                    $Device{"Vendor"} = ""; # vnd0
                }
                
                if(length($Device{"Device"})>20
                and $Device{"Device"}!~/\s/)
                {
                    $Device{"Device"} = ""; # model0
                }
                
                if($Device{"Vendor"} and $Device{"Device"} and $Device{"Size"})
                {
                    my $ID = devID(nameID($Device{"Vendor"}), $Device{"Device"});
                    $ID = fmtID($ID);
                    
                    $Device{"Device"} = "Battery ".$Device{"Device"};
                    
                    if($Device{"Technology"}) {
                        $Device{"Device"} .= " ".$Device{"Technology"};
                    }
                    
                    if($Device{"Size"}) {
                        $Device{"Device"} .= " ".$Device{"Size"};
                    }
                    
                    if($ID) {
                        $HW{"bat:".$ID} = \%Device;
                    }
                }
            }
        }
    }
    
    # Fix incorrect machine type
    if($Upower)
    {
        if(not $Sys{"Type"} or $Sys{"Type"} eq "desktop")
        {
            if($Upower=~/devices\/battery_/)  {
                $Sys{"Type"} = "notebook";
            }
        }
    }
    
    # PNP
    my $Lspnp = "";
    if($FixProbe) {
        $Lspnp = readFile($FixProbe_Logs."/lspnp");
    }
    else
    {
        if(check_Cmd("lspnp"))
        {
            listProbe("logs", "lspnp");
            $Lspnp = `lspnp -vv 2>&1`;
            if($Logs) {
                writeLog($LOG_DIR."/lspnp", $Lspnp);
            }
        }
    }
    
    # HDD
    my $Hdparm = "";
    if($FixProbe) {
        $Hdparm = readFile($FixProbe_Logs."/hdparm");
    }
    else
    {
        if($Logs)
        {
            listProbe("logs", "hdparm");
            if($Admin)
            {
                if(my @HDDs = sort keys(%HDD))
                {
                    my $HdparmCmd = "hdparm -I \"".join("\" \"", @HDDs)."\" 2>/dev/null";
                    $Hdparm = `$HdparmCmd`;
                }
            }
            writeLog($LOG_DIR."/hdparm", $Hdparm);
        }
    }
    
    my $Smartctl = "";
    if($FixProbe) {
        $Smartctl = readFile($FixProbe_Logs."/smartctl");
    }
    else
    {
        if($Logs)
        {
            if($Admin and check_Cmd("smartctl"))
            {
                listProbe("logs", "smartctl");
                if(my @HDDs = sort keys(%HDD))
                {
                    foreach (@HDDs)
                    {
                        my $SmartCmd = "smartctl -x \"".$_."\" 2>/dev/null";
                        my $Output = `$SmartCmd`;
                        $Output=~s/\A.*?(\=\=\=)/$1/sg;
                        $Smartctl .= $_."\n".$Output."\n";
                    }
                }
                writeLog($LOG_DIR."/smartctl", $Smartctl);
            }
        }
    }
    
    print "Ok\n";
}

sub getXRes($)
{
    if($_[0]=~/\A(\d+)/) {
        return $1;
    }
    
    return undef;
}

sub duplVendor($$)
{
    my ($Vendor, $Device) = @_;
    
    if($Vendor)
    { # do not duplicate vendor name
        if(not $Device=~s/\A\Q$Vendor\E(\s+|\-)//ig)
        {
            if(my $ShortVendor = nameID($Vendor))
            {
                if($ShortVendor ne $Vendor) {
                    $Device=~s/\A\Q$ShortVendor\E(\s+|\-)//ig
                }
            }
        }
    }
    
    return $Device;
}

sub round_to_nearest($)
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
    foreach (keys(%{$Hash}))
    {
        my $Val = $Hash->{$_};
        
        if($Val=~/\A[\[\(]*(not specified|not defined|invalid|error|unknown|empty|none)[\)\]]*\Z/i
        or $Val=~/(\A|\b|\d)(to be filled|unclassified device|not defined)(\b|\Z)/i) {
            delete($Hash->{$_});
        }
        
        if($Val=~/\A(vendor|device|unknown vendor|customer|model)\Z/i)
        {
            delete($Hash->{$_});
        }
    }
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
    }
    elsif($Device->{"Type"} eq "memory"
    or $Device->{"Type"} eq "disk")
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

sub nameID($)
{
    my $Name = $_[0];
    
    $Name=~s/\s*\([^()]*\)//g;
    $Name=~s/\s*\[[^\[\]]*\]//g;
    
    while ($Name=~s/\s*(\,\s*|\s+)(Inc|Ltd|Co|GmbH|Corp|Pte|LLC|Sdn|Bhd|BV|RSS|PLC|s\.r\.l\.|srl|S\.P\.A\.|B\.V\.)(\.|\Z)//ig){};
    $Name=~s/,?\s+[a-z]{2,4}\.//ig;
    $Name=~s/,(.+)\Z//ig;
    
    while ($Name=~s/\s+(Corporation|Computer|Electric|Company|Electronics|Electronic|Technologies)\Z//ig){};
    
    $Name=~s/[\.\,]/ /g;
    $Name=~s/\s*\Z//g;
    $Name=~s/\A\s*//g;
    
    return $Name;
}

sub fixModel($$$)
{
    my ($Vendor, $Model, $Version) = @_;
    
    if($Vendor eq "Hewlett-Packard")
    {
        $Model=~s/\AHP\s+//g;
        $Model=~s/\s+Notebook PC\s*\Z//gi;
    }
    elsif(uc($Vendor) eq "LENOVO")
    {
        if($Version=~/[A-Z]/i)
        {
            $Version=~s/\ALenovo\s*//i;
            
            if($Version)
            {
                while($Model=~s/\A\Q$Version\E\s+//){};
                
                if($Model!~/\Q$Version\E/) {
                    $Model = $Version." ".$Model;
                }
            }
        }
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
    
    return @Contents;
}

sub probeSys()
{
    my ($Distr, $Rel) = probeDistr();
    
    $Sys{"System"} = $Distr;
    $Sys{"SystemRel"} = $Rel;
    
    if(not $Sys{"System"}) {
        print STDERR "WARNING: failed to detect Linux distribution\n";
    }
    
    $Sys{"Arch"} = `uname -m`;
    if($Sys{"Arch"}=~/unknown/i)
    {
        $Sys{"Arch"} = $Config{"archname"};
        $Sys{"Arch"}=~s/\-linux.*//;
    }
    
    $Sys{"Kernel"} = `uname -r`;
    $Sys{"Node"} = `uname -n`;
    $Sys{"User"} = $ENV{"USER"};
    
    if($PC_Name) {
        $Sys{"Name"} = $PC_Name;
    }
    
    listProbe("logs", "dmi_id");
    my $DmiDir = "/sys/class/dmi/id/";
    my @DmiFiles = listDir($DmiDir);
    my $Dmi = "";
    
    foreach my $File (sort {$b cmp $a} @DmiFiles)
    {
        if(not -f $DmiDir."/".$File) {
            next;
        }
        
        if($File eq "uevent") {
            next;
        }
        
        my $Value = readFile($DmiDir."/".$File);
        
        if($File eq "sys_vendor")
        {
            if($Value!~/\b(System manufacturer|to be filled)\b/i) {
                $Sys{"Vendor"} = $Value;
            }
        }
        elsif($File eq "product_name")
        {
            if($Value!~/\b(Name|to be filled)\b/i) {
                $Sys{"Model"} = $Value;
            }
        }
        elsif($File eq "product_version")
        {
            if($Value!~/\b(Version|to be filled)\b/i) {
                $Sys{"Version"} = $Value;
            }
        }
        elsif($File eq "board_serial")
        { # root
            if($Value!~/\b(Number|to be filled)\b/i) {
                $Sys{"Board"} = $Value;
            }
        }
        
        if($Value ne "" and $Value=~/[A-Z0-9]/i) {
            $Dmi .= $File.": "  .$Value;
        }
    }
    
    if($Logs) {
        writeLog($LOG_DIR."/dmi_id", $Dmi);
    }
    
    $Sys{"Model"} = fixModel($Sys{"Vendor"}, $Sys{"Model"}, $Sys{"Version"});
    
    foreach (keys(%Sys)) {
        chomp($Sys{$_});
    }
}

sub probeHWaddr()
{
    my $IFConfig = undef;
    
    if($FixProbe)
    {
        if($IFConfig = readFile($FixProbe_Logs."/ifconfig"))
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
        listProbe("logs", "ifconfig");
        if(not check_Cmd("ifconfig"))
        {
            print STDERR "ERROR: can't find 'ifconfig'\n";
            exit(1);
        }
        
        if($IFConfig = `ifconfig -a 2>&1`)
        {
            if($Logs) {
                writeLog($LOG_DIR."/ifconfig", $IFConfig);
            }
            
            $Sys{"HWaddr"} = detectHWaddr($IFConfig);
            
            if(not $Sys{"HWaddr"})
            {
                print STDERR "ERROR: failed to detect hwaddr\n";
                exit(1);
            }
            
            if($Logs)
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
    }
}

sub detectHWaddr($)
{
    my $IFConfig = $_[0];
    
    my (@Eth, @Wlan, @Other) = ();
    
    foreach my $Block (split(/[\n]\s*[\n]+/, $IFConfig))
    {
        my $Addr = undef;
        
        if($Block=~/ether\s+([^\s]+)/)
        { # Fresh
            $Addr = lc($1);
        }
        elsif($Block=~/HWaddr\s+([^\s]+)/)
        { # Marathon
            $Addr = lc($1);
        }
        
        if($Addr and $Addr ne "00:00:00:00:00:00")
        {
            my $NetDev = undef;
            
            if($Block=~/\A([^:]+):/) {
                $NetDev = $1;
            }
            else {
                next;
            }
            
            if(not $FixProbe)
            {
                if(my $RealMac = getRealHWaddr($NetDev)) {
                    $PermanentAddr{$NetDev} = $RealMac;
                }
            }
            
            if(defined $PermanentAddr{$NetDev}) {
                $Addr = $PermanentAddr{$NetDev};
            }
            
            if($NetDev=~/\Aenp\d+s\d+.*u\d+\Z/i)
            { # enp0s20f0u3, enp0s29u1u5, enp0s20u1, etc.
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
    else {
        return undef;
    }
    
    $Sel=~s/:/-/g;
    return $Sel;
}

sub getRealHWaddr($)
{
    my $Dev = $_[0];
    
    if(check_Cmd("ethtool"))
    {
        my $Info = `ethtool -P $Dev 2>/dev/null`;
        
        if($Info=~/(\w\w:\w\w:\w\w:\w\w:\w\w:\w\w)/)
        {
            my $Mac = lc($1);
            
            if($Mac ne "00:00:00:00:00:00"
            and $Mac ne "ff:ff:ff:ff:ff:ff") {
                return $Mac;
            }
        }
    }
    
    return undef;
}

sub readFile($)
{
    my $Path = $_[0];
    open(FILE, $Path);
    local $/ = undef;
    my $Content = <FILE>;
    close(FILE);
    return $Content;
}

sub probeDistr()
{
    my $LSB_Rel = "";
    
    if($FixProbe) {
        $LSB_Rel = readFile($FixProbe_Logs."/lsb_release");
    }
    else
    {
        if(check_Cmd("lsb_release")) {
            $LSB_Rel = `lsb_release -i -d -r -c 2>/dev/null`;
        }
    }
    
    if($LSB_Rel)
    { # Desktop
        my ($Name, $Release, $Descr) = ();
        
        if($LSB_Rel=~/ID:\s*(.*)/) {
            $Name = $1;
        }
        
        if($LSB_Rel=~/Release:\s*(.*)/) {
            $Release = lc($1);
        }
        if($LSB_Rel=~/Description:\s*(.*)/) {
            $Descr = $1;
        }
        
        if($Name=~/\AROSAEnterpriseServer/i) {
            return ("rels-".$Release, "");
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
            
            return ("rosa-".$Release, $Rel);
        }
        elsif($Name=~/\AOpenMandriva/i) {
            return ("openmandriva-".$Release, "");
        }
        
        $Name=~s/\s+(Linux|Project)(\s+|\Z)/ /i;
        $Name=~s/\s+\Z//;
        $Name=~s/\s+/\-/g;
        
        if($Name and $Release) {
            return (lc($Name)."-".$Release, "");
        }
    }
    
    my $OS_Rel = "";
    
    if($FixProbe) {
        $OS_Rel = readFile($FixProbe_Logs."/os-release");
    }
    else {
        $OS_Rel = readFile("/etc/os-release");
    }
    
    if($OS_Rel)
    {
        my ($Name, $Release) = ();
        
        if($OS_Rel=~/\bID=\s*[\"\']*([^"'\n]+)/) {
            $Name = $1;
        }
        if($OS_Rel=~/\bVERSION_ID=\s*[\"\']*([^"'\n]+)/) {
            $Release = $1;
        }
        
        $Name=~s/\s+Linux(\s+|\Z)/ /i;
        
        if($Name and $Release) {
            return (lc($Name)."-".lc($Release), "");
        }
        elsif($Name) {
            return (lc($Name), "");
        }
    }
    
    return ("", "");
}

sub devID(@)
{
    my @ID = ();
    
    foreach (@_)
    {
        if($_) {
            push(@ID,  $_);
        }
    }
    
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
            
            if($HW{$ID}{"SDevice"} ne "Device") {
                push(@D, $HW{$ID}{"SDevice"});
            }
        }
        
        $HWData .= join(";", @D)."\n";
    }
    
    if($FixProbe) {
        writeFile($FixProbe."/devices", $HWData);
    }
    else {
        writeFile($DATA_DIR."/devices", $HWData);
    }
}

sub writeHost()
{
    my $Host = "";
    $Host .= "system:".$Sys{"System"}."\n";
    if($Sys{"SystemRel"}) {
        $Host .= "systemrel:".$Sys{"SystemRel"}."\n";
    }
    if($Sys{"Build"}) {
        $Host .= "build:".$Sys{"Build"}."\n"; # Live
    }
    $Host .= "user:".$Sys{"User"}."\n";
    $Host .= "node:".$Sys{"Node"}."\n";
    $Host .= "arch:".$Sys{"Arch"}."\n";
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
    if($Sys{"Board"}) {
        $Host .= "board:".$Sys{"Board"}."\n";
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
    if($FixProbe) {
        writeFile($FixProbe."/host", $Host);
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

sub writeLogs()
{
    print "Reading logs ... ";
    
    if($ListProbes) {
        print "\n";
    }
    
    my $KRel = $Sys{"Kernel"};
    
    # level=minimal
    listProbe("logs", "dmesg");
    my $Dmesg = `dmesg 2>&1`;
    writeLog($LOG_DIR."/dmesg", $Dmesg);
    
    if($Admin)
    {
        listProbe("logs", "dmesg.1");
        my $Dmesg_Old = `journalctl -a -k -b -1 -o short-monotonic 2>/dev/null | grep -v systemd`;
        $Dmesg_Old=~s/\]\s+.*?\s+kernel:/]/g;
        writeLog($LOG_DIR."/dmesg.1", $Dmesg_Old);
    }
    
    listProbe("logs", "xorg.log");
    my $XLog = readFile("/var/log/Xorg.0.log");
    writeLog($LOG_DIR."/xorg.log", $XLog);
    
    listProbe("logs", "xorg.log.1");
    my $XLog_Old = readFile("/var/log/Xorg.0.log.old");
    writeLog($LOG_DIR."/xorg.log.1", $XLog_Old);
    
    listProbe("logs", "xorg.conf");
    my $XorgConf = readFile("/etc/X11/xorg.conf");
    writeLog($LOG_DIR."/xorg.conf", $XorgConf);
    
    my $MonConf = "/etc/X11/xorg.conf.d/10-monitor.conf";
    if(-f $MonConf)
    { # Obsoleted
        listProbe("logs", "monitor.conf");
        my $MonitorConf = readFile($MonConf);
        writeLog($LOG_DIR."/monitor.conf", $MonitorConf);
    }
    
    if(-e "/etc/default/grub")
    {
        listProbe("logs", "grub");
        my $Grub = readFile("/etc/default/grub");
        writeLog($LOG_DIR."/grub", $Grub);
    }
    
    if(-f "/boot/grub2/grub.cfg")
    {
        listProbe("logs", "grub.cfg");
        my $GrubCfg = readFile("/boot/grub2/grub.cfg");
        writeLog($LOG_DIR."/grub.cfg", $GrubCfg);
    }
    
    if(-f "/var/log/boot.log")
    {
        listProbe("logs", "boot.log");
        my $BootLog = clearLog(readFile("/var/log/boot.log"));
        writeLog($LOG_DIR."/boot.log", $BootLog);
    }
    
    listProbe("logs", "xrandr");
    my $XRandr = `xrandr --verbose 2>&1`;
    writeLog($LOG_DIR."/xrandr", clearLog_X11($XRandr));
    
    listProbe("logs", "xrandr_providers");
    my $XRandrProviders = `xrandr --listproviders 2>&1`;
    writeLog($LOG_DIR."/xrandr_providers", clearLog_X11($XRandrProviders));
    
    listProbe("logs", "glxinfo");
    my $Glxinfo = `glxinfo 2>&1`;
    writeLog($LOG_DIR."/glxinfo", clearLog_X11($Glxinfo));
    
    listProbe("logs", "uname");
    my $Uname = `uname -a 2>&1`;
    writeLog($LOG_DIR."/uname", $Uname);
    
    if(check_Cmd("lsb_release"))
    {
        listProbe("logs", "lsb_release");
        my $Lsb = `lsb_release -i -d -r -c 2>&1`;
        writeLog($LOG_DIR."/lsb_release", $Lsb);
    }
    
    listProbe("logs", "os-release");
    my $OSRelease = readFile("/etc/os-release");
    writeLog($LOG_DIR."/os-release", $OSRelease);
    
    if(check_Cmd("update-alternatives"))
    {
        if($Sys{"system"}=~/rosa/i)
        {
            listProbe("logs", "update-alternatives");
            my $Alternatives = `update-alternatives --list 2>/dev/null`;
            writeLog($LOG_DIR."/update-alternatives", $Alternatives);
        }
    }
    
    listProbe("logs", "biosdecode");
    my $BiosDecode = "";
    if($Admin) {
        $BiosDecode = `biosdecode 2>/dev/null`;
    }
    writeLog($LOG_DIR."/biosdecode", $BiosDecode);
    
    listProbe("logs", "top");
    my $TopInfo = `top -n 1 -b 2>&1`;
    writeLog($LOG_DIR."/top", $TopInfo);
    
    listProbe("logs", "df");
    my $Df = `df -h 2>&1`;
    writeLog($LOG_DIR."/df", $Df);
    
    listProbe("logs", "meminfo");
    my $Meminfo = readFile("/proc/meminfo");
    writeLog($LOG_DIR."/meminfo", $Meminfo);
    
    # level=default
    if($LogLevel eq "default"
    or $LogLevel eq "maximal")
    {
        listProbe("logs", "sensors");
        my $Sensors = `sensors 2>/dev/null`;
        writeLog($LOG_DIR."/sensors", $Sensors);
        
        if(check_Cmd("cpupower"))
        {
            listProbe("logs", "cpupower");
            my $CPUpower = "";
            $CPUpower .= "frequency-info\n--------------\n";
            $CPUpower .= `cpupower frequency-info 2>&1`;
            $CPUpower .= "\n";
            $CPUpower .= "idle-info\n---------\n";
            $CPUpower .= `cpupower idle-info 2>&1`;
            writeLog($LOG_DIR."/cpupower", $CPUpower);
        }
        
        if(check_Cmd("dkms"))
        {
            listProbe("logs", "dkms_status");
            my $DkmsStatus = "";
            if($Admin) {
                $DkmsStatus = `dkms status 2>&1`;
            }
            writeLog($LOG_DIR."/dkms_status", $DkmsStatus);
        }
        
        listProbe("logs", "xdpyinfo");
        my $Xdpyinfo = `xdpyinfo 2>&1`;
        writeLog($LOG_DIR."/xdpyinfo", clearLog_X11($Xdpyinfo));
        
        if(check_Cmd("xinput"))
        {
            listProbe("logs", "xinput");
            my $XInput = `xinput list --long 2>&1`;
            writeLog($LOG_DIR."/xinput", clearLog_X11($XInput));
        }
        
        if(check_Cmd("rpm"))
        {
            listProbe("logs", "rpms");
            my $Rpms = `rpm -qa 2>/dev/null`; # default sorting - by date
            writeLog($LOG_DIR."/rpms", $Rpms);
        }
        
        if(check_Cmd("rfkill"))
        {
            listProbe("logs", "rfkill");
            my $Rfkill = `rfkill list 2>&1`;
            writeLog($LOG_DIR."/rfkill", $Rfkill);
        }
        
        if(check_Cmd("iw"))
        {
            listProbe("logs", "iw_list");
            my $Iw = `iw list 2>&1`;
            writeLog($LOG_DIR."/iw_list", $Iw);
        }
        
        if(check_Cmd("iwconfig"))
        {
            listProbe("logs", "iwconfig");
            my $IwConfig = `iwconfig 2>&1`;
            writeLog($LOG_DIR."/iwconfig", $IwConfig);
        }
        
        if(check_Cmd("hciconfig"))
        {
            listProbe("logs", "hciconfig");
            my $HciConfig = "";
            
            $HciConfig = `hciconfig -a 2>&1`;
            writeLog($LOG_DIR."/hciconfig", $HciConfig);
        }
        
        if(check_Cmd("nm-tool"))
        {
            listProbe("logs", "nm-tool");
            my $NmTool = `nm-tool 2>&1`;
            writeLog($LOG_DIR."/nm-tool", $NmTool);
        }
        
        if(check_Cmd("nmcli"))
        {
            listProbe("logs", "nmcli");
            my $NmCli = `nmcli c 2>&1`;
            writeLog($LOG_DIR."/nmcli", $NmCli);
        }
        
        if(check_Cmd("mmcli"))
        {
            listProbe("logs", "mmcli");
            my $Modems = `mmcli -L 2>&1`;
            if($Modems=~/No modems were found/i) {
                $Modems = "";
            }
            
            my %MNums = ();
            while($Modems=~s/Modem\/(\d+)//) {
                $MNums{$1} = 1;
            }
            
            my $MmCli = "";
            
            foreach my $Modem (sort {int($a)<=>int($b)} keys(%MNums))
            {
                my $MInfo = `mmcli -m $Modem`;
                $MInfo=~s/(own\s*\:\s*)(.+)/$1\-\-/;
                $MmCli .= $MInfo;
                
                $MmCli .= "\n";
            }
            
            writeLog($LOG_DIR."/mmcli", $MmCli);
        }
        
        listProbe("logs", "mount");
        my $Mount = `mount -v 2>&1`;
        writeLog($LOG_DIR."/mount", $Mount);
        
        listProbe("logs", "findmnt");
        my $Findmnt = `findmnt 2>&1`;
        writeLog($LOG_DIR."/findmnt", $Findmnt);
        
        if($Admin)
        {
            listProbe("logs", "fdisk");
            my $Fdisk = `fdisk -l 2>&1`;
            writeLog($LOG_DIR."/fdisk", $Fdisk);
        }
        
        if(check_Cmd("inxi"))
        {
            listProbe("logs", "inxi");
            my $Inxi = `inxi -Fxx -c 0 2>&1`;
            writeLog($LOG_DIR."/inxi", $Inxi);
        }
        
        if(-e "/sys/firmware/efi") # defined $KernMod{"efivarfs"}
        { # installed in EFI mode
            if(check_Cmd("efivar"))
            {
                listProbe("logs", "efivar");
                my $Efivar = `efivar -l 2>&1`;
                
                if($Efivar=~/error listing variables/i) {
                    $Efivar = "";
                }
                
                writeLog($LOG_DIR."/efivar", $Efivar);
            }
            
            if($Admin)
            {
                if($Sys{"Arch"} eq "x86_64")
                {
                    if(check_Cmd("efibootmgr"))
                    {
                        listProbe("logs", "efibootmgr");
                        my $Efibootmgr = `efibootmgr -v 2>&1`;
                        writeLog($LOG_DIR."/efibootmgr", $Efibootmgr);
                    }
                }
            }
            
            if(-d "/boot/efi")
            {
                listProbe("logs", "boot_efi");
                my $BootEfi = `find /boot/efi 2>/dev/null | sort`;
                writeLog($LOG_DIR."/boot_efi", $BootEfi);
            }
        }
        
        my $Switch = "/sys/kernel/debug/vgaswitcheroo/switch";
        if(-e $Switch)
        {
            listProbe("logs", "vgaswitcheroo");
            my $SInfo = readFile($Switch);
            writeLog($LOG_DIR."/vgaswitcheroo", $SInfo);
        }
        
        listProbe("logs", "input_devices");
        my $InputDevices = readFile("/proc/bus/input/devices");
        writeLog($LOG_DIR."/input_devices", $InputDevices);
        
        listProbe("logs", "pstree");
        my $Pstree = `pstree 2>&1`;
        writeLog($LOG_DIR."/pstree", $Pstree);
        
        listProbe("logs", "systemctl");
        my $Sctl = `systemctl 2>/dev/null`;
        writeLog($LOG_DIR."/systemctl", $Sctl);
        
        listProbe("logs", "dev");
        my $DevFiles = `find /dev -ls 2>/dev/null`;
        $DevFiles=~s/(\A|\n).*?\d+ \//$1\//g;
        writeLog($LOG_DIR."/dev", join("\n", sort split(/\n/, $DevFiles)));
        
        if(check_Cmd("acpi"))
        {
            listProbe("logs", "acpi");
            my $Acpi = `acpi -V 2>/dev/null`;
            writeLog($LOG_DIR."/acpi", $Acpi);
        }
        
        if(defined $KernMod{"fglrx"} and $KernMod{"fglrx"}!=0)
        {
            listProbe("logs", "fglrxinfo");
            my $Fglrxinfo = `fglrxinfo -t 2>&1`;
            writeLog($LOG_DIR."/fglrxinfo", $Fglrxinfo);
            
            listProbe("logs", "amdconfig");
            my $AMDconfig = `amdconfig --list-adapters 2>&1`;
            writeLog($LOG_DIR."/amdconfig", $AMDconfig);
        }
        elsif(defined $KernMod{"nvidia"} and $KernMod{"nvidia"}!=0)
        {
            foreach ("64", "")
            {
                my $NvidiaSmi_Path = "/usr/lib".$_."/nvidia/bin/nvidia-smi";
                
                if(-e $NvidiaSmi_Path)
                {
                    listProbe("logs", "nvidia-smi");
                    my $NvidiaSmi = `$NvidiaSmi_Path -q 2>&1`;
                    writeLog($LOG_DIR."/nvidia-smi", $NvidiaSmi);
                    last;
                }
            }
        }
        
        listProbe("logs", "lsblk");
        my $Lsblk = `lsblk -a 2>&1`;
        writeLog($LOG_DIR."/lsblk", $Lsblk);
        
        listProbe("logs", "blkid");
        my $Blkid = `blkid 2>&1`;
        writeLog($LOG_DIR."/blkid", $Blkid);
        
        listProbe("logs", "lscpu");
        my $Lscpu = `lscpu 2>&1`;
        writeLog($LOG_DIR."/lscpu", $Lscpu);
        
        listProbe("logs", "ioports");
        my $IOports = readFile("/proc/ioports");
        writeLog($LOG_DIR."/ioports", $IOports);
        
        listProbe("logs", "interrupts");
        my $Interrupts = readFile("/proc/interrupts");
        writeLog($LOG_DIR."/interrupts", $Interrupts);
        
        listProbe("logs", "fstab");
        my $Fstab = readFile("/etc/fstab");
        writeLog($LOG_DIR."/fstab", $Fstab);
        
        listProbe("logs", "aplay");
        my $Aplay = `aplay -l 2>&1`;
        writeLog($LOG_DIR."/aplay", $Aplay);
        
        listProbe("logs", "arecord");
        my $Arecord = `arecord -l 2>&1`;
        writeLog($LOG_DIR."/arecord", $Arecord);
        
        # listProbe("logs", "codec");
        # my $Codec = `cat /proc/asound/card*/codec* 2>&1`;
        # writeLog($LOG_DIR."/codec", $Codec);
        
        listProbe("logs", "amixer");
        my $Amixer = "";
        while($Aplay=~s/card\s+(\d+)//)
        {
            $Amixer .= `amixer -c$1 info 2>&1`;
            $Amixer .= `amixer -c$1 2>&1`;
            $Amixer .= "\n";
        }
        writeLog($LOG_DIR."/amixer", $Amixer);
        
        listProbe("logs", "alsactl");
        system("alsactl store -f $TMP_DIR/alsactl 2>/dev/null");
        if(-f "$TMP_DIR/alsactl") {
            move("$TMP_DIR/alsactl", $LOG_DIR."/alsactl");
        }
        
        if(check_Cmd("systemd-analyze"))
        {
            listProbe("logs", "systemd-analyze");
            my $SystemdAnalyze = `systemd-analyze blame 2>/dev/null`;
            writeLog($LOG_DIR."/systemd-analyze", $SystemdAnalyze);
        }
        
        listProbe("logs", "modprobe.d");
        my @Modprobe = listDir("/etc/modprobe.d/");
        my $Mprobe = "";
        foreach my $Mp (sort @Modprobe)
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
            
            $Content=~s&http(s|)://[^ ]+&&g;
            
            $Mprobe .= $Content;
            $Mprobe .= "\n\n";
        }
        writeLog($LOG_DIR."/modprobe.d", $Mprobe);
        
        listProbe("logs", "xorg.conf.d");
        my @XorgConfD = listDir("/etc/X11/xorg.conf.d/");
        my $XConfig = "";
        foreach my $Xc (sort @XorgConfD)
        {
            if($Xc!~/\.conf\Z/) {
                next;
            }
            $XConfig .= $Xc."\n";
            foreach (1 .. length($Xc)) {
                $XConfig .= "-";
            }
            $XConfig .= "\n";
            $XConfig .= readFile("/etc/X11/xorg.conf.d/".$Xc);
            $XConfig .= "\n\n";
        }
        writeLog($LOG_DIR."/xorg.conf.d", $XConfig);
        
        if($Scanners)
        {
            if(check_Cmd("sane-find-scanner"))
            {
                listProbe("logs", "sane-find-scanner");
                my $FindScanner = `sane-find-scanner -q 2>/dev/null`;
                writeLog($LOG_DIR."/sane-find-scanner", $FindScanner);
            }
            
            if(check_Cmd("scanimage"))
            {
                listProbe("logs", "scanimage");
                my $Scanimage = `scanimage -L 2>/dev/null | grep -v v4l`;
                if($Scanimage=~/No scanners were identified/i) {
                    $Scanimage = "";
                }
                writeLog($LOG_DIR."/scanimage", $Scanimage);
            }
        }
    }
    
    # level=maximal
    if($LogLevel eq "maximal")
    {
        # scan for available WiFi networks
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
                $IwScan .= `iw dev $I scan 2>&1`;
                $IwScan .= "\n";
            }
        }
        writeLog($LOG_DIR."/iw_scan", $IwScan);
        
        # scan for available bluetooth connections
        listProbe("logs", "hcitool_scan");
        my $HciScan = "";
        if(-s $LOG_DIR."/hciconfig") {
            $HciScan = `hcitool scan --class 2>&1`;
        }
        writeLog($LOG_DIR."/hcitool_scan", $HciScan);
        
        listProbe("logs", "route");
        my $Route = `route 2>&1`;
        writeLog($LOG_DIR."/route", $Route);
        
        listProbe("logs", "xvinfo");
        my $XVInfo = `xvinfo 2>&1`;
        writeLog($LOG_DIR."/xvinfo", clearLog_X11($XVInfo));
        
        if(check_Cmd("vdpauinfo"))
        {
            listProbe("logs", "vdpauinfo");
            my $Vdpauinfo = `vdpauinfo 2>&1`;
            if($Vdpauinfo=~/Failed to open/i) {
                $Vdpauinfo = "";
            }
            if($Vdpauinfo) {
                writeLog($LOG_DIR."/vdpauinfo", clearLog_X11($Vdpauinfo));
            }
        }
        
        if($Printers)
        {
            if($Admin)
            {
                my $ELog = "/var/log/cups/error_log";
                if(-e $ELog)
                {
                    listProbe("logs", "cups_error_log");
                    my $CupsError = readFile($ELog);
                    writeLog($LOG_DIR."/cups_error_log", $CupsError);
                }
                
                my $ALog = "/var/log/cups/access_log";
                if(-e $ALog)
                {
                    listProbe("logs", "cups_access_log");
                    my $CupsAccess = readFile($ALog); 
                    writeLog($LOG_DIR."/cups_access_log", $CupsAccess);
                }
            }
        }
        
        # Disabled as it can hang your system
        # my $SuperIO = "";
        # if($Admin) {
        #     $SuperIO = `superiotool -d 2>/dev/null`;
        # }
        # writeLog($LOG_DIR."/superiotool", $SuperIO);
    }
    
    if($DumpACPI)
    {
        listProbe("logs", "acpidump");
        my $AcpiDump = ""; # pmtools
        
        # To decode acpidump:
        #  1. acpixtract -a acpidump
        #  2. iasl -d ECDT.dat
        
        if($Admin)
        {
            if(check_Cmd("acpidump")) {
                $AcpiDump = `acpidump 2>/dev/null`;
            }
        }
        writeLog($LOG_DIR."/acpidump", $AcpiDump);
        
        if($DecodeACPI)
        {
            if(-s $LOG_DIR."/acpidump") {
                decodeACPI($LOG_DIR."/acpidump", $LOG_DIR."/acpidump_decoded");
            }
        }
    }
    
    print "Ok\n";
}

sub check_Cmd($)
{
    my $Cmd = $_[0];
    return "" if(not $Cmd);
    
    if(-x $Cmd)
    { # relative or absolute path
        return 1;
    }
    
    foreach my $Path (sort {length($a)<=>length($b)} split(/:/, $ENV{"PATH"}))
    {
        if(-x $Path."/".$Cmd) {
            return 1;
        }
    }
    return 0;
}

sub decodeACPI($$)
{
    my ($Dump, $Output) = @_;
    $Dump = abs_path($Dump);
    
    if(not check_Cmd("acpixtract")
    or not check_Cmd("iasl")) {
        return;
    }
    
    my $Dir = $TMP_DIR."/acpi";
    mkpath($Dir);
    chdir($Dir);
    
    # list data
    my $DSL = `acpixtract -l \"$Dump\" 2>&1`;
    $DSL .= "\n";
    
    # extract *.dat
    system("acpixtract -a \"$Dump\" >/dev/null 2>&1");
    
    # decode *.dat
    my @Files = listDir(".");
    
    foreach my $File (sort @Files)
    {
        if($File=~/\A(.+)\.dat\Z/)
        {
            my $Name = $1;
            
            if($Name=~/dsdt/i) {
                # next;
            }
            
            my $Log2 = `iasl -d \"$File\" 2>&1`;
            
            my $DslFile = $Name.".dsl";
            if(-f $DslFile)
            {
                $DSL .= uc($Name)."\n";
                foreach (1 .. length($Name)) {
                    $DSL .= "-";
                }
                $DSL .= "\n";
                my $Data = readFile($DslFile);
                $Data=~s&\A\s*/\*.*?\*/\s*&&sg;
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
}

sub clearLog_X11($)
{
    if(length($_[0])<100
    and $_[0]=~/No protocol specified/i) {
        return "";
    }
    
    return $_[0];
}

sub clearLog($)
{
    my $Log = $_[0];
    
    my $Sc = chr(27);
    $Log=~s/$Sc\[.*?m//g;
    
    return $Log;
}

sub showInfo()
{
    my $ShowDir = $DATA_DIR;
    
    if($Source)
    {
        if(-f $Source)
        {
            if(isPkg($Source))
            {
                my $Pkg = abs_path($Source);
                chdir($TMP_DIR);
                system("tar", "-m", "-xf", $Pkg);
                chdir($ORIG_DIR);
                
                if($?)
                {
                    print STDERR "ERROR: failed to extract package (".$?.")\n";
                    exit(1);
                }
                
                if(my @Dirs = listDir($TMP_DIR)) {
                    $ShowDir = $TMP_DIR."/".$Dirs[0];
                }
                else
                {
                    print STDERR "ERROR: failed to extract package\n";
                    exit(1);
                }
            }
            else
            {
                print STDERR "ERROR: not a package\n";
                exit(1);
            }
        }
        elsif(-d $Source)
        {
            $ShowDir = $Source;
        }
        else
        {
            print STDERR "ERROR: can't access \'$Source\'\n";
            exit(1);
        }
    }
    else
    {
        if(not -d $DATA_DIR)
        {
            print STDERR "ERROR: \'".$DATA_DIR."\' is not found, please make probe first\n";
            exit(1);
        }
    }
    
    my %Tbl;
    my %STbl;
    
    foreach (split(/\s*\n\s*/, readFile($ShowDir."/devices")))
    {
        my @Info = split(";", $_);
        
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
        
        foreach my $Attr (keys(%Dev))
        {
            if(not defined $Tbl{$Attr}) {
                $Tbl{$Attr} = [];
            }
            
            my $Val = $Dev{$Attr};
            
            if($Attr eq "ID")
            {
                if(index($Val, "-serial-")!=-1) {
                    $Val=~s/\-serial\-(.+?)\Z/ [$1]/;
                }
            }
            
            if($Compact)
            {
                if($Attr eq "ID")
                {
                    if(length($Val)>23)
                    {
                        $Val = substr($Val, 0, 23);
                    }
                }
                elsif($Attr eq "Vendor")
                {
                    if(length($Val)>22)
                    {
                        $Val = substr($Val, 0, 22);
                    }
                }
                elsif($Attr eq "Device")
                {
                    if(length($Val)>40)
                    {
                        $Val = substr($Val, 0, 40);
                    }
                }
                elsif($Attr eq "Type")
                {
                    if(length($Val)>14)
                    {
                        $Val = substr($Val, 0, 14);
                    }
                }
            }
            
            push(@{$Tbl{$Attr}}, $Val);
        }
    }
    
    foreach (split(/\s*\n\s*/, readFile($ShowDir."/host")))
    {
        if(/(\w+):(.*)/)
        {
            my ($Attr, $Val) = ($1, $2);
            
            if($Compact)
            {
                if($Attr eq "id")
                {
                    if(length($Val)>25) {
                        $Val = substr($Val, 0, 25);
                    }
                }
            }
            
            $STbl{$Attr} = $Val;
        }
    }
    
    my $Rows = $#{$Tbl{"ID"}};
    
    print "\n";
    print "Total devices: ".($Rows + 1)."\n";
    
    if(defined $Verbose) {
        showTable(\%Tbl, $Rows, "ID", "Class", "Status", "Type", "Vendor", "Device");
    }
    else {
        showTable(\%Tbl, $Rows, "ID", "Class", "Vendor", "Device");
    }
    
    print "\n";
    print "Host Info\n";
    showHash(\%STbl, "system", "user", "node", "arch", "kernel", "vendor", "model", "year", "board", "hwaddr", "type", "id");
}

sub showTable(@)
{
    my $Tbl = shift(@_);
    my $Num = shift(@_);
    
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
    
    foreach my $Col (@_)
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
        foreach my $Col (@_)
        {
            my $El = $Tbl->{$Col}[$Row];
            print "| ".$El;
            print alignStr($El, $Max{$Col} + 1);
        }
        print "|\n";
    }
    
    print $Br."\n";
}

sub showHash(@)
{
    my $Hash = shift(@_);
    
    my $KMax = 0;
    my $VMax = 0;
    
    foreach my $Key (sort keys(%{$Hash}))
    {
        my $Val = $Hash->{$Key};
        if(length($Val) > $VMax) {
            $VMax = length($Val);
        }
        if(length($Key) > $KMax) {
            $KMax = length($Key);
        }
    }
    
    my $Br = "+";
    $Br .= mulCh("-", $KMax + 2);
    $Br .= "+";
    $Br .= mulCh("-", $VMax + 2);
    $Br .= "+";
    
    foreach my $Key (@_)
    {
        my $Val = $Hash->{$Key};
        
        print $Br."\n";
        
        print "| ";
        print ucfirst($Key);
        print alignStr($Key, $KMax + 1);
        print "| ";
        print $Val;
        print alignStr($Val, $VMax + 1);
        print "|\n";
    }
    
    print $Br."\n";
    print "\n";
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
    
    foreach (1 .. $_[1] - length($_[0]))
    {
        $Align .= " ";
    }
    
    return $Align;
}

sub checkHW()
{
    # TODO: test operability, set status to "works" or "failed"
    
    print "Run tests ... ";
    
    if($ListProbes) {
        print "\n";
    }
    
    my $GlxgearsCmd = getTestCmd("glxgears", "glxgears");
    
    if($KernMod{"nouveau"}!=0 or $KernMod{"radeon"}!=0 or $KernMod{"i915"}!=0
    or $KernMod{"fglrx"}!=0)
    { # check free driver
        listProbe("tests", "glxgears");
        my $Glxgears = `vblank_mode=0 $GlxgearsCmd`;
        $Glxgears=~s/(\d+ frames)/\n$1/;
        $Glxgears=~s/GL_EXTENSIONS =.*?\n//;
        writeLog($TEST_DIR."/glxgears", $Glxgears);
    }
    
    if($KernMod{"fglrx"}!=0)
    { # check Radeon card with proprietary driver
        # listProbe("tests", "fgl_glxgears");
        # my $FGl_GlxgearsCmd = getTestCmd("fgl_glxgears", "PBuffer GLXGears");
        # my $FGl_Glxgears = `$FGl_GlxgearsCmd`;
        # $FGl_Glxgears=~s/(\d+ frames)/\n$1/;
        # $FGl_Glxgears=~s/GL_EXTENSIONS =.*?\n//;
        # writeLog($TEST_DIR."/fgl_glxgears", $FGl_Glxgears);
    }
    elsif($KernMod{"nvidia"}!=0)
    {
        if($KernMod{"i915"}!=0)
        { # check NVidia Optimus with proprietary driver
            listProbe("tests", "optirun_glxgears");
            my $Glxgears = `optirun $GlxgearsCmd`;
            $Glxgears=~s/(\d+ frames)/\n$1/;
            $Glxgears=~s/GL_EXTENSIONS =.*?\n//;
            writeLog($TEST_DIR."/optirun_glxgears", $Glxgears);
        }
        else
        { # check NVidia card with proprietary driver
            
        }
    }
    elsif($KernMod{"nouveau"}!=0 and $KernMod{"i915"}!=0)
    { # check NVidia Optimus with free driver
        
    }
    elsif($KernMod{"radeon"}!=0 and $KernMod{"i915"}!=0)
    { # check Radeon Hybrid graphics with free driver
        
    }
    
    print "Ok\n";
}

sub getTestCmd($$)
{
    my ($Cmd, $Win) = @_;
    return $Cmd." -info 2>/dev/null & sleep 17 ; xwininfo -name \'$Win\' ; xkill -id \$(xwininfo -name \'$Win\' | grep \"Window id\" | cut -d' ' -f4) >/dev/null";
}

sub listProbe($$)
{
    if($ListProbes) {
        print $_[0]."/".$_[1]."\n";
    }
}

sub writeLog($$)
{
    my ($Path, $Content) = @_;
    
    writeFile(@_);
}

sub appendFile($$)
{
    my ($Path, $Content) = @_;
    return if(not $Path);
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
    
    my ($V, $D, $SV, $SD) = ();
    
    foreach (split(/\n/, $List))
    {
        if(/\A(\t*)(\w{4}) /)
        {
            my $L = length($1);
            
            if($L==0) {
                $V = $2;
            }
            elsif($L==1)
            {
                $D = $2;
                
                if(/\t\w{4}\s+(.*?)\Z/) {
                    $Info->{$V}{$D} = $1;
                }
            }
            elsif($L==2)
            {
                if(/\t(\w{4}) (\w{4})\s+(.*?)\Z/)
                {
                    $SV = $1;
                    $SD = $2;
                    
                    $Info_D->{$V}{$D}{$SV}{$SD} = $3;
                }
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
        if(/\A(\t*)(\w{4}) /)
        {
            my $L = length($1);
            
            if($L==0) {
                $V = $2;
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

sub readSdioIds_Sys() {
    readSdioIds("/usr/share/hwdata/sdio.ids", \%SdioInfo, \%SdioVendor);
}

sub readSdioIds($$$)
{
    if(not -e $_[0]) {
        return;
    }
    
    my $List = readFile($_[0]);
    
    my $Info = $_[1];
    my $Vnds = $_[2];
    
    my ($V, $D) = ();
    
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

sub scenario()
{
    if($Help)
    {
        helpMsg();
        exit(0);
    }
    
    if($DumpVersion)
    {
        print $TOOL_VERSION."\n";
        exit(0);
    }
    
    if($ShowVersion)
    {
        print $ShortUsage;
        exit(0);
    }
    
    if($LogLevel)
    {
        if($LogLevel=~/\A(min|mini|minimum)\Z/i) {
            $LogLevel = "minimal";
        }
        elsif($LogLevel=~/\A(max|maxi|maximum)\Z/i) {
            $LogLevel = "maximal";
        }
        
        if($LogLevel!~/\A(minimal|default|maximal)\Z/i)
        {
            print STDERR "ERROR: unknown log level \'$LogLevel\'\n";
            exit(1);
        }
        
        $LogLevel = lc($LogLevel);
        $Logs = 1;
    }
    else {
        $LogLevel = "default";
    }
    
    if($All)
    {
        $Probe = 1;
        $Logs = 1;
    }
    
    if($Probe and not $FixProbe)
    {
        if(-d $DATA_DIR)
        {
            if(not -w $DATA_DIR)
            {
                print STDERR "ERROR: can't write to \'$DATA_DIR\', please run as root\n";
                exit(1);
            }
            rmtree($DATA_DIR);
        }
    }
    
    if($Probe)
    {
        if(not $Admin)
        {
            print STDERR "ERROR: you should run as root (su)\n";
            exit(1);
        }
        else
        {
            if(defined $ENV{"SUDO_COMMAND"}
            and $ENV{"SUDO_USER"} ne "root")
            {
                print STDERR "ERROR: please use \"su\" instead of \"sudo\"\n";
                exit(1);
            }
        }
    }
    
    if($PciIDs)
    {
        if(not -e $PciIDs)
        {
            print STDERR "ERROR: can't access \'$PciIDs\'\n";
            exit(1);
        }
        readPciIds($PciIDs, \%PciInfo, \%PciInfo_D);
        
        if(-e $PciIDs.".add") {
            readPciIds($PciIDs.".add", \%AddPciInfo, \%AddPciInfo_D);
        }
    }
    
    if($UsbIDs)
    {
        if(not -e $UsbIDs)
        {
            print STDERR "ERROR: can't access \'$UsbIDs\'\n";
            exit(1);
        }
        readUsbIds($UsbIDs, \%UsbInfo);
        
        if(-e $UsbIDs.".add") {
            readUsbIds($UsbIDs.".add", \%AddUsbInfo);
        }
    }
    
    if($SdioIDs)
    {
        if(not -e $SdioIDs)
        {
            print STDERR "ERROR: can't access \'$SdioIDs\'\n";
            exit(1);
        }
        readSdioIds($SdioIDs, \%SdioInfo, \%SdioVendor);
        
        if(-e $SdioIDs.".add") {
            readSdioIds($SdioIDs.".add", \%AddSdioInfo, \%AddSdioVendor);
        }
    }
    
    if($PnpIDs)
    {
        if(not -e $PnpIDs)
        {
            print STDERR "ERROR: can't access \'$PnpIDs\'\n";
            exit(1);
        }
    }
    
    if($FixProbe)
    {
        if(not -e $FixProbe)
        {
            print STDERR "ERROR: can't access \'$FixProbe\'\n";
            exit(1);
        }
        
        if($FixProbe=~/\.(tar\.xz|txz)\Z/)
        { # package
            $FixProbe_Pkg = abs_path($FixProbe);
            $FixProbe = $FixProbe_Pkg;
            
            chdir($TMP_DIR);
            system("tar", "-m", "-xf", $FixProbe);
            chdir($ORIG_DIR);
            
            $FixProbe = $TMP_DIR."/hw.info";
        }
        elsif(-f $FixProbe)
        {
            print STDERR "ERROR: unsupported probe format \'$FixProbe\'\n";
            exit(1);
        }
        
        $FixProbe=~s/[\/]+\Z//g;
        $FixProbe_Logs = $FixProbe."/logs";
        
        if(-d $FixProbe)
        {
            if(not -e $FixProbe_Logs."/hwinfo")
            {
                print STDERR "ERROR: can't find logs in \'$FixProbe\'\n";
                exit(1);
            }
        }
        else
        {
            print STDERR "ERROR: can't access \'$FixProbe\'\n";
            exit(1);
        }
        
        $Logs = 0;
    }
    
    if($Probe or $Check)
    {
        probeSys();
        probeHWaddr();
        probeHW();
        
        writeDevs();
        writeHost();
        
        if($Logs) {
            writeLogs();
        }
        
        if($Check)
        {
            checkHW();
            
            if(keys(%TestRes))
            {
                # Update
                writeDevs();
                writeHost();
            }
        }
        
        if($Key) {
            writeFile($DATA_DIR."/key", $Key);
        }
    }
    elsif($FixProbe)
    {
        readHost($FixProbe); # instead of probeSys
        probeHWaddr();
        probeHW();
        
        if($PC_Name) {
            $Sys{"Name"} = $PC_Name; # fix PC name
        }
        
        my ($Distr, $Rel) = probeDistr();
        
        if($Distr)
        { # fix system name
            $Sys{"System"} = $Distr;
        }
        
        if($Rel)
        { # fix system name
            $Sys{"SystemRel"} = $Rel;
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
                    print STDERR "ERROR: failed to fix 'system' attribute (kernel is '".$Sys{"Kernel"}."')\n";
                }
            }
            
            if(not $Sys{"SystemRel"})
            {
                if($Sys{"System"} eq "rosa-2012.1")
                {
                    if($Sys{"Kernel"}=~/\A3\.10\.(3\d|4\d)\-/) {
                        $Sys{"SystemRel"} = "rosafresh-r3";
                    }
                    elsif($Sys{"Kernel"}=~/\A3\.10\.19\-/) {
                        $Sys{"SystemRel"} = "rosafresh-r2";
                    }
                    elsif($Sys{"Kernel"}=~/\A3\.8\.12\-/) {
                        $Sys{"SystemRel"} = "rosafresh-r1";
                    }
                }
            }
        }
        
        $Sys{"Model"} = fixModel($Sys{"Vendor"}, $Sys{"Model"}, $Sys{"Version"});
        if($DecodeACPI)
        {
            if(-f $FixProbe."/logs/acpidump") {
                decodeACPI($FixProbe."/logs/acpidump", $FixProbe."/logs/acpidump_decoded");
            }
        }
        
        writeDevs();
        writeHost();
        
        if($FixProbe_Pkg)
        { # package
            chdir($TMP_DIR);
            system("tar", "-cJf", $FixProbe_Pkg, "hw.info");
            chdir($ORIG_DIR);
            
            if($?) {
                print STDERR "ERROR: can't create a package\n";
            }
            
            rmtree($TMP_DIR."/hw.info");
        }
    }
    
    if($Show) {
        showInfo();
    }
    
    if($Upload)
    {
        uploadData();
        cleanData();
    }
    
    if($GetGroup)
    {
        getGroup();
    }
    
    exit(0);
}

scenario();
