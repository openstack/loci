#!/bin/bash -eux

if [[ "${DOCKER_TAG}" == "latest" ]] || [[ "${DOCKER_TAG}" == "ubuntu" ]]; then
    apt-get purge -y --auto-remove ca-certificates curl git
    rm -rf /var/lib/apt/lists/*
elif [[ "${DOCKER_TAG}" == "centos" ]]; then
    yum history -y undo $(yum history list git | tail -2 | head -1 | awk '{ print $1}')
    yum clean all
fi

pip uninstall wheel pip -y
rm -rf /tmp/* /root/.cache
find / -type f -name "*.pyc" -delete
