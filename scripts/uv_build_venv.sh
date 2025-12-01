#!/bin/bash

set -ex

source $(dirname $0)/helpers.sh

export LC_CTYPE=C.UTF-8
export CASS_DRIVER_BUILD_CONCURRENCY=8
export UWSGI_PROFILE_OVERRIDE=ssl=true
export CPUCOUNT=1

for file in /opt/loci/pydep*; do
    PYDEP_PACKAGES+=($(bindep -f $file -b -l newline ${PROJECT} ${PROJECT_RELEASE} ${PROFILES} || :))
done
uv pip install -c /global-requirements.txt -c /upper-constraints.txt \
    ${UV_PIP_ARGS} \
    ${PYDEP_PACKAGES[@]}

clone_project "${PROJECT}" "${PROJECT_REPO}" "${PROJECT_REF}"

extra_projects_path=""
for pr in $EXTRA_PROJECTS; do
    extra_projects_path="$extra_projects_path /tmp/${pr}"
done

project_cmd=/tmp/${PROJECT}
if [[ -n ${PROJECT_PIP_EXTRAS} ]]; then
    project_cmd="${project_cmd}[${PROJECT_PIP_EXTRAS}]"
fi

# Presence of constraint for project we build
# in upper constraints breaks project installation
# with unsatisfied constraints error.
# This line ensures that such constraint is absent.
sed -i "/^${PROJECT}===/d" /upper-constraints.txt

uv pip install -c /global-requirements.txt -c /upper-constraints.txt \
    ${UV_PIP_ARGS} \
    ${project_cmd} ${extra_projects_path} ${PIP_PACKAGES}

collect_info
