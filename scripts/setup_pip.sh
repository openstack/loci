#!/bin/bash

set -ex

pip install -U virtualenv

# NOTE(SamYaple): --system-site-packages flag allows python to use libraries
# outside of the virtualenv if they do not exist inside the venv. This is a
# requirement for using python-rbd which is not pip installable and is only
# available in packaged form.
# --no-pip --no-setuptools --no-wheel is declared because it was breaking pypi
# mirrors until setuptools is setup properly
virtualenv --no-pip --no-setuptools --no-wheel --system-site-packages /var/lib/openstack/
source /var/lib/openstack/bin/activate
pip install -U pip
pip install -U setuptools wheel
