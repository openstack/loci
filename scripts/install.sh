#!/bin/bash

set -ex

source /etc/lsb-release

export LC_CTYPE=C.UTF-8
# This overrides the base image configuration
echo 'APT::Get::AllowUnauthenticated "true";' > /etc/apt/apt.conf.d/99allow-unauthenticated
mv /etc/apt/sources.list /etc/apt/sources.list.bak
cat > /etc/apt/sources.list <<EOF
deb ${APT_MIRROR} ${DISTRIB_CODENAME} main universe
deb ${APT_MIRROR} ${DISTRIB_CODENAME}-updates main universe
deb ${APT_MIRROR} ${DISTRIB_CODENAME}-security main universe
deb ${APT_MIRROR} ${DISTRIB_CODENAME}-backports main universe
EOF
apt-get update
apt-get upgrade -y
apt-get install -y --no-install-recommends \
    git \
    netbase \
    patch \
    sudo \
    bind9-host \
    python3 \
    python3-venv
if [[ ! -z "$(apt-cache search ^python3-distutils$)" ]]; then
    apt-get install -y --no-install-recommends python3-distutils
fi
apt-get install -y --no-install-recommends \
    libpython3.$(python3 -c 'import sys; print(sys.version_info.minor);')

if [[ "${PROJECT}" == "requirements" ]]; then
    $(dirname $0)/requirements.sh
    exit 0
fi

if [ "${KEEP_ALL_WHEELS}" != "False" ]; then
    NO_INDEX=--no-index
fi

if [[ "${PLUGIN}" == "no" ]]; then
    $(dirname $0)/create_user.sh
    $(dirname $0)/setup_pip.sh
    $(dirname $0)/pip_install.sh bindep
    $(dirname $0)/install_packages.sh
    for file in /opt/loci/pydep*; do
        PYDEP_PACKAGES+=($(bindep -f $file -b -l newline ${PROJECT} ${PROJECT_RELEASE} ${PROFILES} || :))
    done
    $(dirname $0)/pip_install.sh ${PYDEP_PACKAGES[@]}
fi

$(dirname $0)/clone_project.sh
$(dirname $0)/install_packages.sh

extra_projects_path=""
for pr in $EXTRA_PROJECTS; do
    extra_projects_path="$extra_projects_path /tmp/${pr}"
done
project_cmd=/tmp/${PROJECT}
if [[ -n ${PROJECT_PIP_EXTRAS} ]]; then
    project_cmd="${project_cmd}[${PROJECT_PIP_EXTRAS}]"
fi

$(dirname $0)/pip_install.sh ${NO_INDEX} ${project_cmd} ${extra_projects_path} ${PIP_PACKAGES}
for project_script in $(ls $(dirname $0)/project_specific/${PROJECT}); do
    echo "Running $PROJECT specific script $project_script"
    $(dirname $0)/project_specific/${PROJECT}/$project_script
done
$(dirname $0)/configure_packages.sh
$(dirname $0)/collect_info.sh
$(dirname $0)/cleanup.sh
