#!/bin/bash

set -ex

distro=$(awk -F= '/^ID=/ {gsub(/\"/, "", $2); print $2}' /etc/*release)
export distro=${DISTRO:=$distro}

case ${distro} in
    debian|ubuntu)
        apt-get update
        apt-get upgrade -y
        apt-get install -y --no-install-recommends \
            git \
            ca-certificates \
            netbase \
            python \
            virtualenv \
            lsb-release \
            sudo
        ;;
    centos)
        yum upgrade -y
        yum install -y --setopt=skip_missing_names_on_install=False \
            git \
            python \
            python-virtualenv \
            redhat-lsb-core \
            sudo
        ;;
    *)
        echo "Unknown distro: ${distro}"
        exit 1
        ;;
esac

if [[ "${PROJECT}" == "requirements" ]]; then
    $(dirname $0)/requirements.sh
    exit 0
fi

$(dirname $0)/fetch_wheels.sh
if [[ "${PLUGIN}" == "no" ]]; then
    $(dirname $0)/create_user.sh
    $(dirname $0)/setup_pip.sh
    $(dirname $0)/pip_install.sh \
        bindep==2.5.1.dev1 \
        pycrypto \
        pymysql \
        python-memcached \
        uwsgi
fi

$(dirname $0)/clone_project.sh
$(dirname $0)/pip_install.sh /tmp/${PROJECT} ${PIP_PACKAGES}
$(dirname $0)/install_packages.sh
$(dirname $0)/cleanup.sh
