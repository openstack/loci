#!/bin/bash -ex

packages=$@

/opt/loci/fetch_wheels.py

mkdir -p /tmp/wheels/
# NOTE(SamYaple): We exclude all files starting with '.' as these can be
# control files for AUFS which have special meaning on AUFS backed file
# stores.
tar xf /tmp/wheels.tar.gz --exclude='.*' -C /tmp/wheels/

pip install --no-cache-dir --no-index --no-compile --find-links /tmp/wheels/ ${packages[@]}
