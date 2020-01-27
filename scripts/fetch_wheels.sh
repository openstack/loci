#!/bin/bash

set -ex

if [[ "${PYTHON3}" == "no" ]]; then
    python=python2
else
    python=python3
fi

${python} $(dirname $0)/fetch_wheels.py

mkdir -p /tmp/wheels/
# Exclude all files starting with '.' as these can be control files for
# AUFS which have special meaning on AUFS backed file stores.
tar xf /tmp/wheels.tar.gz --exclude='.*' -C /tmp/wheels/

# Presence of constraint for project we build (in Stein, Train for Horizon and
# Neutron) in uc breaks project installation with unsatisfied constraints error
# This line ensures that such constraint is absent for any future occurrence
sed -i "/^${PROJECT}===/d" /tmp/wheels/upper-constraints.txt
