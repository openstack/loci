ARG DISTRO=ubuntu
ARG DISTRO_RELEASE=xenial
ARG FROM=${DISTRO}:${DISTRO_RELEASE}
FROM ${FROM}

ARG DISTRO=ubuntu
ARG DISTRO_RELEASE=xenial
ARG UBUNTU_URL=http://archive.ubuntu.com/ubuntu/
ARG CLOUD_ARCHIVE_URL=http://ubuntu-cloud.archive.canonical.com/ubuntu/
ARG ALLOW_UNAUTHENTICATED=false
ARG PIP_INDEX_URL=https://pypi.python.org/simple/
ARG PIP_TRUSTED_HOST=pypi.python.org
ENV PIP_INDEX_URL=${PIP_INDEX_URL}
ENV PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST}
ARG OPENSTACK_RELEASE=rocky

LABEL source_repository="https://github.com/sapcc/loci"

COPY sources.list /etc/apt/
COPY cloud-archive.gpg ceph.gpg /etc/apt/trusted.gpg.d/
RUN bash -c '[[ "$OPENSTACK_RELEASE" == "mitaka" ]] && sed -i -e /%%CLOUD_ARCHIVE_URL%%/d /etc/apt/sources.list; exit 0'
RUN sed -i \
        -e "s|%%UBUNTU_URL%%|${UBUNTU_URL}|g" \
        -e "s|%%UBUNTU_RELEASE%%|${DISTRO_RELEASE}|g" \
        -e "s|%%CLOUD_ARCHIVE_URL%%|${CLOUD_ARCHIVE_URL}|g" \
        -e "s|%%OPENSTACK_RELEASE%%|${OPENSTACK_RELEASE}|g" \
        /etc/apt/sources.list
RUN echo "APT::Get::AllowUnauthenticated \"${ALLOW_UNAUTHENTICATED}\";" > /etc/apt/apt.conf.d/allow-unathenticated

# add SAP certificates
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
COPY certificates/* /usr/local/share/ca-certificates/

RUN echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ca-certificates && \
    update-ca-certificates && \
    apt-get purge -y --auto-remove ca-certificates && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache
