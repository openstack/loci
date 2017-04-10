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

function generate_override {
    set -eux

    local distro=$1
    source /etc/nodepool/provider

    NODEPOOL_MIRROR_HOST=${NODEPOOL_MIRROR_HOST:-mirror.${NODEPOOL_REGION,,}.$NODEPOOL_CLOUD.openstack.org}

    CURDIR=$(pwd)
    cd $(mktemp -d)
    case $distro in
    ubuntu)
        mkdir -p etc/apt
        echo 'APT::Get::AllowUnauthenticated "true";' > etc/apt/apt.conf
        cat << EOF > etc/apt/sources.list
deb http://${NODEPOOL_MIRROR_HOST}/ubuntu xenial main restricted universe
deb http://${NODEPOOL_MIRROR_HOST}/ubuntu xenial-updates main restricted universe
deb http://${NODEPOOL_MIRROR_HOST}/ubuntu xenial-security main restricted universe
EOF
    ;;
    debian)
        mkdir -p etc/apt
        echo 'APT::Get::AllowUnauthenticated "true";' >> etc/apt/apt.conf
        cat << EOF > etc/apt/sources.list
deb http://${NODEPOOL_MIRROR_HOST}/debian jessie main
deb http://${NODEPOOL_MIRROR_HOST}/debian jessie-updates main
deb http://${NODEPOOL_MIRROR_HOST}/debian jessie-security main
deb http://${NODEPOOL_MIRROR_HOST}/debian jessie-backports main
EOF
    ;;
    centos)
        mkdir -p etc/yum.repos.d
        cat << EOF > etc/yum.repos.d/CentOS-Base.repo
[base]
name=CentOS-\$releasever - Base
baseurl=http://${NODEPOOL_MIRROR_HOST}/centos/\$releasever/os/\$basearch/
gpgcheck=0

[updates]
name=CentOS-\$releasever - Updates
baseurl=http://${NODEPOOL_MIRROR_HOST}/centos/\$releasever/updates/\$basearch/
gpgcheck=0

[extras]
name=CentOS-\$releasever - Extras
baseurl=http://${NODEPOOL_MIRROR_HOST}/centos/\$releasever/extras/\$basearch/
gpgcheck=0

[centos-openstack-ocata]
includepkgs=liberasurecode*
name=CentOS-7 - OpenStack Ocata
baseurl=http://${NODEPOOL_MIRROR_HOST}/centos/7/cloud/\$basearch/openstack-ocata/
gpgcheck=0
EOF
    ;;
    *)
    echo "Unknown distro: ${distro}"
    exit 1
    ;;
    esac

    tar cfz ${CURDIR}/override.tar.gz .
}

function builder {
    set -eux

    local directory=$1
    cd ${directory}
    local distro=${PWD##*/}
    local log=${LOGS_DIR}/builds/${distro}.log

    local build_args="--build-arg OVERRIDE=override.tar.gz"
    build_args+=" --build-arg PROJECT_REPO=http://172.17.0.1/openstack/${ZUUL_PROJECT#*-} --build-arg PROJECT_REF=zuul"
    build_args+=" --build-arg SCRIPTS_REPO=http://172.17.0.1/openstack/loci --build-arg SCRIPTS_REF=zuul"
    $(generate_override $distro)
    docker build --no-cache ${build_args} . 2>&1 > ${log} || echo ${log} >> ${LOGS_DIR}/build_error
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
