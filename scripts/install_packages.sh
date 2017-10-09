#!/bin/bash

set -ex

PACKAGES=($(bindep -f /opt/loci/bindep.txt -b ${PROJECT} ${PROFILES} || :))

if [[ ! -z ${PACKAGES} ]]; then
    case ${distro} in
        debian|ubuntu)
            apt-get install -y --no-install-recommends ${PACKAGES[@]}
            ;;
        centos)
            yum -y --setopt=skip_missing_names_on_install=False install ${PACKAGES[@]}
            ;;
        *)
            echo "Unknown distro: ${distro}"
            exit 1
            ;;
    esac
fi
