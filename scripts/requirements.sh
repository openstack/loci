#!/bin/bash

set -eux

$(dirname $0)/setup_pip.sh
pip install git+https://github.com/openstack-infra/bindep
$(dirname $0)/install_packages.sh
$(dirname $0)/clone_project.sh
mv /tmp/requirements/{global-requirements.txt,upper-constraints.txt} /

# NOTE(SamYaple): https://issues.apache.org/jira/browse/PROTON-1381
# TODO(SamYaple): Make python-qpid-proton build here (possibly patch it)
if (( $(openssl version | awk -F'[ .]' '{print $3}') >= 1 )); then
    sed -i '/python-qpid-proton/d' /upper-constraints.txt
fi

# NOTE(SamYaple): Build all deps in parallel. This is safe because we are
# constrained on the version and we are building with --no-deps
export CASS_DRIVER_BUILD_CONCURRENCY=8
pushd $(mktemp -d)
split -l1 /upper-constraints.txt
ls -1 | xargs -n1 -P20 -t pip wheel --no-deps --wheel-dir / -c /upper-constraints.txt -r | tee /tmp/wheels.txt
popd
# NOTE(SamYaple): Handle packages not in upper-constriants and not in PyPI as
# native whls
additional_packages=(git+https://github.com/openstack-infra/bindep@24427065c5f30047ac80370be0a390e7f417ce34 uwsgi)
echo "${additional_packages[@]}" | xargs -n1 -P20 pip wheel --wheel-dir / -c /upper-constraints.txt

# NOTE(SamYaple) Remove native-binary wheels, we only want to keep wheels that
# we compiled ourselves
# TODO(SamYaple): Figure out how to not download a whl if it already exists in
# whl form upstream
awk -F'[ ,]+' '/^Skipping/ {gsub("-","_");print $2}' /tmp/wheels.txt | xargs -n1 bash -c 'ls /$1-*' _ | xargs rm

# NOTE(SamYaple): We want to purge all files that are not wheels or txt to
# reduce the size of the layer to only what is needed
shopt -s extglob
rm -rf /!(*whl|*txt) > /dev/null 2>&1 || :
