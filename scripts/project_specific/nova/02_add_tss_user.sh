#!/bin/bash
# When using emulated TPM, the user/group that swtpm binary runs as.
set -ex

groupadd -g ${NOVA_TSS_GID} ${NOVA_TSS_USER}
useradd -u ${NOVA_TSS_UID} -g ${NOVA_TSS_USER} -s /usr/sbin/nologin -c "${NOVA_TSS_USER} user" ${NOVA_TSS_USER}
