#!/bin/bash

set -eux


SOURCES_DIR=/tmp
UPPER_CONSTRAINTS=/upper-constraints.txt
UPPER_CONSTRAINTS_BUILD=/build-upper-constraints.txt
UPPER_CONSTRAINTS_DEV=/dev-upper-constraints.txt

$(dirname $0)/setup_pip.sh
pip install ${PIP_ARGS} bindep pkginfo

$(dirname $0)/install_packages.sh
$(dirname $0)/clone_project.sh
mv /tmp/requirements/{global-requirements.txt,upper-constraints.txt} /

function get_pkg_name {
  local folder=$1
  local name
  pushd $folder > /dev/null
  name=$(python3 setup.py --name 2>/dev/null | grep -v '^\[pbr\]')
  popd > /dev/null
  echo $name
}

function get_pkg_version {
  local folder=$1
  local vesion
  pushd $folder > /dev/null
  version=$(python3 setup.py --version 2>/dev/null | grep -v '^\[pbr\]')
  popd > /dev/null
  echo $version
}

function get_pipy_name_by_project_name {
    local project_name=$1
    while read _folder_name _pipy_name _pkg_name; do
            if [[ "${_pkg_name}" == "${project_name}" ]]; then
                echo "${_pipy_name}"
                return
            fi
    done < /opt/loci/scripts/python-custom-name-mapping.txt
    echo "$project_name"
}

function make_build_constraints {
    cp $UPPER_CONSTRAINTS $UPPER_CONSTRAINTS_DEV
    cp $UPPER_CONSTRAINTS $UPPER_CONSTRAINTS_BUILD
    pushd $SOURCES_DIR
    for repo in $(ls -1 $SOURCES_DIR); do
        if [[ ! -f $repo/setup.cfg ]]; then
            continue
        fi
        echo "Making build constraint for $repo"
        pkg_name=$(get_pkg_name $repo)
        pkg_version=$(get_pkg_version $repo)
        pipy_name=$(get_pipy_name_by_project_name $pkg_name)
        sed -i "s|^${pipy_name}===.*|file://${SOURCES_DIR}/${repo}#egg=${pkg_name}|g" $UPPER_CONSTRAINTS_BUILD
        sed -i "s|^${pipy_name}===.*|${pipy_name}===${pkg_version}|g" $UPPER_CONSTRAINTS_DEV
    done
    popd
}

# Setuptools from constraints is not compatible with other constrainted packages
[[ "${PROJECT_REF}" == "master" ]] && sed -i '/setuptools/d' /upper-constraints.txt

# NOTE(mnaser): confluent-kafka fails to build under aarch64 because the version
#               of libfdkafka-dev in the distributions is too old (x86_64 relies
#               on the wheel inside PyPI).
if [[ "$(uname -p)" == "aarch64" ]]; then
    sed -i '/confluent-kafka/d' /upper-constraints.txt
fi

# Ceilometer uses extras in requirements, which does not work for case when
# tooz is installed from local folder
# AssertionError: Internal issue: Candidate is not for this requirement tooz vs tooz[zake]
# Drop ceilometer from constraints.
sed -i '/ceilometer===.*/d' /upper-constraints.txt

# NOTE: This is to install python-openstackclient from the HEAD of the stable/2025.1 branch
#       This was merged after 7.4.0 which is pinned in the 2025.1 constraints.
#       https://review.opendev.org/c/openstack/python-openstackclient/+/944991
if [[ ${PROJECT_REF} == "stable/2025.1" ]]; then
    sed -i "s|^python-openstackclient===.*|git+https://opendev.org/openstack/python-openstackclient.git@stable/2025.1#egg=python-openstackclient|g" /upper-constraints.txt
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
  pip install ${PIP_ARGS} -c /global-requirements.txt -c /upper-constraints.txt --no-cache ${PIP_PACKAGES}
fi

export CASS_DRIVER_BUILD_CONCURRENCY=8
export UWSGI_PROFILE_OVERRIDE=ssl=true
export CPUCOUNT=1
# Make UPPER_CONSTRAINTS_BUILD visible in xargs -P
export UPPER_CONSTRAINTS_BUILD

# Construct upper-constraints with honor of locally downloaded projects
make_build_constraints
rm -rf $UPPER_CONSTRAINTS
mv $UPPER_CONSTRAINTS_DEV $UPPER_CONSTRAINTS

echo "DEBUG: ${UPPER_CONSTRAINTS_BUILD}"
cat ${UPPER_CONSTRAINTS_BUILD}

echo "DEBUG: ${UPPER_CONSTRAINTS}"
cat ${UPPER_CONSTRAINTS}

# Build all dependencies in parallel. This is safe because we are
# constrained on the version and we are building with --no-deps
echo uwsgi enum-compat ${PIP_PACKAGES} | xargs -n1 | split -l1 -a3
if [[ "$KEEP_ALL_WHEELS" == "False" ]]; then
  ls -1 | xargs -n1 -P20 -t bash -c 'set -x; pip wheel ${PIP_WHEEL_ARGS} --find-links /source-wheels --find-links / --no-deps --wheel-dir / -c /global-requirements.txt -c ${UPPER_CONSTRAINTS_BUILD} -r $1 || cat $1 >> /failure' _ | tee /tmp/wheels.txt
  # Remove native-binary wheels, we only want to keep wheels that we
  # compiled ourselves.
  awk -F'[ ,]+' '/^Skipping/ {gsub("-","_");print $2}' /tmp/wheels.txt | xargs -r -n1 bash -c 'ls /$1-*' _ | sort -u | xargs -t -r rm
  # Wheels built from unnamed constraints were removed with previous command. Move them back after deletion.
  [ ! -z "$(ls -A /source-wheels)" ] && mv /source-wheels/*.whl /
else
  ls -1 | xargs -n1 -P20 -t bash -c 'set -x; mkdir $1-wheels; pip wheel ${PIP_WHEEL_ARGS} --find-links /source-wheels --find-links / --wheel-dir /$(pwd)/$1-wheels -c /global-requirements.txt -c ${UPPER_CONSTRAINTS_BUILD}  -r $1 || cat $1 >> /failure' _
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
