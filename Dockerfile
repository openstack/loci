ARG WHEELS=quay.io/airshipit/requirements:master-ubuntu_jammy
ARG FROM=ubuntu:jammy

# This is an alias for mounting the wheels image
FROM ${WHEELS} AS wheels

FROM ${FROM} AS common

ENV PATH=/var/lib/openstack/bin:$PATH
ENV LANG=C.UTF-8

# WHEELS_PATH must not be somewhere in /tmp because /tmp/* are deleted in the end of build
ARG WHEELS_PATH="/wheels"
ARG PROJECT
ARG PROJECT_REPO=https://opendev.org/openstack/${PROJECT}
ARG PROJECT_REF=master
ARG PROJECT_RELEASE=master
ARG EXTRA_PROJECTS=""
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
ARG HORIZON_EXTRA_PANELS
ARG PROJECT_PIP_EXTRAS

# NOTE: This option is only applicable to apt/dpkg systems. The value is noop
# for rpm based systems. This will not show up in the final image regardless.
ARG DEBIAN_FRONTEND=noninteractive

ARG UID=42424
ARG GID=42424

# Nova arguments
# User/group that swtpm binary runs as.
ARG NOVA_TSS_USER=tss
ARG NOVA_TSS_UID=42434
ARG NOVA_TSS_GID=42434

ARG NOVNC_REPO=https://github.com/novnc/novnc
ARG NOVNC_REF=v1.0.0
ARG SPICE_REPO=https://gitlab.freedesktop.org/spice/spice-html5.git
ARG SPICE_REF=spice-html5-0.1.6

# End Nova arguments

# Virtualenv arguments

ARG PIP_CONSTRAINT=""
ARG SETUPTOOL_CONSTRAINT=""
ARG WHEEL_CONSTRAIN=""

# End virtualenv argumens

ADD data /tmp/
COPY scripts /opt/loci/scripts
ADD bindep.txt pydep.txt $EXTRA_BINDEP $EXTRA_PYDEP /opt/loci/

FROM common AS requirements
RUN /opt/loci/scripts/install.sh

FROM common AS project
RUN --mount=type=bind,from=wheels,target=${WHEELS_PATH} /opt/loci/scripts/install.sh
