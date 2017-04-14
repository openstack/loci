#!/bin/bash -eux

if [[ "${DOCKER_TAG}" == "debian" ]] || [[ "${DOCKER_TAG}" == "ubuntu" ]]; then
    apt-get purge -y --auto-remove \
        ca-certificates \
        curl \
        git
    rm -rf /var/lib/apt/lists/*
elif [[ "${DOCKER_TAG}" == "centos" ]]; then
    yum -y autoremove git
    yum clean all
fi

pip uninstall wheel pip -y
rm -rf /tmp/* /root/.cache
find /usr/ -type f -name "*.pyc" -delete
