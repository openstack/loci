#!/bin/bash

set -eux

if [[ ! -d /tmp/${PROJECT} ]]; then
  git clone ${PROJECT_REPO} /tmp/${PROJECT}
  pushd /tmp/${PROJECT}
  git fetch ${PROJECT_REPO} ${PROJECT_REF}
  git checkout FETCH_HEAD
  popd
fi
