#!/bin/bash

set -ex

case ${distro} in
    ubuntu)
        apt-get purge -y --auto-remove \
            git \
            patch \
            python3-virtualenv \
            virtualenv
        rm -rf /var/lib/apt/lists/*
        ;;
    centos)
        # We should be removing 'patch' here, but that breaks
        # centos as it tries to rip out systemd for some reason
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

# Changing this option allows python to use libraries outside of the
# virtualenv > 20 if they do not exist inside the venv. This is a requirement
# for using python-rbd which is not pip installable and is only available
# in packaged form.
sed -i 's/\(include-system-site-packages\).*/\1 = true/g' /var/lib/openstack/pyvenv.cfg
rm -rf /tmp/* /root/.cache /etc/machine-id
find /usr/ /var/ \( -name "*.pyc" -o -name "__pycache__" \) -delete
