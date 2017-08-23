ARG FROM=centos:7
FROM ${FROM}

ARG OVERRIDE=override

ADD $OVERRIDE /

RUN set -x \
    && yum install -y qemu-img \
    && yum clean all
