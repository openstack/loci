#!/bin/bash

set -ex

distro=$(awk -F= '/^ID=/ {gsub(/\"/, "", $2); print $2}' /etc/*release)
export distro=${DISTRO:=$distro}

if [[ "${PYTHON3}" == "no" ]]; then
    if [[ "${DISTRO_RELEASE}" == "trusty" ]]; then
        dpkg_python_packages=("python" "python-virtualenv")
    else
        dpkg_python_packages=("python" "virtualenv")
    fi
    rpm_python_packages=("python" "python-virtualenv")
    python3=""
    python_version=2
else
    dpkg_python_packages=("python3" "python3-virtualenv" "python3-distutils")
    rpm_python_packages=("python3" "python3-virtualenv")
    python3="python3"
    python_version=3
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
        apt-get install -y --no-install-recommends \
            libpython${python_version}.$(python${python_version} -c 'import sys;\
                                         print(sys.version_info.minor);')
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
            curl \
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
        PYDEP_PACKAGES+=($(bindep -f $file -b -l newline ${PROJECT} ${PROFILES} ${python3} ${DISTRO_RELEASE}|| :))
    done
    $(dirname $0)/pip_install.sh ${PYDEP_PACKAGES[@]}
fi
$(dirname $0)/clone_project.sh
if [[ "${EXTENSIONS}" == "no" ]]; then
    if [[ ${PROJECT} == 'nova' ]]; then
        $(dirname $0)/install_nova_console.sh
    fi
    $(dirname $0)/install_packages.sh
    $(dirname $0)/pip_install.sh /tmp/${PROJECT} ${PIP_PACKAGES}
else
    # install custom requirements
    if [[ -e /tmp/${PROJECT}/custom-requirements.txt ]]; then
        pip install --no-cache-dir --pre --no-compile -r /tmp/${PROJECT}/custom-requirements.txt -c /tmp/wheels/upper-constraints.txt --find-links /tmp/wheels/ ${PIP_ARGS}
    fi
fi
$(dirname $0)/setup_pyroscope.py
$(dirname $0)/cleanup.sh
