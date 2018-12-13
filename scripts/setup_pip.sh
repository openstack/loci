#!/bin/bash

set -ex

if [[ "${PYTHON3}" == "no" ]]; then
    TMP_VIRTUALENV="virtualenv"
else
    TMP_VIRTUALENV="python3 -m virtualenv --python=python3"
fi

# This little dance allows us to install the latest pip and setuptools
# without get_pip.py or the python-pip package (in epel on centos)
if (( $(${TMP_VIRTUALENV} --version | cut -d. -f1) >= 14 )); then
    SETUPTOOLS="--no-setuptools"
fi
${TMP_VIRTUALENV} --extra-search-dir=/tmp/wheels ${SETUPTOOLS} /tmp/venv
source /tmp/venv/bin/activate

# f5 packages break with pip 10
pip install --upgrade ${PIP_ARGS} 'virtualenv<16'

hash -r
virtualenv --extra-search-dir=/tmp/wheels /var/lib/openstack
source /var/lib/openstack/bin/activate
pip install --force-reinstall pip==9.0.3
