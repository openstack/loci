#!/bin/bash

set -ex

for file in /opt/loci/bindep*; do
    PACKAGES+=($(bindep -f $file -b -l newline ${PROJECT} ${PROFILES} ${distro_version} || :))
done

if [[ ! -z ${PACKAGES} ]]; then
    case ${distro} in
        ubuntu)
            apt-get install -y --no-install-recommends ${PACKAGES[@]} ${DIST_PACKAGES}

	    # NOTE: This doesn't belong here. This should be a user shim or a
	    #       custom base image configuration change to the apt sources
	    #       "libapache2-mod-oauth2" package is available in Ubuntu 22.10
            # NOTE(mnaser): mod_oauth2 is not available inside packaging repos, so we manually
            #               install it here.
	    if [[ "${PROFILES[*]}" =~ "mod_oauth2" ]] && [[ ${PROJECT} == 'keystone' ]] && [[ $(uname -p) == "x86_64" ]]; then
                source /etc/lsb-release
                apt-get install -y --no-install-recommends wget apache2
                wget --no-check-certificate \
		    https://github.com/zmartzone/mod_oauth2/releases/download/v3.2.2/libapache2-mod-oauth2_3.2.2-1.${DISTRIB_CODENAME}+1_amd64.deb \
		    https://github.com/zmartzone/liboauth2/releases/download/v1.4.3/liboauth2_1.4.3-1.${DISTRIB_CODENAME}+1_amd64.deb
                apt-get -y --no-install-recommends install \
		    ./libapache2-mod-oauth2_3.2.2-1.${DISTRIB_CODENAME}+1_amd64.deb \
		    ./liboauth2_1.4.3-1.${DISTRIB_CODENAME}+1_amd64.deb
                a2enmod oauth2
                rm -rfv \
		    ./libapache2-mod-oauth2_3.2.2-1.${DISTRIB_CODENAME}+1_amd64.deb \
		    ./liboauth2_1.4.3-1.${DISTRIB_CODENAME}+1_amd64.deb
                apt-get purge -y wget
            fi
            ;;
        centos)
            yum -y --setopt=skip_missing_names_on_install=False install ${PACKAGES[@]} ${DIST_PACKAGES}
            ;;
        *)
            echo "Unknown distro: ${distro}"
            exit 1
            ;;
    esac
fi
