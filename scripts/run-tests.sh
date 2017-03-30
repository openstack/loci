#!/bin/bash

# NOTE(SamYaple): It is not safe to have multiple instances of this script
# running at once due to (poor) error handling
# TODO(SamYaple): Make this script safer if running outside the gate

set -eux

function prep_log_dir {
    rm -rf /tmp/loci_logs
    mkdir -p /tmp/loci_logs/builds
}

function dump_error_logs {
    while read -r line; do
        cat $line
    done < /tmp/loci_logs/build_error
    exit 1
}

function builder {
    set -eux

    local directory=$1
    cd ${directory}
    local distro=${PWD##*/}
    local log=/tmp/loci_logs/builds/${distro}.log
    docker build --no-cache . 2>&1 > ${log} || echo ${log} >> /tmp/loci_logs/build_error
}

# NOTE(SamYaple): We must export the functions for use with subshells (xargs)
export -f $(compgen -A function)

prep_log_dir

echo "Building images"
# NOTE(SamYaple): The $1 gets interpreted as an unbound variable incorrectly
set +u
find . -type f -name Dockerfile -printf '%h\0' | xargs -0 -P10 -n1 bash -c 'builder $1' _
set -u

if [[ -f /tmp/loci_logs/build_error ]]; then
    echo "Building images failure; Dumping failed logs to stdout"
    dump_error_logs
else
    echo "Building images successful"
fi
