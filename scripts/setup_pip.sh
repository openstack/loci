#!/bin/bash

set -ex

PIP_CONSTRAINT=${PIP_CONSTRAINT}
SETUPTOOL_CONSTRAINT=${SETUPTOOL_CONSTRAINT}
WHEEL_CONSTRAIN=${WHEEL_CONSTRAIN}
VIRTUALENV="python3 -m virtualenv --python=python3 --no-seed"

wget $GET_PIP_URL -O /tmp/get-pip.py

# Create the virtualenv with the updated toolchain for openstack service
# for using python-rbd which is not pip installable and is only available
# in packaged form.
$VIRTUALENV  --system-site-packages --extra-search-dir=/tmp/wheels /var/lib/openstack

source /var/lib/openstack/bin/activate

python /tmp/get-pip.py

pip install --upgrade pip${PIP_CONSTRAINT}
pip install --upgrade setuptools${SETUPTOOL_CONSTRAINT}
pip install --upgrade wheel${WHEEL_CONSTRAIN}
