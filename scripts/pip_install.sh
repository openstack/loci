#!/bin/bash

set -ex

packages=$@

# Presence of constraint for project we build
# in upper constraints breaks project installation
# with unsatisfied constraints error.
# This line ensures that such constraint is absent.
cp ${WHEELS_PATH}/upper-constraints.txt /tmp/upper-constraints.txt
sed -i "/^${PROJECT}===/d" /tmp/upper-constraints.txt

pip install --no-cache-dir --only-binary :all: --no-compile -c ${WHEELS_PATH}/global-requirements.txt -c /tmp/upper-constraints.txt --find-links ${WHEELS_PATH} --ignore-installed ${PIP_ARGS} ${packages}
