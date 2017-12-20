#!/bin/bash

set -eux

case ${distro} in
    debian|ubuntu)
        apt-get update
        apt-get upgrade -y
        apt-get install -y --no-install-recommends patch
        ;;
    centos)
        yum upgrade -y
        yum install -y --setopt=skip_missing_names_on_install=False patch
        ;;
    *)
        echo "Unknown distro: ${distro}"
        exit 1
        ;;
esac

$(dirname $0)/setup_pip.sh
pip install bindep==2.5.0
# NOTE(SamYaple): Remove when bindep>2.5.0 is released
patch /var/lib/openstack/lib/python*/site-packages/bindep/depends.py < /opt/loci/scripts/bindep.depends.patch
rm -f /var/lib/openstack/lib/python*/site-packages/bindep/depends.pyc

$(dirname $0)/install_packages.sh
$(dirname $0)/clone_project.sh
mv /tmp/requirements/{global-requirements.txt,upper-constraints.txt} /

# NOTE(SamYaple): https://issues.apache.org/jira/browse/PROTON-1381
# TODO(SamYaple): Make python-qpid-proton build here (possibly patch it)
if (( $(openssl version | awk -F'[ .]' '{print $3}') >= 1 )); then
    sed -i '/python-qpid-proton/d' /upper-constraints.txt
fi

if [[ "${PYTHON3}" == "no" ]]; then
    ignore_wheels=py2
else
    ignore_wheels=py3
fi

pushd $(mktemp -d)

# NOTE(SamYaple): Build all deps in parallel. This is safe because we are
# constrained on the version and we are building with --no-deps
export CASS_DRIVER_BUILD_CONCURRENCY=8
split -l1 /upper-constraints.txt
echo uwsgi ${PIP_PACKAGES} | xargs -n1 | split -l1 -a3
ls -1 | xargs -n1 -P20 -t bash -c 'pip wheel --no-deps --wheel-dir / -c /upper-constraints.txt -r $1 || echo %1 >> /failure' _ | tee /tmp/wheels.txt

# TODO(SamYaple): Improve the failure catching
if [[ -f /failure ]]; then
    echo Wheel failed to build
    cat /failure
    exit 1
fi

# NOTE(SamYaple) Remove native-binary wheels, we only want to keep wheels that
# we compiled ourselves.
awk -F'[ ,]+' '/^Skipping/ {gsub("-","_");print $2}' /tmp/wheels.txt | xargs -r -n1 bash -c 'ls /$1-*' _ | sort -u | xargs -t -r rm

# NOTE(SamYaple): We want to purge all files that are not wheels or txt to
# reduce the size of the layer to only what is needed
shopt -s extglob
rm -rf /!(*whl|*txt) > /dev/null 2>&1 || :
