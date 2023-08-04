#!/bin/bash

set -ex

: ${COPY_DEFAULT_CONFIG_FILES:="no"}

if [[ $COPY_DEFAULT_CONFIG_FILES == "yes" ]] && [[ ! ${PROJECT} =~ ^(infra|requirements)$ ]]; then
    mkdir -p "/etc/${PROJECT}/"
    cp -r "/var/lib/openstack/etc/${PROJECT}"/* "/etc/${PROJECT}/" || true
fi
