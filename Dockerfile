ARG FROM=ubuntu:jammy
FROM ${FROM}

ENV PATH=/var/lib/openstack/bin:$PATH
ENV LANG=C.UTF-8
ARG PROJECT
ARG WHEELS=loci/requirements:master-ubuntu_jammy
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

ARG GET_PIP_URL="https://bootstrap.pypa.io/get-pip.py"
ARG PIP_CONSTRAINT=""
ARG SETUPTOOL_CONSTRAINT=""
ARG WHEEL_CONSTRAIN=""

# End virtualenv argumens

ADD data /tmp/
COPY scripts /opt/loci/scripts
ADD bindep.txt pydep.txt $EXTRA_BINDEP $EXTRA_PYDEP /opt/loci/

RUN /opt/loci/scripts/install.sh
