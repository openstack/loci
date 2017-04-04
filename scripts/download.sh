#!/bin/bash -ex

if [[ "${DOCKER_TAG}" == "latest" ]] || [[ "${DOCKER_TAG}" == "ubuntu" ]]; then
    apt-get install -y --no-install-recommends python git
elif [[ "${DOCKER_TAG}" == "centos" ]]; then
    yum install -y git
fi

if [[ -n "$WHEELS" ]]; then
    curl -sSL ${WHEELS} > /tmp/wheels.tar.gz
else
    TOKEN=$(curl -sSL "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${DOCKER_REPO}:pull" | \
            python -c "import sys, json; print json.load(sys.stdin)['token']")
    BLOB=$(curl -sSL -H "Authorization: Bearer ${TOKEN}" https://registry.hub.docker.com/v2/${DOCKER_REPO}/manifests/${DOCKER_TAG} | \
            python -c "import sys, json; print json.load(sys.stdin)['fsLayers'][0]['blobSum']")
    curl -sSL -H "Authorization: Bearer ${TOKEN}" https://registry.hub.docker.com/v2/${DOCKER_REPO}/blobs/${BLOB} > /tmp/wheels.tar.gz
fi

mkdir /tmp/packages
tar xf /tmp/wheels.tar.gz -C /tmp/packages/ --strip-components=2 root/packages
