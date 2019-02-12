ARG FROM=opensuse/leap:15
FROM ${FROM}

ARG PACKAGE_MIRROR=http://download.opensuse.org/
ARG PIP_INDEX_URL=https://pypi.python.org/simple/
ARG PIP_TRUSTED_HOST=pypi.python.org
ENV PIP_INDEX_URL=${PIP_INDEX_URL}
ENV PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST}

RUN for filename in $(grep -Rl enabled=1 /etc/zypp/repos.d/); do sed -i "s|http://download.opensuse.org/|${PACKAGE_MIRROR}|" $filename; done && zypper refresh && zypper up -y && zypper install -y tar gzip which unzip
