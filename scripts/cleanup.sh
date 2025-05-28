#!/bin/bash

set -ex

apt-get purge -y --auto-remove \
    git \
    patch \
    python3-virtualenv \
    virtualenv
if [ -f /etc/apt/sources.list.bak ]; then
    mv /etc/apt/sources.list.bak /etc/apt/sources.list
fi
rm -rf /var/lib/apt/lists/*

# Changing this option allows python to use libraries outside of the
# virtualenv > 20 if they do not exist inside the venv. This is a requirement
# for using python-rbd which is not pip installable and is only available
# in packaged form.
sed -i 's/\(include-system-site-packages\).*/\1 = true/g' /var/lib/openstack/pyvenv.cfg
rm -rf /tmp/* /root/.cache /etc/machine-id
find /usr/ /var/ \( -name "*.pyc" -o -name "__pycache__" \) -delete
# Remove sources added to image
rm -rf /opt/loci/data/*
