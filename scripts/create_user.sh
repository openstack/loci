#!/bin/bash

set -ex

groupadd -g ${GID} ${PROJECT}
if [[ "${PROJECT}" == "nova" ]];then
    # NOTE: bash needed for nova to support instance migration
    useradd -u ${UID} -g ${PROJECT} -M -d /var/lib/${PROJECT} -s /bin/bash -c "${PROJECT} user" ${PROJECT}
else
    useradd -u ${UID} -g ${PROJECT} -M -d /var/lib/${PROJECT} -s /usr/sbin/nologin -c "${PROJECT} user" ${PROJECT}
fi

mkdir -p /etc/${PROJECT} /var/log/${PROJECT} /var/lib/${PROJECT} /var/cache/${PROJECT}
chown ${PROJECT}:${PROJECT} /etc/${PROJECT} /var/log/${PROJECT} /var/lib/${PROJECT} /var/cache/${PROJECT}
