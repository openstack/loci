#!/bin/bash

set -ex

packages=$@

pip install --no-cache-dir --only-binary :all: --no-compile -c /tmp/wheels/upper-constraints.txt --find-links /tmp/wheels/ ${PIP_ARGS} ${packages}

# add custom requirements
if [[ -e /tmp/${PROJECT}/custom-requirements.txt ]]; then
    pip install --no-cache-dir --no-compile -r /tmp/${PROJECT}/custom-requirements.txt -c /tmp/wheels/upper-constraints.txt --find-links /tmp/wheels/ ${PIP_ARGS}
fi
