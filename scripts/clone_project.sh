#!/bin/bash

set -eux

git clone --filter=tree:0 ${PROJECT_REPO} ${PROJECT_DEST}
pushd ${PROJECT_DEST}
git checkout ${PROJECT_REF}
popd
