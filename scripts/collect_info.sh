#!/bin/bash

set -ex

INFO_DIR="/etc/image_info"
mkdir -p $INFO_DIR
PACKAGES_INFO="${INFO_DIR}/packages.txt"
PIP_INFO="${INFO_DIR}/pip.txt"

case ${distro} in
    debian|ubuntu)
        dpkg -l > $PACKAGES_INFO
        ;;
    centos)
        yum list installed > $PACKAGES_INFO
        ;;
    opensuse|opensuse-leap|opensuse-tumbleweed|sles)
        zypper se --installed-only > $PACKAGES_INFO
        ;;
    *)
        echo "Unknown distro: ${distro}"
        exit 1
        ;;
esac

pip freeze > $PIP_INFO
