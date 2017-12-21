ARG FROM=ubuntu:xenial
FROM ${FROM}

ENV PATH=/var/lib/openstack/bin:$PATH
ARG PROJECT
ARG WHEELS=loci/requirements:master-ubuntu
ARG PROJECT_REPO=https://git.openstack.org/openstack/${PROJECT}
ARG PROJECT_REF=master
ARG DISTRO
ARG PROFILES
ARG PIP_PACKAGES=""
ARG PLUGIN=no
ARG PYTHON3=no

COPY scripts /opt/loci/scripts
COPY bindep.txt /opt/loci/

RUN /opt/loci/scripts/install.sh
