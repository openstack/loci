ARG FROM=ubuntu:focal
FROM ${FROM}

ENV PATH=/var/lib/openstack/bin:$PATH
ARG PROJECT
ARG WHEELS=loci/requirements:master-ubuntu
ARG PROJECT_REPO=https://opendev.org/openstack/${PROJECT}
ARG PROJECT_REF=master
ARG PROJECT_RELEASE=master
ARG DISTRO=""
ARG PROFILES=""
ARG PIP_PACKAGES=""
ARG PIP_ARGS=""
ARG PIP_WHEEL_ARGS=$PIP_ARGS
ARG DIST_PACKAGES=""
ARG PLUGIN=no
ARG EXTRA_BINDEP=""
ARG EXTRA_PYDEP=""
ARG REGISTRY_PROTOCOL="detect"
ARG REGISTRY_INSECURE="False"
ARG KEEP_ALL_WHEELS="False"

# NOTE: This option is only applicable to apt/dpkg systems. The value is noop
# for rpm based systems. This will not show up in the final image regardless.
ARG DEBIAN_FRONTEND=noninteractive

ARG UID=42424
ARG GID=42424

ARG NOVNC_REPO=${NOVNC_REPO:-https://github.com/novnc/novnc}
ARG NOVNC_REF=${NOVNC_REF:-v1.0.0}
ARG SPICE_REPO=${SPICE_REPO:-https://gitlab.freedesktop.org/spice/spice-html5.git}
ARG SPICE_REF=${SPICE_REF:-spice-html5-0.1.6}

COPY scripts /opt/loci/scripts
ADD bindep.txt pydep.txt $EXTRA_BINDEP $EXTRA_PYDEP /opt/loci/

RUN /opt/loci/scripts/install.sh
