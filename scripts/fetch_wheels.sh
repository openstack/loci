#!/bin/bash

set -ex

if [[ "${PYTHON3}" == "no" ]]; then
    python=python2
else
    python=python3
fi

${python} $(dirname $0)/fetch_wheels.py

mkdir -p /tmp/wheels/
# NOTE(SamYaple): We exclude all files starting with '.' as these can be
# control files for AUFS which have special meaning on AUFS backed file
# stores.
tar xvf /tmp/wheels.tar.gz --exclude='.*' -C /tmp/wheels/
ls -l /tmp/wheels