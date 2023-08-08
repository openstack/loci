#!/bin/bash

set -ex

packages=$@

pip install --no-cache-dir --only-binary :all: --no-compile -c /tmp/wheels/global-requirements.txt -c /tmp/wheels/upper-constraints.txt --find-links /tmp/wheels/ --ignore-installed ${PIP_ARGS} ${packages}
