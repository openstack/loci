#!/bin/bash

set -eux

# TODO(SamYaple): Switch all of this to bindep once syntax is supported better
# NOTE(SamYaple): Ubuntu and Debian have slightly different package lists
case ${distro} in
    debian)
        apt-get update
        apt-get upgrade -y
        apt-get install -y --no-install-recommends \
            build-essential \
            ca-certificates \
            git \
            liberasurecode-dev \
            libffi-dev \
            libkrb5-dev \
            libldap2-dev \
            libmariadbclient-dev \
            libnss3-dev \
            libpq-dev \
            libsasl2-dev \
            libssl-dev \
            libsystemd-dev \
            libxml2-dev \
            libxslt1-dev \
            libvirt-dev \
            libyaml-dev \
            libz-dev \
            pkg-config \
            python-dev \
            python-pip \
            python-virtualenv
        ;;
    ubuntu)
        apt-get update
        apt-get upgrade -y
        apt-get install -y --no-install-recommends \
            build-essential \
            ca-certificates \
            git \
            liberasurecode-dev \
            libffi-dev \
            libkrb5-dev \
            libldap2-dev \
            libmysqlclient-dev \
            libnss3-dev \
            libpq-dev \
            libsasl2-dev \
            libssl-dev \
            libsystemd-dev \
            libxml2-dev \
            libxslt1-dev \
            libvirt-dev \
            libyaml-dev \
            libz-dev \
            pkg-config \
            python-dev \
            python-pip
        ;;
    centos)
        yum upgrade -y
        # NOTE(SamYaple): https://bugs.centos.org/view.php?id=10750
        yum install -y --setopt=tsflags=docs --setopt=skip_missing_names_on_install=False libffi-devel
        yum install -y --setopt=skip_missing_names_on_install=False \
            gcc \
            gcc-c++ \
            make \
            openssl-devel \
            ca-certificates \
            git \
            bzip2 \
            liberasurecode-devel \
            openldap-devel \
            mariadb-devel \
            nss-devel \
            postgresql-devel \
            cyrus-sasl-devel \
            openssl-devel \
            libxml2-devel \
            libxslt-devel \
            libvirt-devel \
            libyaml-devel \
            zlib-devel \
            pkgconfig \
            python \
            python-devel \
            python-pip \
            libgcrypt \
            nss-util \
            systemd-devel
        ;;
    *)
        echo "Unknown distro: ${distro}"
        exit 1
        ;;
esac

$(dirname $0)/setup_pip.sh
$(dirname $0)/clone_project.sh
mv /tmp/requirements/{global-requirements.txt,upper-constraints.txt} /

# NOTE(SamYaple): Build all deps in parallel. This is safe because we are
# constrained on the version and we are building with --no-deps
pushd $(mktemp -d)
split -l1 /upper-constraints.txt
ls -1 | xargs -n1 -P20 -t pip wheel --no-deps --wheel-dir / -c /upper-constraints.txt -r
popd
# NOTE(SamYaple): Handle packages not in global-requirements
additional_packages=(argparse bindep==2.5.0 pip setuptools uwsgi wheel virtualenv)
echo "${additional_packages[@]}" | xargs -n1 -P20 pip wheel --wheel-dir / -c /upper-constraints.txt

# NOTE(SamYaple): We want to purge all files that are not wheels or txt to
# reduce the size of the layer to only what is needed
shopt -s extglob
rm -rf /!(*whl|*txt) > /dev/null 2>&1 || :
