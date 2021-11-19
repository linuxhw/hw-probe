#!/bin/sh
if [ $# -eq 0 ]; then
    hw-probe-snap -snap
else
    hw-probe-snap -snap "$@"
fi
