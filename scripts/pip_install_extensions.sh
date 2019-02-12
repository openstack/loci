#!/bin/bash

set -ex

# install custom requirements
if [[ -e /tmp/${PROJECT}/custom-requirements.txt ]]; then
    pip install --no-cache-dir --pre --no-compile -r /tmp/${PROJECT}/custom-requirements.txt --find-links /tmp/wheels/ ${PIP_ARGS}
fi

