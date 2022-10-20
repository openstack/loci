ARG DISTRO=ubuntu
ARG DISTRO_RELEASE=xenial
ARG FROM=${DISTRO}:${DISTRO_RELEASE}
FROM ${FROM}

ENV PATH=/var/lib/openstack/bin:$PATH
ARG PROJECT
ARG DISTRO=ubuntu
ARG DISTRO_RELEASE=xenial
ARG WHEELS=loci/requirements:master-ubuntu
ARG PROJECT_REPO=https://opendev.org/openstack/${PROJECT}
ARG PROJECT_REF=master
ARG PROFILES
ARG PIP_PACKAGES=""
ARG PIP_ARGS=""
ARG PIP_WHEEL_ARGS=$PIP_ARGS
ARG DIST_PACKAGES=""
ARG PLUGIN=no
ARG PYTHON3=no
ARG EXTRA_BINDEP=""
ARG EXTRA_PYDEP=""
ARG EXTENSIONS="no"
ARG REGISTRY_PROTOCOL="detect"
ARG REGISTRY_INSECURE="False"
ARG SETUPTOOLS_VERSION_REQUIREMENT="<58"

ARG UID=42424
ARG GID=42424

ARG NOVNC_REPO=https://github.com/novnc/novnc
ARG NOVNC_REF=v1.0.0
ARG SPICE_REPO=https://gitlab.freedesktop.org/spice/spice-html5.git
ARG SPICE_REF=spice-html5-0.1.6

COPY scripts /opt/loci/scripts
ADD bindep.txt pydep.txt $EXTRA_BINDEP $EXTRA_PYDEP /opt/loci/

LABEL source_repository=${PROJECT_REPO}
RUN /opt/loci/scripts/install.sh
