ARG FROM=ubuntu:xenial
FROM ${FROM}

ARG UBUNTU_URL=http://archive.ubuntu.com/ubuntu/
ARG CLOUD_ARCHIVE_URL=http://ubuntu-cloud.archive.canonical.com/ubuntu/
ARG CEPH_URL=http://download.ceph.com/debian-luminous/
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
RUN echo "APT::Get::AllowUnauthenticated \"${ALLOW_UNAUTHENTICATED}\";" \
         > /etc/apt/apt.conf.d/allow-unathenticated

# add SAP certificates
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
RUN echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils && \
    DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y -u && \
    apt-get install -u -y --no-install-recommends ca-certificates wget && \
    wget -O /usr/local/share/ca-certificates/SAP_Global_Root_CA.crt http://aia.pki.co.sap.com/aia/SAP%20Global%20Root%20CA.crt && \
    wget -O /usr/local/share/ca-certificates/SAP_Global_Sub_CA_02.crt http://aia.pki.co.sap.com/aia/SAP%20Global%20Sub%20CA%2002.crt && \
    wget -O /usr/local/share/ca-certificates/SAP_Global_Sub_CA_04.crt http://aia.pki.co.sap.com/aia/SAP%20Global%20Sub%20CA%2004.crt && \
    wget -O /usr/local/share/ca-certificates/SAP_Global_Sub_CA_05.crt http://aia.pki.co.sap.com/aia/SAP%20Global%20Sub%20CA%2005.crt && \
    wget -O /usr/local/share/ca-certificates/SAPNetCA_G2.crt http://aia.pki.co.sap.com/aia/SAPNetCA_G2.crt && \
    update-ca-certificates && \
    apt-get purge -y ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache
