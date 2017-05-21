#!/bin/bash -ex

packages=$@

distro=$(awk -F= '/^ID=/ {print $2}' /etc/*release | tr -d \")

case ${distro} in
    debian|ubuntu)
        apt-get install -y --no-install-recommends \
            ca-certificates \
            python \
            virtualenv \
            sudo
        ;;
    centos)
        yum install -y \
            python-virtualenv \
            sudo
        ;;
    *)
        echo "Unknown distro: ${distro}"
        exit 1
        ;;
esac

mkdir -p /opt/loci/
cp $(dirname $0)/fetch_wheels.py /opt/loci/
/opt/loci/fetch_wheels.py

mkdir /tmp/packages
# NOTE(SamYaple): We exclude all files starting with '.' as these can be
# control files for AUFS which have special meaning on AUFS backed file
# stores.
tar xf /tmp/wheels.tar.gz --exclude='.*' -C /tmp/packages/ --strip-components=2 root/packages

git init /tmp/${PROJECT}
git --git-dir /tmp/${PROJECT}/.git fetch ${PROJECT_REPO} ${PROJECT_REF}
git --work-tree /tmp/${PROJECT} --git-dir /tmp/${PROJECT}/.git checkout FETCH_HEAD

# NOTE(SamYaple): --system-site-packages flag allows python to use libraries
# outside of the virtualenv if they do not exist inside the venv. This is a
# requirement for using python-rbd which is not pip installable and is only
# available in packaged form.
virtualenv --system-site-packages /var/lib/openstack/
source /var/lib/openstack/bin/activate
pip install -U pip
pip install -U setuptools wheel

pip install --no-cache-dir --no-index --no-compile --find-links /tmp/packages --constraint /tmp/packages/upper-constraints.txt \
        /tmp/${PROJECT} \
        pycrypto \
        pymysql \
        python-memcached \
        uwsgi \
        ${packages[@]}

groupadd -g 42424 ${PROJECT}
useradd -u 42424 -g ${PROJECT} -M -d /var/lib/${PROJECT} -s /usr/sbin/nologin -c "${PROJECT} user" ${PROJECT}

mkdir -p /etc/${PROJECT} /var/log/${PROJECT} /var/lib/${PROJECT} /var/cache/${PROJECT}
chown ${PROJECT}:${PROJECT} /etc/${PROJECT} /var/log/${PROJECT} /var/lib/${PROJECT} /var/cache/${PROJECT}

case ${distro} in
    debian|ubuntu)
        apt-get purge -y --auto-remove \
            ca-certificates \
            git \
            virtualenv
        rm -rf /var/lib/apt/lists/*
        ;;
    centos)
        yum -y autoremove \
            git \
            python-virtualenv
        yum clean all
        ;;
    *)
        echo "Unknown distro: ${distro}"
        exit 1
        ;;
esac

rm -rf /tmp/* /root/.cache
find /usr/ /var/ -type f -name "*.pyc" -delete
