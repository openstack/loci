#!/bin/bash -ex

git clone --depth 1 ${PROJECT_REPO} /tmp/${PROJECT} -b ${PROJECT_REF}
#git --git-dir /tmp/${PROJECT}/.git fetch ${PROJECT_REPO} ${PROJECT_REF}
#git --work-tree /tmp/${PROJECT} --git-dir /tmp/${PROJECT}/.git checkout FETCH_HEAD
