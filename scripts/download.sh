#!/bin/bash -ex

if [[ "${DOCKER_TAG}" == "latest" ]] || [[ "${DOCKER_TAG}" == "ubuntu" ]]; then
    apt-get install -y --no-install-recommends python git
elif [[ "${DOCKER_TAG}" == "centos" ]]; then
    yum install -y git
fi

$(dirname $0)/fetch_wheels.py

mkdir /tmp/packages
tar xf /tmp/wheels.tar.gz -C /tmp/packages/ --strip-components=2 root/packages
