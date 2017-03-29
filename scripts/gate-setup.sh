#!/bin/bash

set -eux

function debug_info {
    set +x
    local PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    sudo parted -l
    sudo mount
    df -h
    uname -a
    cat /etc/*release*
    cat /proc/meminfo
    env
    set -x
}

debug_info
