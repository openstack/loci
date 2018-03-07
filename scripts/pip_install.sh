#!/bin/bash

set -ex

packages=$@

pip install --no-cache-dir --only-binary :all: --no-compile -c /tmp/wheels/upper-constraints.txt --find-links /tmp/wheels/ ${packages}

# add custom requirements
if [[ -e /tmp/${PROJECT}/custom-requirements.txt ]]; then
    pip install --no-cache-dir --no-compile  --process-dependency-links  --allow-all-external -r /tmp/${PROJECT}/custom-requirements.txt -c /tmp/wheels/upper-constraints.txt --find-links /tmp/wheels/
fi