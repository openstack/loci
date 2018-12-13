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
        apt-get update
        apt-get upgrade -y
        apt-get install -y --no-install-recommends \
            git \
            ca-certificates \
            netbase \
            lsb-release \
            patch \
            sudo \
            curl \
            ${dpkg_python_packages[@]}
        ;;
    centos)
        yum upgrade -y
        yum install -y --setopt=skip_missing_names_on_install=False \
            git \
            patch \
            redhat-lsb-core \
            sudo \
            curl \
            ${rpm_python_packages[@]}
        ;;
    opensuse|opensuse-leap|opensuse-tumbleweed|sles)
        if [[ "${PYTHON3}" == "no" ]]; then
           rpm_python_packages+=("python-devel" "python-setuptools")
        else
           rpm_python_packages+=("python3-devel" "python3-setuptools")
        fi
        zypper --non-interactive --gpg-auto-import-keys refresh
        zypper --non-interactive install --no-recommends \
            ca-certificates \
            git-core \
            lsb-release \
            patch \
            sudo \
            tar \
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
    # grab kubernetes-entrypoint
    curl -sLo /usr/local/bin/kubernetes-entrypoint https://github.wdf.sap.corp/d062284/k8s-entrypoint-build/releases/download/f52d105/kubernetes-entrypoint && \
    chmod +x /usr/local/bin/kubernetes-entrypoint
fi

$(dirname $0)/fetch_wheels.sh
if [[ "${PROJECT}" == "infra" ]]; then
   $(dirname $0)/setup_pip.sh
    $(dirname $0)/pip_install.sh bindep ${PIP_PACKAGES}
    $(dirname $0)/install_packages.sh
    $(dirname $0)/cleanup.sh
    exit 0
fi
if [[ "${PLUGIN}" == "no" ]]; then
    $(dirname $0)/create_user.sh
    $(dirname $0)/setup_pip.sh
    $(dirname $0)/pip_install.sh bindep
    for file in /opt/loci/pydep*; do
        PYDEP_PACKAGES+=($(bindep -f $file -b -l newline ${PROJECT} ${PROFILES} ${python3} || :))
    done
    $(dirname $0)/pip_install.sh ${PYDEP_PACKAGES[@]}
fi

# special neutron aci drivers installation sauce
if [[ ${PROJECT} == 'neutron' ]]; then
    $(dirname $0)/install_apic.sh
fi

if [[ ${PROJECT} == 'nova' ]]; then
    $(dirname $0)/install_nova_console.sh
fi
$(dirname $0)/clone_project.sh
$(dirname $0)/install_packages.sh
$(dirname $0)/pip_install.sh /tmp/${PROJECT} ${PIP_PACKAGES}
$(dirname $0)/cleanup.sh
