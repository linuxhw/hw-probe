FROM alpine:3.11

RUN apk update \
    && apk add --no-cache perl curl xz dmidecode pciutils usbutils \
    smartmontools hdparm sysstat util-linux util-linux-dev lm_sensors acpi iw wireless-tools \
    alsa-utils xrandr xdpyinfo xinput acpica iasl perl-libwww \
    && apk add --no-cache --virtual build-deps git gcc g++ make libc-dev flex linux-headers \
    && git clone https://git.linuxtv.org/edid-decode.git \
    && cd edid-decode \
    && make \
    && make install \
    && cd .. \
    && rm -fr edid-decode \
    && git clone https://github.com/wfeldt/libx86emu.git \
    && cd libx86emu \
    && make \
    && make install \
    && cd .. \
    && rm -fr libx86emu \
    && git clone https://github.com/openSUSE/hwinfo.git \
    && cd hwinfo \
    && make \
    && make install \
    && cd .. \
    && rm -fr hwinfo \
    && git clone https://github.com/linuxhw/hw-probe.git \
    && cd hw-probe \
    && git checkout tags/1.5 -b v1.5 \
    && make install \
    && cd .. \
    && rm -fr hw-probe \
    && apk del build-deps

ENV LD_LIBRARY_PATH /usr/lib64:/usr/lib
ENV DISPLAY :0

ENTRYPOINT ["/usr/bin/hw-probe", "-docker"]
