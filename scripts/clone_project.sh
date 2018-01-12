#!/bin/bash

set -eux

git clone ${PROJECT_REPO} /tmp/${PROJECT}
pushd /tmp/${PROJECT}
git fetch ${PROJECT_REPO} ${PROJECT_REF}
git checkout FETCH_HEAD
popd
