#!/bin/bash

set -ex

python3=python3

for file in /opt/loci/bindep*; do
    PACKAGES+=($(bindep -f $file -b -l newline ${PROJECT} ${PROFILES} ${python3} ${DISTRO_RELEASE} || :))
done

if [[ ! -z ${PACKAGES} ]]; then
    case ${distro} in
        debian|ubuntu)
            DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${PACKAGES[@]} ${DIST_PACKAGES}
            ;;
        centos)
            yum -y --setopt=skip_missing_names_on_install=False install ${PACKAGES[@]} ${DIST_PACKAGES}
            ;;
        opensuse|opensuse-leap|opensuse-tumbleweed|sles)
            zypper --non-interactive install --no-recommends ${PACKAGES[@]} ${DIST_PACKAGES}
            ;;
        *)
            echo "Unknown distro: ${distro}"
            exit 1
            ;;
    esac
fi
