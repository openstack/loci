#!/bin/bash

set -eux

$(dirname $0)/setup_pip.sh
pip install ${PIP_ARGS} bindep

$(dirname $0)/install_packages.sh
$(dirname $0)/clone_project.sh
mv /tmp/requirements/{global-requirements.txt,upper-constraints.txt,custom-requirements.txt} /

# TODO: Make python-qpid-proton build here (possibly patch it)
# or remove when python-qpid-proton is updated with build fix.
#   https://issues.apache.org/jira/browse/PROTON-1381
if (( $(openssl version | awk -F'[ .]' '{print $3}') >= 1 )); then
    sed -i '/python-qpid-proton/d' /upper-constraints.txt
fi

if [[ "${PYTHON3}" == "no" ]]; then
    ignore_wheels=py2
else
    ignore_wheels=py3
fi

pushd $(mktemp -d)

# Build all dependencies in parallel. This is safe because we are
# constrained on the version and we are building with --no-deps
export CASS_DRIVER_BUILD_CONCURRENCY=8

# Drop python packages requested by monasca_analytics. Their
# build time is huge and on !x86 we do not get binaries from Pypi.
egrep -v "(scipy|scikit-learn)" /upper-constraints.txt | split -l1

# When a package uses the variable 'setup_requires' in 'setup.py',
# 'pip wheel' dependency management will be overridden, resulting in
# possible incompatibilities between packages. Installing packages using
# upper-constraints.txt before building the wheels ensures the correct
# package versions will be available and installed locally.
#   https://pip.readthedocs.io/en/stable/user_guide/#installation-bundles
# This allows to work around such issues as
#   https://github.com/lxc/pylxd/issues/308
if [ ! -z "${PIP_PACKAGES}" ]; then
  pip install ${PIP_ARGS} -c /upper-constraints.txt ${PIP_PACKAGES}
fi

grep -v "^#" /upper-constraints.txt | split -l1 - x
# additional custom-requirements?
if [ -e /custom-requirements.txt ]; then
    grep -v "^#" /custom-requirements.txt | split -l1 - y
fi
echo uwsgi enum-compat ${PIP_PACKAGES} | xargs -n1 | split -l1 -a3 - p
ls -1 | xargs -n1 -P20 -t bash -c 'pip wheel ${PIP_WHEEL_ARGS} --exists-action i --no-deps --wheel-dir / -c /upper-constraints.txt -r $1 || cat $1 >> /failure' _ | tee /tmp/wheels.txt

# TODO: Improve the failure catching
if [[ -f /failure ]]; then
    echo Wheel failed to build
    cat /failure
    exit 1
fi

# Remove native-binary wheels, we only want to keep wheels that we
# compiled ourselves.
#awk -F'[ ,]+' '/^Skipping/ {gsub("-","_");print $2}' /tmp/wheels.txt | xargs -r -n1 bash -c 'ls /$1-*' _ | sort -u | xargs -t -r rm

# Purge all files that are not wheels or txt to reduce the size of the
# layer to only what is needed
shopt -s extglob
rm -rf /!(*whl|*txt) > /dev/null 2>&1 || :
