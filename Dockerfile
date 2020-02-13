FROM alpine:3.11

RUN apk update \
    && apk add --no-cache perl curl xz dmidecode pciutils usbutils \
    smartmontools hdparm sysstat util-linux lm_sensors acpi iw wireless-tools glib libxrandr zlib eudev libusb libdrm  \
    alsa-utils xrandr xdpyinfo xinput acpica iasl perl-libwww \
    && apk add --no-cache --virtual build-deps git gcc g++ make libc-dev util-linux-dev flex linux-headers glib-dev libxrandr-dev zlib-dev eudev-dev libusb-dev libdrm-dev \
    && git clone https://git.linuxtv.org/edid-decode.git 2>/dev/null \
    && cd edid-decode \
    && make \
    && find . -type f | perl -lne 'print if -B and -x' | xargs strip \
    && make install \
    && cd .. \
    && rm -fr edid-decode \
    && git clone https://github.com/rockowitz/ddcutil.git \
    && cd ddcutil \
    && git checkout 0.9.9-dev \
    && ./configure --prefix=/usr \
    && make \
    && find . -type f | perl -lne 'print if -B and -x' | xargs strip \
    && make install \
    && cd .. \
    && rm -fr ddcutil \
    && git clone https://github.com/wfeldt/libx86emu.git \
    && cd libx86emu \
    && make \
    && find . -type f | perl -lne 'print if -B and -x' | xargs strip \
    && make install \
    && cd .. \
    && rm -fr libx86emu \
    && git clone https://github.com/openSUSE/hwinfo.git \
    && cd hwinfo \
    && make \
    && find . -type f | perl -lne 'print if -B and -x' | xargs strip \
    && make install \
    && cd .. \
    && rm -fr hwinfo \
    && curl -L https://github.com/linuxhw/build-stuff/releases/download/1.5/hw-probe-1.5-AI.tar.gz > hw-probe-1.5-AI.tar.gz \
    && tar -xf hw-probe-1.5-AI.tar.gz \
    && cd hw-probe-1.5-AI \
    && make install \
    && cd .. \
    && rm -fr hw-probe-1.5-AI \
    && apk del build-deps \
    && rm -fr /usr/bin/{acpibin,acpiexamples,acpiexec,acpihelp,acpinames,acpisrc,lsusb.py,usbhid-dump} \
    && rm -fr /usr/sbin/{convert_hd,check_hd,mk_isdnhwdb,getsysinfo,fancontrol,pwmconfig,isadump,isaset,ownership,setpci,vpddecode,update-smart-drivedb,smartd} \
    && rm -fr /usr/share/{man,doc,pkgconfig,cmake,ddcutil} \
    && rm -fr /usr/include \
    && rm -fr /usr/lib/{pkgconfig,systemd} \
    && rm -fr /usr/share/perl5/vendor_perl/libwww/*.pod \
    && rm -fr /usr/bin/lwp-*

ENV LD_LIBRARY_PATH /usr/lib64:/usr/lib
ENV DISPLAY :0

ENTRYPOINT ["/usr/bin/hw-probe", "-docker"]
