ARG FROM=ubuntu:xenial
FROM ${FROM}

ENV PATH=/var/lib/openstack/bin:$PATH
ARG PROJECT
ARG WHEELS=loci/requirements:master-ubuntu
ARG PROJECT_REPO=https://git.openstack.org/cbaker423/${PROJECT}
ARG PROJECT_REF=master
ARG DISTRO
ARG PROFILES
ARG PIP_PACKAGES=""
ARG DIST_PACKAGES=""
ARG PLUGIN=no
ARG PYTHON3=no

ARG UID=42424
ARG GID=42424

ARG NOVNC_REPO=https://github.com/novnc/novnc
ARG NOVNC_REF=v1.0.0
ARG SPICE_REPO=https://github.com/SPICE/spice-html5
ARG SPICE_REF=spice-html5-0.1.6

COPY scripts /opt/loci/scripts
COPY bindep.txt pydep.txt /opt/loci/

RUN /opt/loci/scripts/install.sh
