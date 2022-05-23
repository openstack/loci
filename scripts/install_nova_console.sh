#!/bin/bash

set -ex

# Nova console is a special case. The html files needed to make this work
# exist only upstream. The "packaged" versions of these come only from
# OpenStack specific repos and they have hard requirements to a massive
# amount of packages. Installing from "source" is the only way to get
# these html files into the container. In total this adds less than a MB
# to the image size

NOVNC_DIR=/usr/share/novnc
SPICE_DIR=/usr/share/spice-html5

mkdir ${NOVNC_DIR}
git clone -b ${NOVNC_REF} --depth 1 ${NOVNC_REPO} ${NOVNC_DIR}
rm -rf ${NOVNC_DIR}/.git*
if [[ ! -f /usr/share/novnc/vnc_auto.html ]]; then
    # novnc >= 1.0.0 is installed
    ln -s vnc_lite.html ${NOVNC_DIR}/vnc_auto.html
fi

mkdir ${SPICE_DIR}
git clone -b ${SPICE_REF} --depth 1 ${SPICE_REPO} ${SPICE_DIR}
rm -rf ${SPICE_DIR}/.git*
