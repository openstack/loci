#!/bin/bash

# NOTE(SamYaple): It is not safe to have multiple instances of this script
# running at once due to (poor) error handling
# TODO(SamYaple): Make this script safer if running outside the gate

set -eux

if [[ -e /etc/nodepool/provider ]]; then
    export RUNNING_IN_GATE=true
    export LOGS_DIR=${WORKSPACE}/logs
else
    export RUNNING_IN_GATE=false
    export LOGS_DIR=$(mktemp -d)
fi

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

function debian_override {
    mkdir -p etc/apt/
    echo 'APT::Get::AllowUnauthenticated "true";' > etc/apt/apt.conf
    cat <<-EOF > etc/apt/sources.list
	deb http://${NODEPOOL_MIRROR_HOST}/debian jessie main
	deb http://${NODEPOOL_MIRROR_HOST}/debian jessie-updates main
	deb http://${NODEPOOL_MIRROR_HOST}/debian jessie-security main
	EOF
}

function ubuntu_override {
    mkdir -p etc/apt/
    echo 'APT::Get::AllowUnauthenticated "true";' > etc/apt/apt.conf
    cat <<-EOF > etc/apt/sources.list
	deb http://${NODEPOOL_MIRROR_HOST}/ubuntu xenial main restricted universe
	deb http://${NODEPOOL_MIRROR_HOST}/ubuntu xenial-updates main restricted universe
	deb http://${NODEPOOL_MIRROR_HOST}/ubuntu xenial-security main restricted universe
	EOF
}

function centos_override {
    mkdir -p etc/yum.repos.d/
    cat <<-EOF > etc/yum.repos.d/CentOS-Base.repo
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
	EOF
}

function debian_backports_override {
    mkdir -p etc/apt/sources.list.d/
    cat <<-EOF > etc/apt/sources.list.d/backports.list
	deb http://${NODEPOOL_MIRROR_HOST}/debian jessie-backports main
	EOF
}

function debian_ceph_override {
    mkdir -p etc/apt/sources.list.d/
    # NOTE(SamYaple): Update after https://review.openstack.org/#/c/452547/
    # Currently Jewel repos are not mirrored.
    cat <<-EOF > etc/apt/sources.list.d/ceph.list
	deb http://download.ceph.com/debian-jewel/ jessie main
	EOF
}

function ubuntu_ceph_override {
    mkdir -p etc/apt/sources.list.d/
    cat <<-EOF > etc/apt/sources.list.d/ceph.list
	deb http://${NODEPOOL_MIRROR_HOST}/ceph-deb-jewel/ xenial main
	EOF
}

function centos_ceph_override {
    # TODO(SamYaple): Add centos mirror to infra
    cat <<-EOF > etc/yum.repos.d/Ceph.repo
	[centos-ceph-jewel]
	name=CentOS-7 - Ceph Jewel
	baseurl=http://download.ceph.com/rpm-jewel/el7/noarch
	gpgcheck=0
	EOF
}

function centos_openstack_override {
    cat <<-EOF > etc/yum.repos.d/CentOS-OpenStack.repo
	[centos-openstack-ocata]
	includepkgs=liberasurecode*
	name=CentOS-7 - OpenStack Ocata
	baseurl=http://${NODEPOOL_MIRROR_HOST}/centos/7/cloud/\$basearch/openstack-ocata/
	gpgcheck=0
	EOF
}

function generate_override {
    set -eux

    source /etc/nodepool/provider

    if [[ -z "${NODEPOOL_MIRROR_HOST-}" ]]; then
        local NODEPOOL_MIRROR_HOST=mirror.${NODEPOOL_REGION,,}.${NODEPOOL_CLOUD}.openstack.org
    fi

    local TARBALL=${PWD}/override.tar.gz
    cd $(mktemp -d)

    ${DISTRO}_override
    if [[ -n ${PLUGIN-} ]] && type -t ${DISTRO}_${PLUGIN}_override; then
        ${DISTRO}_${PLUGIN}_override
    fi
    if [[ -n ${EXTRA-} ]] && type -t ${DISTRO}_${EXTRA}_override; then
        ${DISTRO}_${EXTRA}_override
    fi

    tar cfz ${TARBALL} .
}

function builder {
    set -eux

    local directory=$1
    cd ${directory}
    source testvars
    if [[ ! -n "${PLUGIN-}" ]]; then
        local log=${LOGS_DIR}/builds/${DISTRO}.log
    else
        local log=${LOGS_DIR}/builds/${DISTRO}-${PLUGIN}.log
    fi

    local build_args=""

    if $RUNNING_IN_GATE; then
        build_args+="--build-arg OVERRIDE=override.tar.gz"
        build_args+=" --build-arg PROJECT_REPO=http://172.17.0.1/openstack/${ZUUL_PROJECT#*-} --build-arg PROJECT_REF=zuul"
        build_args+=" --build-arg SCRIPTS_REPO=http://172.17.0.1/openstack/loci --build-arg SCRIPTS_REF=zuul"
        $(generate_override)
    fi
    if [[ ! -n "${PLUGIN-}" ]]; then
        docker build --tag openstackloci/${PROJECT}:${DISTRO} --no-cache ${build_args} . 2>&1 > ${log} || echo ${log} >> ${LOGS_DIR}/build_error
    else
        docker build --tag openstackloci/${PROJECT}:${DISTRO}-${PLUGIN} --no-cache ${build_args} . 2>&1 > ${log} || echo ${log} >> ${LOGS_DIR}/build_error
    fi
}

# NOTE(SamYaple): We must export the functions for use with subshells (xargs)
export -f $(compgen -A function)

prep_log_dir

echo "Building images"
find . -mindepth 2 -maxdepth 2 -type f -name Dockerfile -printf '%h\0' | xargs -r -0 -P10 -n1 bash -c 'builder $1' _
echo "Building plugins"
find . -mindepth 3 -maxdepth 3 -type f -name Dockerfile -printf '%h\0' | xargs -r -0 -P10 -n1 bash -c 'builder $1' _

if [[ -f ${LOGS_DIR}/build_error ]]; then
    echo "Building images failure; Dumping failed logs to stdout"
    dump_error_logs
else
    echo "Building images successful"
fi
