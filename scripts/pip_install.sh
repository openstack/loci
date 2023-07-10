#!/bin/bash

set -ex

packages=$@

if [[ $1 == /var/lib/openstack/* ]]; then
  PIP_ARGS="${PIP_ARGS} -e "
fi

pip install --only-binary :all: --no-compile ${CUSTOM_REQUIREMENTS} -c ${WHEELS_DEST}/upper-constraints.txt --find-links ${WHEELS_DEST} ${PIP_ARGS} ${packages}
