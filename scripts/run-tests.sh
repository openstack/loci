#!/bin/bash

# NOTE(SamYaple): It is not safe to have multiple instances of this script
# running at once due to (poor) error handling
# TODO(SamYaple): Make this script safer if running outside the gate

set -eux

export LOGS_DIR=${WORKSPACE:-/tmp/loci}/logs

function prep_log_dir {
    rm -rf ${LOGS_DIR}/build_error
    mkdir -p ${LOGS_DIR}/builds
}

function dump_error_logs {
    while read -r line; do
        cat $line
    done < ${LOGS_DIR}/build_error
    exit 1
}

function builder {
    set -eux

    local directory=$1
    cd ${directory}
    local distro=${PWD##*/}
    local log=${LOGS_DIR}/builds/${distro}.log
    docker build --no-cache . 2>&1 > ${log} || echo ${log} >> ${LOGS_DIR}/build_error
}

# NOTE(SamYaple): We must export the functions for use with subshells (xargs)
export -f $(compgen -A function)

prep_log_dir

echo "Building images"
find . -type f -name Dockerfile -printf '%h\0' | xargs -0 -P10 -n1 bash -c 'builder $1' _

if [[ -f ${LOGS_DIR}/build_error ]]; then
    echo "Building images failure; Dumping failed logs to stdout"
    dump_error_logs
else
    echo "Building images successful"
fi
