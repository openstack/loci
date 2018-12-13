#!/bin/bash

set -ex

if [[ "${PYTHON3}" != "no" ]]; then
    python3=python3
fi

for file in /opt/loci/bindep*; do
    PACKAGES+=($(bindep -f $file -b -l newline ${PROJECT} ${PROFILES} ${python3} || :))
done

if [[ ! -z ${PACKAGES} ]]; then
    case ${distro} in
        debian|ubuntu)
            apt-get install -y --no-install-recommends ${PACKAGES[@]} ${DIST_PACKAGES}
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
