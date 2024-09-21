ARG FROM=ubuntu:jammy
FROM ${FROM}

ARG CEPH_REPO="deb https://download.ceph.com/debian-reef/ jammy main"
ARG CEPH_KEY="https://download.ceph.com/keys/release.asc"
ARG ALLOW_UNAUTHENTICATED=false

RUN echo "APT::Get::AllowUnauthenticated \"${ALLOW_UNAUTHENTICATED}\";\n\
Acquire::AllowInsecureRepositories \"${ALLOW_UNAUTHENTICATED}\";\n\
Acquire::AllowDowngradeToInsecureRepositories \"${ALLOW_UNAUTHENTICATED}\";" \
    >> /etc/apt/apt.conf.d/allow-unathenticated

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        gnupg2 \
        wget && \
    wget -q -O- ${CEPH_KEY} | apt-key add - && \
    echo "${CEPH_REPO}" | tee /etc/apt/sources.list.d/ceph.list && \
    apt-get remove -y wget gnupg2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
