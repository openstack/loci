#!/bin/bash -ex

git clone ${PROJECT_REPO} /tmp/${PROJECT}
git --git-dir /tmp/${PROJECT}/.git fetch ${PROJECT_REPO} ${PROJECT_REF}
git --work-tree /tmp/${PROJECT} --git-dir /tmp/${PROJECT}/.git checkout FETCH_HEAD
