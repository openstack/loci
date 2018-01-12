#!/bin/bash

set -ex

distro=$(awk -F= '/^ID=/ {gsub(/\"/, "", $2); print $2}' /etc/*release)
export distro=${DISTRO:=$distro}

if [[ "${PYTHON3}" == "no" ]]; then
    dpkg_python_packages=("python" "virtualenv")
    rpm_python_packages=("python" "python-virtualenv")
else
    dpkg_python_packages=("python3" "python3-virtualenv")
    rpm_python_packages=("python3" "python3-virtualenv")
fi

case ${distro} in
    debian|ubuntu)
        echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf
        apt-get update
        apt-get upgrade -y
        apt-get install -y --no-install-recommends \
            git \
            ca-certificates \
            netbase \
            lsb-release \
            patch \
            sudo \
            wget \
            ack-grep \
            cron \
            dnsutils \
            inetutils-ping \
            ${dpkg_python_packages[@]}
        ;;
    centos)
        yum upgrade -y
        yum install -y --setopt=skip_missing_names_on_install=False \
            git \
            patch \
            redhat-lsb-core \
            sudo \
            wget \
            ${rpm_python_packages[@]}
        ;;
    *)
        echo "Unknown distro: ${distro}"
        exit 1
        ;;
esac

if [[ "${PROJECT}" == "requirements" ]]; then
    $(dirname $0)/requirements.sh
    exit 0
else
    # install SAP certificates
    wget -O /usr/local/share/ca-certificates/SAP_Global_Root_CA.crt http://aia.pki.co.sap.com/aia/SAP%20Global%20Root%20CA.crt && \
    wget -O /usr/local/share/ca-certificates/SAP_Global_Sub_CA_02.crt http://aia.pki.co.sap.com/aia/SAP%20Global%20Sub%20CA%2002.crt && \
    wget -O /usr/local/share/ca-certificates/SAP_Global_Sub_CA_04.crt http://aia.pki.co.sap.com/aia/SAP%20Global%20Sub%20CA%2004.crt && \
    wget -O /usr/local/share/ca-certificates/SAP_Global_Sub_CA_05.crt http://aia.pki.co.sap.com/aia/SAP%20Global%20Sub%20CA%2005.crt && \
    wget -O /usr/local/share/ca-certificates/SAPNetCA_G2.crt http://aia.pki.co.sap.com/aia/SAPNetCA_G2.crt

    # grab kubernetes-entrypoint
    curl -sLo /usr/local/bin/kubernetes-entrypoint https://github.wdf.sap.corp/d062284/k8s-entrypoint-build/releases/download/f52d105/kubernetes-entrypoint && \
    chmod +x /usr/local/bin/kubernetes-entrypoint
fi

$(dirname $0)/fetch_wheels.sh
if [[ "${PLUGIN}" == "no" ]]; then
    $(dirname $0)/create_user.sh
    $(dirname $0)/setup_pip.sh
    $(dirname $0)/pip_install.sh \
        bindep==2.5.0 \
        cryptography \
        pymysql \
        python-memcached \
        uwsgi
fi

# NOTE(SamYaple): Remove when bindep>2.5.0 is released
patch /var/lib/openstack/lib/python*/site-packages/bindep/depends.py < /opt/loci/scripts/bindep.depends.patch
rm -f /var/lib/openstack/lib/python*/site-packages/bindep/depends.pyc

if [[ ${PROJECT} == 'nova' ]]; then
    $(dirname $0)/pip_install.sh libvirt-python
fi
$(dirname $0)/clone_project.sh
$(dirname $0)/pip_install.sh /tmp/${PROJECT} ${PIP_PACKAGES}
$(dirname $0)/install_packages.sh
$(dirname $0)/cleanup.sh
