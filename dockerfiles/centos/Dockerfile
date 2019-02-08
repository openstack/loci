ARG FROM=centos:7
FROM ${FROM}

ARG PACKAGE_MIRROR=mirror.centos.org
ARG PIP_INDEX_URL=https://pypi.python.org/simple/
ARG PIP_TRUSTED_HOST=pypi.python.org
ENV PIP_INDEX_URL=${PIP_INDEX_URL}
ENV PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST}

RUN rm -rf /etc/yum.repos.d/*
COPY CentOS.repo /etc/yum.repos.d/
COPY RPM-GPG-KEY-CentOS-SIG-Cloud /etc/pki/rpm-gpg/
RUN sed -i "s|%%PACKAGE_MIRROR%%|${PACKAGE_MIRROR}|g" /etc/yum.repos.d/CentOS.repo \
  && yum install -y centos-release-qemu-ev \
  && yum update -y
