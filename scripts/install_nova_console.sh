#!/bin/bash

set -ex

# NOTE(SamYaple): Nova console is a special case. The html files needed to make
# this work exist only upstream. The "packaged" versions of these come only
# from openstack specific repos and they have hard requirements to a massive
# amount of packages. Installing from "source" is the only way to get these
# html files into the container. In total this adds less than a MB to the image
# size

mkdir /usr/share/novnc
git clone -b ${NOVNC_REF} --depth 1 ${NOVNC_REPO} /usr/share/novnc

mkdir /usr/share/spice-html5
git clone -b ${SPICE_REF} --depth 1 ${SPICE_REPO} /usr/share/spice-html5
