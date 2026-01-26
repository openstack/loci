#!/bin/bash

# Common helper functions shared by build scripts.

get_bindep_system_packages() {
    # Resolve bindep packages for a project/profile set.
    # Args:
    #   $1: project name
    #   $2...: PROFILES list (space-separated)
    source /etc/lsb-release

    local project="$1"
    shift
    local profiles=("$@")

    local packages=()
    for file in /opt/loci/bindep*; do
        packages+=($(bindep -f "$file" -b -l newline "${project}" "${profiles[@]}" "${DISTRIB_CODENAME}" || :))
    done

    echo "${packages[@]}"
}

install_system_packages() {
    # Install distribution packages provided as arguments.
    # Args:
    #   $@ packages to install
    local packages=("$@")
    export DEBIAN_FRONTEND=noninteractive
    if [[ ${#packages[@]} -gt 0 ]]; then
        apt-get update && \
        apt-get install -y --no-install-recommends "${packages[@]}"
    fi
}

get_pkg_name() {
    local folder=$1
    local name
    pushd "$folder" > /dev/null
    name=$(python3 setup.py --name 2>/dev/null | grep -v '^\[pbr\]')
    popd > /dev/null
    echo "$name"
}

get_pkg_version() {
    local folder=$1
    local version
    pushd "$folder" > /dev/null
    version=$(python3 setup.py --version 2>/dev/null | grep -v '^\[pbr\]')
    popd > /dev/null
    echo "$version"
}

get_pipy_name_by_project_name() {
    local project_name=$1
    while read _folder_name _pipy_name _pkg_name; do
        if [[ "${_pkg_name}" == "${project_name}" ]]; then
            echo "${_pipy_name}"
            return
        fi
    done < /opt/loci/scripts/python-custom-name-mapping.txt
    echo "$project_name"
}

configure_apt_sources() {
    # Configure apt sources for Ubuntu based on the release version.
    # Args:
    #   $1: apt mirror_host
    local apt_mirror_host="${1}"
    if [[ -z "${apt_mirror_host}" ]]; then
        return
    fi
    local driver=${2:-https}

    source /etc/os-release
    local ver=${VERSION_ID/./}
    local codename="${VERSION_CODENAME}"
    local arch="${TARGETARCH:-}"

    if [[ -z "${arch}" ]]; then
        arch="$(dpkg --print-architecture 2>/dev/null || true)"
    fi

    local trusted_prefix=""
    local trusted_flag=""
    if [[ -n "${apt_mirror_host}" ]]; then
        trusted_prefix="[trusted=yes] "
        trusted_flag="yes"
    fi

    case "${arch}" in
    "arm64"|"aarch64")
        apt_mirror="${driver}://${apt_mirror_host:-ports.ubuntu.com}/ubuntu-ports/"
        ;;
    "amd64"|"x86_64")
        apt_mirror="${driver}://${apt_mirror_host:-archive.ubuntu.com}/ubuntu/"
        ;;
    *)
        echo "Unsupported architecture: ${arch}"
        exit 1
        ;;
    esac

    if [ "$ver" -ge "2404" ]; then  # Ubuntu 24.04 and newer
        mkdir -p /etc/apt/sources.list.d
        if [[ -f /etc/apt/sources.list.d/ubuntu.sources && ! -f /etc/apt/sources.list.d/ubuntu.sources.orig ]]; then
            mv /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.orig
        fi
        cat > /etc/apt/sources.list.d/ubuntu.sources <<EOF
Types: deb
URIs: ${apt_mirror}
Suites: ${codename} ${codename}-updates ${codename}-backports ${codename}-security
Components: main universe
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
        if [[ -n "${trusted_flag}" ]]; then
            echo "Trusted: ${trusted_flag}" >> /etc/apt/sources.list.d/ubuntu.sources
        fi
        cat /etc/apt/sources.list.d/ubuntu.sources
    else
        if [[ -f /etc/apt/sources.list.d/ubuntu.sources && ! -f /etc/apt/sources.list.d/ubuntu.sources.orig ]]; then
            mv /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.orig
        fi
        if [[ -f /etc/apt/sources.list && ! -f /etc/apt/sources.list.orig ]]; then
            mv /etc/apt/sources.list /etc/apt/sources.list.orig
        fi
        cat > /etc/apt/sources.list <<EOF
deb ${trusted_prefix}${apt_mirror} ${codename} main universe
deb ${trusted_prefix}${apt_mirror} ${codename}-updates main universe
deb ${trusted_prefix}${apt_mirror} ${codename}-security main universe
deb ${trusted_prefix}${apt_mirror} ${codename}-backports main universe
EOF
        cat /etc/apt/sources.list
    fi
}

revert_apt_sources() {
    # Restore original apt sources files if backups exist.
    if [[ -f /etc/apt/sources.list.d/ubuntu.sources.orig ]]; then
        mv /etc/apt/sources.list.d/ubuntu.sources{.orig,}
    fi
    if [[ -f /etc/apt/sources.list.orig ]]; then
        mv /etc/apt/sources.list{.orig,}
    fi
}

