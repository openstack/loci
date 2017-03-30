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

function setup_docker {
    echo 'deb http://apt.dockerproject.org/repo ubuntu-xenial main' | sudo tee /etc/apt/sources.list.d/docker.list
    sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

    sudo apt-get update
    sudo apt-get install --no-install-recommends -y docker-engine

    sudo systemctl stop docker
    sudo mount -t tmpfs tmpfs /var/lib/docker
    sudo tee /etc/systemd/system/docker.service << EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --userns-remap default --storage-driver overlay2 --group jenkins
EOF
    sudo systemctl daemon-reload
    sudo systemctl start docker
}

debug_info
setup_docker
