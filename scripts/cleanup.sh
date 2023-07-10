#!/bin/bash

# ubuntu trusty apt-get purge 'fails' when packages are not installed: ignore it
set +e

case ${distro} in
    debian|ubuntu)
        apt-get purge -y --auto-remove \
            python3-virtualenv \
            python-virtualenv \
            virtualenv
        ;;
    centos)
        # We should be removing 'patch' here, but that breaks
        # centos as it tries to rip out systemd for some reason
        yum -y autoremove \
            python-virtualenv \
            python3-virtualenv
        yum clean all
        ;;
    opensuse|opensuse-leap|opensuse-tumbleweed|sles)
        virtualenv_package="python3-virtualenv"
        zypper remove -y --clean-deps \
            git-core \
            patch \
            "${virtualenv_package}"
        zypper clean -a
        ;;
    *)
        echo "Unknown distro: ${distro}"
        exit 1
        ;;
esac

# Removing this file allows python to use libraries outside of the
# virtualenv if they do not exist inside the venv. This is a requirement
# for using python-rbd which is not pip installable and is only available
# in packaged form.
rm -f /var/lib/openstack/lib/python*/no-global-site-packages.txt
rm -rf /tmp/* /etc/machine-id
find /usr/ /var/ \( -name "*.pyc" -o -name "__pycache__" \) -delete
