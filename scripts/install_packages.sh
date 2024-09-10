#!/bin/bash

set -ex

for file in /opt/loci/bindep*; do
    PACKAGES+=($(bindep -f $file -b -l newline ${PROJECT} ${PROFILES} ${distro_version} || :))
done

if [[ ! -z ${PACKAGES} ]]; then
    case ${distro} in
        ubuntu)
            apt-get install -y --no-install-recommends ${PACKAGES[@]} ${DIST_PACKAGES}
            ;;
        centos)
            yum -y --setopt=skip_missing_names_on_install=False install ${PACKAGES[@]} ${DIST_PACKAGES}
            ;;
        *)
            echo "Unknown distro: ${distro}"
            exit 1
            ;;
    esac
fi
