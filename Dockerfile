FROM alpine:3.11

RUN apk update \
    && apk add --no-cache perl curl xz dmidecode pciutils usbutils \
    smartmontools hdparm sysstat util-linux lm_sensors acpi iw wireless-tools \
    alsa-utils xrandr xdpyinfo xinput acpica iasl perl-libwww \
    && apk add --no-cache --virtual build-deps git gcc g++ make libc-dev util-linux-dev flex linux-headers glib-dev libxrandr-dev zlib-dev findutils \
    && git clone https://git.linuxtv.org/edid-decode.git \
    && cd edid-decode \
    && make \
    && find . -type f | perl -lne 'print if -B and -x' | xargs strip \
    && make install \
    && cd .. \
    && rm -fr edid-decode \
    && curl -L https://github.com/linuxhw/build-stuff/releases/download/1.5/ddcutil-20200211.tar.xz > ddcutil-20200211.tar.xz \
    && tar -xf ddcutil-20200211.tar.xz \
    && cd ddcutil-20200211 \
    && NOCONFIGURE=1 NO_CONFIGURE=1 sh autogen.sh \
    && ./configure --prefix=/usr \
    && make \
    && find . -type f | perl -lne 'print if -B and -x' | xargs strip \
    && make install \
    && cd .. \
    && rm -fr ddcutil-20200211 \
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
    && apk del build-deps

ENV LD_LIBRARY_PATH /usr/lib64:/usr/lib
ENV DISPLAY :0

ENTRYPOINT ["/usr/bin/hw-probe", "-docker"]
