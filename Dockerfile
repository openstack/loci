ARG FROM=ubuntu:xenial
FROM ${FROM}

ENV PATH=/var/lib/openstack/bin:$PATH
ARG PROJECT
ARG WHEELS=openstackloci/requirements:ubuntu
ARG PROJECT_REPO=https://git.openstack.org/openstack/${PROJECT}
ARG PROJECT_REF=master
ARG DISTRO
ARG PROFILES
ARG PIP_PACKAGES

COPY scripts /opt/loci/scripts
COPY bindep.txt /opt/loci/

RUN /opt/loci/scripts/install.sh
