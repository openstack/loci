#!/bin/bash

set -ex

HORIZON_EXTRA_PANELS="${HORIZON_EXTRA_PANELS:-heat_dashboard octavia_dashboard designatedashboard tf_dashboard bgpvpn_dashboard masakaridashboard manila_ui neutron_vpnaas_dashboard watcher_dashboard}"
SITE_PACKAGES_ROOT=$(python -c "from sysconfig import get_path; print(get_path('purelib'))")
DASHBOARD_ROOT=/usr/local/share/openstack_dashboard
MANAGE_CMD="${SITE_PACKAGES_ROOT}/openstack_dashboard/manage.py"
LOCAL_SETTINGS="${SITE_PACKAGES_ROOT}/openstack_dashboard/local/local_settings.py"

cp /tmp/${PROJECT}/manage.py ${SITE_PACKAGES_ROOT}/openstack_dashboard/

# wsgi/horizon-http needs open files here, including secret_key_store
chown -R horizon ${SITE_PACKAGES_ROOT}/openstack_dashboard/local/

for panel_ in ${HORIZON_EXTRA_PANELS}; do
    for enabled_dir in enabled local/enabled; do
      PANEL_DIR="${SITE_PACKAGES_ROOT}/${panel_}/${enabled_dir}"
      if [[ -d ${PANEL_DIR} ]]; then
          for panel in $(ls -1 ${PANEL_DIR}/_[1-9]*.py); do
              ln -s ${panel} ${SITE_PACKAGES_ROOT}/openstack_dashboard/local/enabled/$(basename ${panel})
          done
          break
      fi
    done

    PANEL_DIR="${SITE_PACKAGES_ROOT}/${panel_}/local/local_settings.d"
    if [[ -d ${PANEL_DIR} ]]; then
        for panel in $(ls -1 ${PANEL_DIR}/*); do
            ln -s ${panel} ${SITE_PACKAGES_ROOT}/openstack_dashboard/local/local_settings.d/$(basename ${panel})
        done
    fi

    CONF_DIR="${SITE_PACKAGES_ROOT}/${panel_}/conf"
    if [[ -d ${CONF_DIR} ]]; then
        for policy in $(find $CONF_DIR -maxdepth 1 -iname '*.json' -o -iname '*.yaml'); do
            ln -s ${policy} ${SITE_PACKAGES_ROOT}/openstack_dashboard/conf/$(basename ${policy})
        done
        if [[ -d ${CONF_DIR}/default_policies ]]; then
            mkdir -p ${SITE_PACKAGES_ROOT}/openstack_dashboard/conf/default_policies
            for default_policy in $(find ${CONF_DIR}/default_policies -maxdepth 1 -iname '*.json' -o -iname '*.yaml'); do
                ln -s ${default_policy} ${SITE_PACKAGES_ROOT}/openstack_dashboard/conf/default_policies/$(basename ${default_policy})
            done
        fi
    fi
done

mkdir /etc/openstack-dashboard
ln -s ${SITE_PACKAGES_ROOT}/openstack_dashboard/conf/default_policies /etc/openstack-dashboard/default_policies

cp ${SITE_PACKAGES_ROOT}/openstack_dashboard/local/local_settings.py.example ${LOCAL_SETTINGS}
echo "COMPRESS_OFFLINE = True" >> ${LOCAL_SETTINGS}
echo "STATIC_ROOT = '/var/www/html/horizon'" >> ${LOCAL_SETTINGS}

if type -p gettext >/dev/null 2>/dev/null; then
   cd ${SITE_PACKAGES_ROOT}/openstack_dashboard; "${MANAGE_CMD}" compilemessages
fi

# Compress Horizon's assets.
"${MANAGE_CMD}" collectstatic --clear --noinput
"${MANAGE_CMD}" compress --force

# make a static path so to not depend on the python version
ln -s ${SITE_PACKAGES_ROOT}/openstack_dashboard ${DASHBOARD_ROOT}

rm -rf ${DASHBOARD_ROOT}/local/.secret_key_store
for lock in ${DASHBOARD_ROOT}/local/*.lock; do
    rm -f ${lock}
done
