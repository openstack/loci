#!/bin/bash

set -ex

packages=$@

# install custom requirements first, so they can provide existing, installed dependencies for pip install {packages} in the next step
if [[ -e /tmp/${PROJECT}/custom-requirements.txt ]]; then
    pip install --no-cache-dir --pre --no-compile -r /tmp/${PROJECT}/custom-requirements.txt -c /tmp/wheels/upper-constraints.txt --find-links /tmp/wheels/ ${PIP_ARGS}
fi

if [[ "${PROJECT}" == "rally-openstack" ]]; then
    pip install --no-cache-dir --only-binary :all: --no-compile -c /tmp/${PROJECT}/upper-constraints.txt --find-links /tmp/wheels/ ${PIP_ARGS} ${packages}
else
    pip install --no-cache-dir --pre --only-binary :all: --no-compile -c /tmp/wheels/upper-constraints.txt --find-links /tmp/wheels/ ${PIP_ARGS} ${packages}
fi

