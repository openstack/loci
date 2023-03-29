#!/bin/bash

set -eux

git clone --filter=tree:0 ${PROJECT_REPO} /tmp/${PROJECT}
pushd /tmp/${PROJECT}
git checkout ${PROJECT_REF}
popd
