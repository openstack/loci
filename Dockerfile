ARG FROM=ubuntu:xenial
FROM ${FROM}

ENV PATH=/var/lib/openstack/bin:$PATH
ENV UWSGI_EMBED_PLUGINS=stats_pusher_statsd
ARG PROJECT
ARG WHEELS=loci/requirements:master-ubuntu
ARG PROJECT_REPO=https://git.openstack.org/openstack/${PROJECT}
ARG PROJECT_REF=master
ARG DISTRO
ARG PROFILES
ARG PIP_PACKAGES=""
ARG PIP_ARGS=""
ARG PIP_WHEEL_ARGS=$PIP_ARGS
ARG DIST_PACKAGES=""
ARG PLUGIN=no
ARG PYTHON3=no
ARG EXTRA_BINDEP=""
ARG EXTRA_PYDEP=""
ARG EXTENSIONS
ARG APIC_URL
ARG REGISTRY_PROTOCOL="detect"
ARG REGISTRY_INSECURE="False"

ARG UID=42424
ARG GID=42424

ARG NOVNC_REPO=https://github.com/novnc/novnc
ARG NOVNC_REF=v1.0.0
ARG SPICE_REPO=https://gitlab.freedesktop.org/spice/spice-html5.git
ARG SPICE_REF=spice-html5-0.1.6

COPY scripts /opt/loci/scripts
ADD bindep.txt pydep.txt $EXTRA_BINDEP $EXTRA_PYDEP /opt/loci/

RUN if [ "x$EXTENSIONS" = "x" ] ; then /opt/loci/scripts/install.sh ; else /opt/loci/scripts/install_extensions.sh ; fi