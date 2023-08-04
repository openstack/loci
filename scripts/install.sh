#!/bin/bash

set -ex

distro=$(awk -F= '/^ID=/ {gsub(/\"/, "", $2); print $2}' /etc/*release)
export distro=${DISTRO:=$distro}

if [[ ${distro} == "ubuntu" ]]; then
    distro_version=$(awk -F= '/^UBUNTU_CODENAME=/ {gsub(/\"/, "", $2); print $2}' /etc/*release)
fi
export distro_version=${DISTRO_VERSION:=$distro_version}

dpkg_python_packages=("python3" "python3-virtualenv")
rpm_python_packages=("python3")

case ${distro} in
    ubuntu)
        export LC_CTYPE=C.UTF-8
        apt-get update
        if [[ ! -z "$(apt-cache search ^python3-distutils$)" ]]; then
            dpkg_python_packages+=("python3-distutils")
        fi
        apt-get upgrade -y
        apt-get install -y --no-install-recommends \
            git \
            ca-certificates \
            netbase \
            lsb-release \
            patch \
            sudo \
            ${dpkg_python_packages[@]}
        apt-get install -y --no-install-recommends \
            libpython3.$(python3 -c 'import sys; print(sys.version_info.minor);')
        ;;
    centos)
        export LC_CTYPE=en_US.UTF-8
        yum upgrade -y
        yum install -y --setopt=skip_missing_names_on_install=False \
            git \
            patch \
            redhat-lsb-core \
            sudo \
            ${rpm_python_packages[@]}
        if [[ "${PYTHON3}" != "no" ]]; then
          pip3 install virtualenv
        fi
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

if [ "${KEEP_ALL_WHEELS}" != "False" ]; then
    NO_INDEX=--no-index
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
    $(dirname $0)/install_packages.sh
    for file in /opt/loci/pydep*; do
        PYDEP_PACKAGES+=($(bindep -f $file -b -l newline ${PROJECT} ${PROJECT_RELEASE} ${PROFILES} || :))
    done
    $(dirname $0)/pip_install.sh ${PYDEP_PACKAGES[@]}
fi

if [[ ${PROJECT} == 'nova' ]]; then
    $(dirname $0)/install_nova_console.sh
fi
$(dirname $0)/clone_project.sh
$(dirname $0)/install_packages.sh
$(dirname $0)/pip_install.sh ${NO_INDEX} /tmp/${PROJECT} ${PIP_PACKAGES}
$(dirname $0)/configure_packages.sh
$(dirname $0)/collect_info.sh
$(dirname $0)/cleanup.sh
