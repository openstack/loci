ARG FROM=centos:7
FROM ${FROM}

ENV GENERIC=yes
ENV PATH=/var/lib/openstack/bin:$PATH
ARG PROJECT
ARG WHEELS=openstackloci/requirements:centos
ARG PROJECT_REPO=https://git.openstack.org/openstack/${PROJECT}
ARG PROJECT_REF=master
ARG SCRIPTS_REPO=https://git.openstack.org/openstack/loci
ARG SCRIPTS_REF=master
ARG DISTRO
ARG PROFILES
ARG PYPI_PACKAGES

RUN set -ex; \
    yum upgrade -y; \
    yum install -y git; \
    git init /tmp/common/; \
    git --git-dir /tmp/common/.git fetch --depth 1 $SCRIPTS_REPO $SCRIPTS_REF; \
    git --work-tree /tmp/common --git-dir /tmp/common/.git checkout FETCH_HEAD; \
    /tmp/common/scripts/install.sh ${PYPI_PACKAGES}
