#!/bin/bash

set -ex


TMP_VIRTUALENV="python3 -m virtualenv --python=python3"

# This little dance allows us to install the latest pip and setuptools
# without get_pip.py or the python-pip package (in epel on centos)
if (( $(${TMP_VIRTUALENV} --version | cut -d. -f1) >= 14 )); then
    SETUPTOOLS="--no-setuptools"
fi

# virtualenv 16.4.0 fixed symlink handling. The interaction of the new
# corrected behavior with legacy bugs in packaged virtualenv releases in
# distributions means we need to hold on to the pip bootstrap installation
# chain to preserve symlinks. As distributions upgrade their default
# installations we may not need this workaround in the future
PIPBOOTSTRAP=/var/lib/pipbootstrap

# Create the boostrap environment so we can get pip from virtualenv
${TMP_VIRTUALENV} --extra-search-dir=file:///tmp/wheels ${SETUPTOOLS} ${PIPBOOTSTRAP}
source ${PIPBOOTSTRAP}/bin/activate

# Upgrade virtualenv, version 20 breaks with missing setuptools
pip install --upgrade ${PIP_ARGS} 'virtualenv<20'

# Forget the cached locations of python binaries
hash -r

# Create the virtualenv with the updated toolchain for openstack service
virtualenv --extra-search-dir=file:///tmp/wheels /var/lib/openstack

# Deactivate the old bootstrap virtualenv and switch to the new one
deactivate
source /var/lib/openstack/bin/activate

pip install --upgrade ${PIP_ARGS} 'pip'

# Restrict setuptools, version 58 breaks for use_2to3
pip install --upgrade ${PIP_ARGS} "setuptools${SETUPTOOLS_VERSION_REQUIREMENT}"
