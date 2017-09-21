ARG FROM=ubuntu:xenial
FROM ${FROM}

RUN set -eux; \
    # Ceph.com (release key) <security@ceph.com>
    apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 08B73419AC32B4E966C1A330E84AC2C0460F3994; \
    echo "deb http://download.ceph.com/debian-luminous xenial main" | tee /etc/apt/sources.list.d/ceph.list; \
    # Canonical Cloud Archive Signing Key <ftpmaster@canonical.com>
    apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 391A9AA2147192839E9DB0315EDB1B62EC4926EA; \
    echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu xenial-updates/pike main" | tee /etc/apt/sources.list.d/cloudarchive.list
