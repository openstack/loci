#!/bin/bash

set -ex

source $(dirname $0)/helpers.sh

export LC_CTYPE=C.UTF-8

setup_venv

read -r -a extra_packages <<<"${DIST_PACKAGES}"
read -r -a bindep_packages <<<"$(get_bindep_system_packages "${PROJECT}" ${PROFILES})"
install_system_packages "${bindep_packages[@]}" "${extra_packages[@]}"

if [[ "${PLUGIN}" == "no" ]]; then
    create_user "${GID}" "${UID}" "${PROJECT}"
fi

for file in /opt/loci/pydep*; do
    PYDEP_PACKAGES+=($(bindep -f $file -b -l newline ${PROJECT} ${PROJECT_RELEASE} ${PROFILES} || :))
done
pip install --no-cache-dir --only-binary :all: --no-compile \
    -c ${WHEELS_PATH}/global-requirements.txt -c ${WHEELS_PATH}/upper-constraints.txt \
    --find-links ${WHEELS_PATH} --ignore-installed \
    ${PIP_ARGS} \
    ${PYDEP_PACKAGES[@]}

clone_project "${PROJECT}" "${PROJECT_REPO}" "${PROJECT_REF}"

extra_projects_path=""
for pr in $EXTRA_PROJECTS; do
    extra_projects_path="$extra_projects_path /tmp/${pr}"
done

project_cmd=${SOURCES_DIR}/${PROJECT}
if [[ -n ${PROJECT_PIP_EXTRAS} ]]; then
    project_cmd="${project_cmd}[${PROJECT_PIP_EXTRAS}]"
fi

# Presence of constraint for project we build
# in upper constraints breaks project installation
# with unsatisfied constraints error.
# This line ensures that such constraint is absent.
cp ${WHEELS_PATH}/upper-constraints.txt /tmp/upper-constraints.txt
sed -i "/^${PROJECT}===/d" /tmp/upper-constraints.txt

if [[ "${KEEP_ALL_WHEELS}" != "False" ]]; then
    # The requirements image contains not only those wheels
    # that we built from upper-constraints.txt but also all wheels
    # that were pulled as dependencies during that build.
    # We can use them as source for dependencies.
    NO_INDEX="--no-index"
fi

pip install --no-cache-dir --only-binary :all: --no-compile \
    -c ${WHEELS_PATH}/global-requirements.txt -c /tmp/upper-constraints.txt \
    --find-links ${WHEELS_PATH} --ignore-installed \
    ${NO_INDEX} ${PIP_ARGS} \
    ${project_cmd} ${extra_projects_path} ${PIP_PACKAGES}

for project_script in $(ls $(dirname $0)/project_specific/${PROJECT}); do
    echo "Running $PROJECT specific script $project_script"
    $(dirname $0)/project_specific/${PROJECT}/$project_script
done

configure_packages
collect_info
cleanup
