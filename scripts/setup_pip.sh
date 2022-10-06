#!/bin/bash

set -ex


TMP_VIRTUALENV="python3 -m virtualenv --python=python3"

# This little dance allows us to install the latest pip
# without get_pip.py or the python-pip package (in epel on centos)
if (( $(${TMP_VIRTUALENV} --version | grep -Po '[0-9]+\.[0-9]+\.[0-9]+' | cut -d. -f1) >= 14 )); then
    SETUPTOOLS="--no-setuptools"
fi
if (( $(${TMP_VIRTUALENV} --version | grep -Po '[0-9]+\.[0-9]+\.[0-9]+' | cut -d. -f1) >= 20 )); then
    SETUPTOOLS="--seed pip --download"
fi

# virtualenv 16.4.0 fixed symlink handling. The interaction of the new
# corrected behavior with legacy bugs in packaged virtualenv releases in
# distributions means we need to hold on to the pip bootstrap installation
# chain to preserve symlinks. As distributions upgrade their default
# installations we may not need this workaround in the future
PIPBOOTSTRAP=/var/lib/pipbootstrap

# Create the boostrap environment so we can get pip from virtualenv
${TMP_VIRTUALENV} ${SETUPTOOLS} ${PIPBOOTSTRAP}
source ${PIPBOOTSTRAP}/bin/activate

# Install setuptools explicitly required for virtualenv > 20 installation
pip install --upgrade setuptools

# Upgrade to the latest version of virtualenv
pip install --upgrade ${PIP_ARGS} virtualenv==20.7.2

# Forget the cached locations of python binaries
hash -r

# Create the virtualenv with the updated toolchain for openstack service
virtualenv --seed pip --download /var/lib/openstack

# Deactivate the old bootstrap virtualenv and switch to the new one
deactivate
source /var/lib/openstack/bin/activate
