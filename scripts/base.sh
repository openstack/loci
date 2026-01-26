#!/bin/bash

set -xeo pipefail

source "$(dirname $0)/helpers.sh"
configure_apt_sources "${APT_MIRROR_HOST}" http  # Use http before ca-certificates is installed

export LC_CTYPE=C.UTF-8
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    gnupg2 \
    lsb-release \
    wget

revert_apt_sources
configure_apt_sources "${APT_MIRROR_HOST}"

cat <<EOF >> /etc/apt/apt.conf.d/allow-unauthenticated
APT::Get::AllowUnauthenticated "${ALLOW_UNAUTHENTICATED}";
Acquire::AllowInsecureRepositories "${ALLOW_UNAUTHENTICATED}";
Acquire::AllowDowngradeToInsecureRepositories "${ALLOW_UNAUTHENTICATED}";
EOF

wget -q -O- "${CEPH_KEY}" | apt-key add -
if [ -n "${CEPH_REPO}" ]; then
    echo "${CEPH_REPO}" | tee /etc/apt/sources.list.d/ceph.list
fi

apt-get update
apt-get upgrade -y
apt-get install -y --no-install-recommends \
    git \
    netbase \
    patch \
    sudo \
    bind9-host \
    python3 \
    python3-venv

if [[ -n $(apt-cache search ^python3-distutils$ 2>/dev/null) ]]; then
    apt-get install -y --no-install-recommends python3-distutils
fi

apt-get install -y --no-install-recommends \
    libpython3.$(python3 -c 'import sys; print(sys.version_info.minor);')

revert_apt_sources

apt-get clean
rm -rf /var/lib/apt/lists/*
