#!/bin/bash

set -ex

python3 $(dirname $0)/fetch_wheels.py

mkdir -p /tmp/wheels/
# Exclude all files starting with '.' as these can be control files for
# AUFS which have special meaning on AUFS backed file stores.
tar xvf /tmp/wheels.tar.gz --exclude='.*' -C /tmp/wheels/
