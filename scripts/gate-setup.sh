#!/bin/bash

set -eux

function setup_git_server {
    sudo apt-get install --no-install-recommends -y apache2 gitweb
    sudo systemctl stop apache2

    mkdir repos logs/git-server
    pushd repos
    local repos=(openstack/{loci,${ZUUL_PROJECT#*-}})
    /usr/zuul-env/bin/zuul-cloner --cache-dir /opt/git git://git.openstack.org ${repos[@]}
    for p in ${repos[@]}; do
        git --git-dir ${p}/.git checkout -b zuul
    done
    popd

    sed -i "s|##WORKSPACE##|${WORKSPACE}|g" openstack/loci/confs/git-server.conf
    sudo apache2 -f ${WORKSPACE}/openstack/loci/confs/git-server.conf
}

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
    # TODO(SamYaple): CentOS cannot be build with userns-remap enabled. httpd
    # uses cap_set_file capability and there is no way to pass that in at build
    # time yet.
    sudo tee /etc/systemd/system/docker.service << EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --storage-driver overlay2 --group jenkins
EOF
    sudo systemctl daemon-reload
    sudo systemctl start docker

    # NOTE(SamYaple): Allow all connections from containers to host ports
    sudo iptables -I INPUT -i docker0 -j ACCEPT
}

function setup_swap {
    sudo fallocate -l20G /swap
    sudo chmod 0600 /swap
    sudo mkswap /swap
    sudo swapon /swap
}

function setup_logs {
    mkdir logs
}

setup_logs
debug_info | tee logs/gate_info.log
setup_swap
setup_docker
setup_git_server
