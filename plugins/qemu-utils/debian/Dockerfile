ARG FROM=debian:jessie-slim
FROM ${FROM}

ARG OVERRIDE=override

ADD $OVERRIDE /

RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends qemu-utils \
    && rm -rf /var/lib/apt/lists/*
