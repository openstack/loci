#!/bin/bash

set -ex

case ${distro} in
    debian|ubuntu)
        apt-get purge -y --auto-remove \
            git \
            python3-virtualenv \
            virtualenv
        rm -rf /var/lib/apt/lists/*
        ;;
    centos)
        yum -y autoremove \
            git \
            python-virtualenv \
            python3-virtualenv
        yum clean all
        ;;
    *)
        echo "Unknown distro: ${distro}"
        exit 1
        ;;
esac

# NOTE(SamYaple): Removing this file allows python to use libraries outside of
# the virtualenv if they do not exist inside the venv. This is a requirement
# for using python-rbd which is not pip installable and is only available in
# packaged form.
rm /var/lib/openstack/lib/python*/no-global-site-packages.txt
rm -rf /tmp/* /root/.cache
find /usr/ /var/ \( -name "*.pyc" -o -name "__pycache__" \) -delete
