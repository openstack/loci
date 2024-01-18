#!/bin/bash

set -eux

$(dirname $0)/setup_pip.sh
pip install ${PIP_ARGS} bindep pkginfo

$(dirname $0)/install_packages.sh
$(dirname $0)/clone_project.sh
mv /tmp/requirements/{global-requirements.txt,upper-constraints.txt} /

# TODO: Make python-qpid-proton build here (possibly patch it)
# or remove when python-qpid-proton is updated with build fix.
#   https://issues.apache.org/jira/browse/PROTON-1381
if (( $(openssl version | awk -F'[ .]' '{print $3}') >= 1 )); then
    sed -i '/python-qpid-proton/d' /upper-constraints.txt
fi

# Remove python-qpid-proton 0.14.0 as this old version cannot be built in CI
# anymore
sed -i '/python-qpid-proton===0.14.0/d' /upper-constraints.txt

# Setuptools from constraints is not compatible with other constrainted packages
[[ "${PROJECT_REF}" == "master" ]] && sed -i '/setuptools/d' /upper-constraints.txt
# https://review.opendev.org/c/openstack/requirements/+/813693
sed -i '/^futures===/d' /upper-constraints.txt

# NOTE(mnaser): confluent-kafka fails to build under aarch64 because the version
#               of libfdkafka-dev in the distributions is too old (x86_64 relies
#               on the wheel inside PyPI).
if [[ "$(uname -p)" == "aarch64" ]]; then
    sed -i '/confluent-kafka/d' /upper-constraints.txt
fi

# Remove any pylxd before 2.2.7 as the old versions cannot be built in CI.
lxd_constraint=$(grep pylxd /upper-constraints.txt)
# This removes (##) everything (*) from the lxd_constraint until the last =,
# and removes all '.' to look like a number.
if (( $(echo ${lxd_constraint##*=} | sed 's#\.##g') < 227 )); then
    sed -i '/pylxd/d' /upper-constraints.txt
fi

mkdir /source-wheels
# Pre-build wheels for unnamed constraints
for entry in $(grep '^git+' /upper-constraints.txt); do
  pip wheel --no-deps --wheel-dir /source-wheels ${entry}
done

# Replace unnamed constraints with named ones
sed -i '/^git+/d' /upper-constraints.txt
for wheel in $(ls /source-wheels/*.whl); do
  python -c "import pkginfo; wheel = pkginfo.Wheel('${wheel}'); print('%s===%s' % (wheel.name, wheel.version))" >> /upper-constraints.txt
done

pushd $(mktemp -d)

export CASS_DRIVER_BUILD_CONCURRENCY=8

# The libnss3 headers in Ubuntu Jammy are not compatible
# with python-nss===1.0.1. Ubuntu Jammy itself
# provides the binary package python3-nss and
# they apply the patch that renames RSAPublicKey/DSAPublicKey
# types into PyRSAPublicKey/PyDSAPublicKey.
# Here we do the same.
if [[ ${distro} == "ubuntu" ]] && [[ ${distro_version} == "jammy" ]] && grep -q "python-nss===1.0.1" /upper-constraints.txt; then
    sed -i '/python-nss/d' /upper-constraints.txt
    pip download python-nss===1.0.1
    tar jxf python-nss-1.0.1.tar.bz2 && rm -f python-nss-1.0.1.tar.bz2
    pushd python-nss-1.0.1
    patch -p1 < $(dirname $0)/python-nss-1.0.1-fix-ftbfs.diff
    pip wheel ${PIP_WHEEL_ARGS} --find-links /source-wheels -c /upper-constraints.txt . && mv *.whl / || echo "python-nss===1.0.1" >> /failure
    popd && rm -r python-nss-1.0.1
fi

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
  pip install ${PIP_ARGS} -c /upper-constraints.txt --no-cache ${PIP_PACKAGES}
fi

export UWSGI_PROFILE_OVERRIDE=ssl=true
export CPUCOUNT=1

# Build all dependencies in parallel. This is safe because we are
# constrained on the version and we are building with --no-deps
echo uwsgi enum-compat ${PIP_PACKAGES} | xargs -n1 | split -l1 -a3
if [[ "$KEEP_ALL_WHEELS" == "False" ]]; then
  ls -1 | xargs -n1 -P20 -t bash -c 'pip wheel ${PIP_WHEEL_ARGS} --find-links /source-wheels --find-links / --no-deps --wheel-dir / -c /upper-constraints.txt -r $1 || cat $1 >> /failure' _ | tee /tmp/wheels.txt
  # Remove native-binary wheels, we only want to keep wheels that we
  # compiled ourselves.
  awk -F'[ ,]+' '/^Skipping/ {gsub("-","_");print $2}' /tmp/wheels.txt | xargs -r -n1 bash -c 'ls /$1-*' _ | sort -u | xargs -t -r rm
  # Wheels built from unnamed constraints were removed with previous command. Move them back after deletion.
  [ ! -z "$(ls -A /source-wheels)" ] && mv /source-wheels/*.whl /
else
  ls -1 | xargs -n1 -P20 -t bash -c 'mkdir $1-wheels; pip wheel ${PIP_WHEEL_ARGS} --find-links /source-wheels --find-links / --wheel-dir /$(pwd)/$1-wheels -c /upper-constraints.txt -r $1 || cat $1 >> /failure' _
  for dir in *-wheels/; do [ ! -z "$(ls -A ${dir})" ] && mv ${dir}*.whl /; done
fi

# TODO: Improve the failure catching
if [[ -f /failure ]]; then
    echo Wheel failed to build
    cat /failure
    exit 1
fi

# Purge all files that are not wheels or txt to reduce the size of the
# layer to only what is needed
shopt -s extglob
rm -rf /!(*whl|*txt) > /dev/null 2>&1 || :
