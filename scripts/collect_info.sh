#!/bin/bash

set -ex

INFO_DIR="/etc/image_info"
mkdir -p $INFO_DIR
PACKAGES_INFO="${INFO_DIR}/packages.txt"
PIP_INFO="${INFO_DIR}/pip.txt"
PROJECT_INFO="${INFO_DIR}/project.txt"

dpkg -l > $PACKAGES_INFO

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
