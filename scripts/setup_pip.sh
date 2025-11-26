#!/bin/bash

set -ex

PIP_VERSION_CONSTRAINT=${PIP_VERSION_CONSTRAINT}
SETUPTOOL_CONSTRAINT=${SETUPTOOL_CONSTRAINT}
WHEEL_CONSTRAIN=${WHEEL_CONSTRAIN}

# Create the virtualenv with the updated toolchain for openstack service
# for using python-rbd which is not pip installable and is only available
# in packaged form.
python3 -m venv --system-site-packages /var/lib/openstack

source /var/lib/openstack/bin/activate

pip install --upgrade pip${PIP_VERSION_CONSTRAINT}
pip install --upgrade setuptools${SETUPTOOL_CONSTRAINT}
pip install --upgrade wheel${WHEEL_CONSTRAIN}
