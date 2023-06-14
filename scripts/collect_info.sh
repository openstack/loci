#!/bin/bash

set -ex

INFO_DIR="/etc/image_info"
mkdir -p $INFO_DIR
PACKAGES_INFO="${INFO_DIR}/packages.txt"
PIP_INFO="${INFO_DIR}/pip.txt"
PROJECT_INFO="${INFO_DIR}/project.txt"

case ${distro} in
    ubuntu)
        dpkg -l > $PACKAGES_INFO
        ;;
    centos)
        yum list installed > $PACKAGES_INFO
        ;;
    *)
        echo "Unknown distro: ${distro}"
        exit 1
        ;;
esac

pip freeze > $PIP_INFO
cat > ${PROJECT_INFO} <<EOF
PROJECT=${PROJECT}
PROJECT_REPO=${PROJECT_REPO}
PROJECT_REF=${PROJECT_REF}
PROJECT_RELEASE=${PROJECT_RELEASE}
EOF
pushd /tmp/${PROJECT}
echo "========"
git log -1 >> ${PROJECT_INFO}
popd