cleanup() {
    apt-get update
    apt-get purge -y --auto-remove \
        git \
        patch \
        python3-virtualenv \
        virtualenv || true

    rm -rf /var/lib/apt/lists/*

    # Allow python to use system site packages when missing from the venv
    sed -i 's/\(include-system-site-packages\).*/\1 = true/g' /var/lib/openstack/pyvenv.cfg
    rm -rf /tmp/* /root/.cache/pip /etc/machine-id
    find /usr/ /var/ \( -name "*.pyc" -o -name "__pycache__" \) -delete
    # Remove sources added to image
    rm -rf /opt/loci/*
}

collect_info() {
    # Gather pip and project metadata into INFO_DIR.
    local INFO_DIR="/etc/image_info"
    mkdir -p "${INFO_DIR}"
    local pip_info="${INFO_DIR}/pip.txt"
    local project_info="${INFO_DIR}/project.txt"

    pip freeze > "${pip_info}"

    cat > "${project_info}" <<EOF
PROJECT=${PROJECT}
PROJECT_REPO=${PROJECT_REPO}
PROJECT_REF=${PROJECT_REF}
PROJECT_RELEASE=${PROJECT_RELEASE}
EOF
    pushd "${SOURCES_DIR}/${PROJECT}"
    echo "========"
    git log -1 >> "${project_info}"
    popd
}

configure_packages() {
    # Optionally copy default config files from venv/etc into /etc/PROJECT.
    local copy_default_config_files="${1:-${COPY_DEFAULT_CONFIG_FILES:-no}}"
    if [[ "${copy_default_config_files}" == "yes" ]]; then
        mkdir -p "/etc/${PROJECT}/"
        cp -r "/var/lib/openstack/etc/${PROJECT}"/* "/etc/${PROJECT}/" || true
    fi
}

clone_project() {
    # Clone the project defined by provided parameters into /tmp and checkout the ref.
    # Args:
    #   $1: project name
    #   $2: project repo
    #   $3: project ref
    local project_name="$1"
    local project_repo="$2"
    local project_ref="$3"

    if [[ ! -d "${SOURCES_DIR}/${project_name}" ]]; then
        git clone "${project_repo}" "${SOURCES_DIR}/${project_name}"
        pushd "${SOURCES_DIR}/${project_name}"
        git fetch "${project_repo}" "${project_ref}"
        git checkout FETCH_HEAD
        popd
    fi
}

create_user() {
    # Create the system user/group for the project.
    # Args:
    #   $1: GID
    #   $2: UID
    #   $3: PROJECT name
    local gid="$1"
    local uid="$2"
    local project="$3"

    groupadd -g "${gid}" "${project}"
    if [[ "${project}" == "nova" ]]; then
        # NOTE: bash needed for nova to support instance migration
        useradd -u "${uid}" -g "${project}" -M -d "/var/lib/${project}" -s /bin/rbash -c "${project} user" "${project}"
    else
        useradd -u "${uid}" -g "${project}" -M -d "/var/lib/${project}" -s /usr/sbin/nologin -c "${project} user" "${project}"
    fi

    mkdir -p "/etc/${project}" "/var/log/${project}" "/var/lib/${project}" "/var/cache/${project}"
    chown "${project}:${project}" "/etc/${project}" "/var/log/${project}" "/var/lib/${project}" "/var/cache/${project}"
}

setup_venv() {
    # Create and prime a virtualenv with optional toolchain constraints.
    # Uses PIP_VERSION_CONSTRAINT, SETUPTOOL_CONSTRAINT, WHEEL_CONSTRAINT if set.
    local venv_path="${1:-/var/lib/openstack}"

    python3 -m venv "${venv_path}"
    # shellcheck source=/dev/null
    source "${venv_path}/bin/activate"

    pip install --upgrade "pip${PIP_VERSION_CONSTRAINT}"
    pip install --upgrade "setuptools${SETUPTOOL_CONSTRAINT}"
    pip install --upgrade "wheel${WHEEL_CONSTRAINT}"
    pip install --upgrade bindep pkginfo uv
}

honor_local_sources() {
    # Update constraints to prefer local checkouts in SOURCES_DIR.
    # List of packages to be built will be placed in UPPER_CONSTRAINTS_BUILD.
    # Args:
    #   $1: sources dir
    #   $2: UPPER_CONSTRAINTS path
    #   $3: UPPER_CONSTRAINTS_BUILD path
    local sources_dir="$1"
    local constraints="$2"
    local constraints_build="$3"
    local constraints_tmp="${constraints}.tmp"

    cp "${constraints}" "${constraints_tmp}"
    cp "${constraints}" "${constraints_build}"
    pushd "${sources_dir}"
    for repo in $(ls -1 "${sources_dir}"); do
        if [[ ! -f "${repo}/setup.cfg" ]]; then
            continue
        fi
        echo "Making build constraint for ${repo}"
        pkg_name=$(get_pkg_name "${repo}")
        pkg_version=$(get_pkg_version "${repo}")
        pipy_name=$(get_pipy_name_by_project_name "${pkg_name}")
        sed -i "s|^${pipy_name}===.*|file://${sources_dir}/${repo}#egg=${pkg_name}|g" "${constraints_build}"
        sed -i "s|^${pipy_name}===.*|${pipy_name}===${pkg_version}|g" "${constraints_tmp}"
    done
    popd
    mv "${constraints_tmp}" "${constraints}"
}
