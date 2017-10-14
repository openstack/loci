#!/bin/bash

set -ex

# NOTE(SamYaple): This little dance allows us to install the latest pip and
# setuptools without get_pip.py or the python-pip package (which is in epel on
# centos)
if (( $(virtualenv --version | cut -d. -f1) >= 14 )); then
    SETUPTOOLS="--no-setuptools"
fi
virtualenv --extra-search-dir=/tmp/wheels ${SETUPTOOLS} /tmp/venv
source /tmp/venv/bin/activate
pip install --upgrade virtualenv
hash -r
virtualenv --extra-search-dir=/tmp/wheels /var/lib/openstack
