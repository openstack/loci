#!/bin/bash

set -ex

source $(dirname $0)/helpers.sh

export LC_CTYPE=C.UTF-8

configure_apt_sources "${APT_MIRROR}"

read -r -a extra_packages <<<"${DIST_PACKAGES}"
read -r -a bindep_packages <<<"$(get_bindep_system_packages "${PROJECT}" ${PROFILES})"
install_system_packages "${bindep_packages[@]}" "${extra_packages[@]}"

create_user "${GID}" "${UID}" "${PROJECT}"

for project_script in $(ls $(dirname $0)/project_specific/${PROJECT}); do
    echo "Running $PROJECT specific script $project_script"
    $(dirname $0)/project_specific/${PROJECT}/$project_script
done

revert_apt_sources
configure_packages
cleanup
