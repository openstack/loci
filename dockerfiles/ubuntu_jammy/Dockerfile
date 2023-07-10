ARG FROM=ubuntu:jammy
FROM ${FROM}

ARG UBUNTU_URL=http://archive.ubuntu.com/ubuntu/
ARG CLOUD_ARCHIVE_URL=http://ubuntu-cloud.archive.canonical.com/ubuntu/
ARG CEPH_URL=http://download.ceph.com/debian-reef/
ARG ALLOW_UNAUTHENTICATED=false
ARG PIP_INDEX_URL=https://pypi.python.org/simple/
ARG PIP_TRUSTED_HOST=pypi.python.org
ENV PIP_INDEX_URL=${PIP_INDEX_URL}
ENV PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST}

COPY sources.list /etc/apt/
COPY cloud-archive.gpg ceph.gpg /etc/apt/trusted.gpg.d/
RUN sed -i \
        -e "s|%%UBUNTU_URL%%|${UBUNTU_URL}|g" \
        -e "s|%%CLOUD_ARCHIVE_URL%%|${CLOUD_ARCHIVE_URL}|g" \
        -e "s|%%CEPH_URL%%|${CEPH_URL}|g" \
        /etc/apt/sources.list
RUN echo "APT::Get::AllowUnauthenticated \"${ALLOW_UNAUTHENTICATED}\";\n\
Acquire::AllowInsecureRepositories \"${ALLOW_UNAUTHENTICATED}\";\n\
Acquire::AllowDowngradeToInsecureRepositories \"${ALLOW_UNAUTHENTICATED}\";" \
    >> /etc/apt/apt.conf.d/allow-unathenticated
