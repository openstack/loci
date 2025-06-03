#!/bin/bash

set -ex

source /etc/lsb-release

for file in /opt/loci/bindep*; do
    PACKAGES+=($(bindep -f $file -b -l newline ${PROJECT} ${PROFILES} ${DISTRIB_CODENAME} || :))
done

if [[ ! -z ${PACKAGES} ]]; then
    apt-get install -y --no-install-recommends ${PACKAGES[@]} ${DIST_PACKAGES}
fi
