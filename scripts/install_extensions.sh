#!/bin/bash

set -ex

distro=$(awk -F= '/^ID=/ {gsub(/\"/, "", $2); print $2}' /etc/*release)
export distro=${DISTRO:=$distro}

case ${distro} in
    debian|ubuntu)
        apt-get update
        ;;
    centos)
        yum upgrade -y
        ;;
    opensuse|opensuse-leap|opensuse-tumbleweed|sles)
        zypper --non-interactive --gpg-auto-import-keys refresh
        ;;
    *)
        echo "Unknown distro: ${distro}"
        exit 1
        ;;
esac

$(dirname $0)/fetch_wheels.sh

$(dirname $0)/clone_project.sh

# should now come from https://objectstore-3.eu-de-1.cloud.sap/v1/AUTH_caa6209d2c38450f8266311fd0f05446/sapcc-pypi/aci-python-bindings/
# special neutron aci drivers installation sauce
#if [[ ${PROJECT} == 'neutron' ]]; then
#    $(dirname $0)/install_apic.sh
#fi

$(dirname $0)/pip_install_extensions.sh
$(dirname $0)/cleanup.sh
