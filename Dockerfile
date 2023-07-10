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
ARG MKS_REPO=https://github.com/rgerganov/noVNC.git
ARG MKS_REF=master

COPY scripts /opt/loci/scripts
ADD bindep.txt pydep.txt $EXTRA_BINDEP $EXTRA_PYDEP /opt/loci/

LABEL source_repository=${PROJECT_REPO}
ARG PIP_CACHE_DIR=/var/cache/pip
ARG FETCH_WHEELS_CACHE_DIR=/var/cache/fetch_wheels
ARG WHEELS_DEST=/tmp/wheels
ARG PROJECT_DEST=/tmp/${PROJECT}
ARG CACHEBUST=0 # In order to force a rebuild of any layer following this line
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=${PIP_CACHE_DIR},sharing=locked \
    --mount=type=cache,target=${FETCH_WHEELS_CACHE_DIR},sharing=locked \
    --mount=type=cache,target=/root/.cache,sharing=locked \
    /opt/loci/scripts/install.sh
