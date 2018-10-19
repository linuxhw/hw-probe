#!/bin/sh
if [ $# -eq 0 ]; then
    perl /app/bin/hw-probe-flatpak -flatpak
else
    perl /app/bin/hw-probe-flatpak -flatpak "$@"
fi
