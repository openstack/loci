#!/bin/bash

set -eux

source $(dirname $0)/helpers.sh

setup_venv

configure_apt_sources "${APT_MIRROR}"

read -r -a bindep_packages <<<"$(get_bindep_system_packages requirements)"
install_system_packages "${bindep_packages[@]}"

clone_project requirements "${REQUIREMENTS_REPO}" "${REQUIREMENTS_REF}"
mv ${SOURCES_DIR}/requirements/{global-requirements.txt,upper-constraints.txt} /

revert_apt_sources
