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

if [[ "${PROJECT}" == 'requirements' ]]; then
    $(dirname $0)/requirements.sh
    exit 0
fi

$(dirname $0)/fetch_wheels.sh
$(dirname $0)/setup_pip.sh
$(dirname $0)/clone_project.sh
$(dirname $0)/pip_install.sh \
        /tmp/${PROJECT} \
        pycrypto \
        pymysql \
        python-memcached \
        uwsgi \
        bindep \
        ${PIP_PACKAGES}

PACKAGES=($(bindep -f /opt/loci/bindep.txt -b ${PROJECT} ${PROFILES} || :))

groupadd -g 42424 ${PROJECT}
useradd -u 42424 -g ${PROJECT} -M -d /var/lib/${PROJECT} -s /usr/sbin/nologin -c "${PROJECT} user" ${PROJECT}

mkdir -p /etc/${PROJECT} /var/log/${PROJECT} /var/lib/${PROJECT} /var/cache/${PROJECT}
chown ${PROJECT}:${PROJECT} /etc/${PROJECT} /var/log/${PROJECT} /var/lib/${PROJECT} /var/cache/${PROJECT}

case ${distro} in
    debian|ubuntu)
        if [[ ! -z ${PACKAGES} ]]; then
            apt-get install -y --no-install-recommends ${PACKAGES[@]}
        fi
        apt-get purge -y --auto-remove \
            git \
            python-pip
        rm -rf /var/lib/apt/lists/*
        ;;
    centos)
        if [[ ! -z ${PACKAGES} ]]; then
            yum -y --setopt=skip_missing_names_on_install=False install ${PACKAGES[@]}
        fi
        yum -y autoremove \
            git \
            python-pip
        yum clean all
        ;;
    *)
        echo "Unknown distro: ${distro}"
        exit 1
        ;;
esac

# NOTE(SamYaple): Removing this file allows python to use libraries outside of
# the virtualenv if they do not exist inside the venv. This is a requirement
# for using python-rbd which is not pip installable and is only available in
# packaged form.
rm /var/lib/openstack/lib/python*/no-global-site-packages.txt

rm -rf /tmp/* /root/.cache
find /usr/ /var/ -type f -name "*.pyc" -delete
