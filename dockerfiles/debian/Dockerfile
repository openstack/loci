ARG FROM=debian:stretch
FROM ${FROM}

ARG DEBIAN_URL=http://deb.debian.org/debian/
ARG DEBIAN_SECURITY_URL=http://security.debian.org/
ARG DEBIAN_SECURITY_DISTRIBUTION=stretch/updates
ARG CEPH_URL=http://download.ceph.com/debian-luminous/
ARG ALLOW_UNAUTHENTICATED=false
ARG PIP_INDEX_URL=https://pypi.python.org/simple/
ARG PIP_TRUSTED_HOST=pypi.python.org
ENV PIP_INDEX_URL=${PIP_INDEX_URL}
ENV PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST}

COPY sources.list /etc/apt/
COPY ceph.gpg /etc/apt/trusted.gpg.d/
RUN sed -i \
        -e "s|%%DEBIAN_URL%%|${DEBIAN_URL}|g" \
        -e "s|%%DEBIAN_SECURITY_URL%%|${DEBIAN_SECURITY_URL}|g" \
        -e "s|%%DEBIAN_SECURITY_DISTRIBUTION%%|${DEBIAN_SECURITY_DISTRIBUTION}|g" \
        -e "s|%%CEPH_URL%%|${CEPH_URL}|g" \
        /etc/apt/sources.list
RUN echo "APT::Get::AllowUnauthenticated \"${ALLOW_UNAUTHENTICATED}\";" \
         > /etc/apt/apt.conf.d/allow-unathenticated
