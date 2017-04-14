#!/bin/bash -ex

if [[ "${DOCKER_TAG}" == "debian" ]] || [[ "${DOCKER_TAG}" == "ubuntu" ]]; then
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        python
fi

$(dirname $0)/fetch_wheels.py

mkdir /tmp/packages
tar xf /tmp/wheels.tar.gz -C /tmp/packages/ --strip-components=2 root/packages
