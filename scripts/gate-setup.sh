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
    sudo mount -o size=25g -t tmpfs tmpfs /var/lib/docker
    # TODO(SamYaple): Images cannot be build with userns-remap enabled. figure that out
    sudo tee /etc/systemd/system/docker.service << EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --storage-driver overlay2 --group jenkins
EOF
    sudo systemctl daemon-reload
    sudo systemctl start docker
}

function setup_swap {
    sudo fallocate -l20G /swap
    sudo chmod 0600 /swap
    sudo mkswap /swap
    sudo swapon /swap
}

# TODO(SamYaple): Should this be done in infra?
function clone_project {
    /usr/zuul-env/bin/zuul-cloner --cache-dir /opt/git git://git.openstack.org $ZUUL_PROJECT
}

debug_info
setup_swap
setup_docker
clone_project
