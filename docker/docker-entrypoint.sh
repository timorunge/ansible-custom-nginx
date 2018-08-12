#!/bin/sh
set -e

printf '[defaults]\nroles_path=/etc/ansible/roles\ngather_timeout=60' > ansible.cfg
ansible-lint /etc/ansible/roles/${ENV_ROLE_NAME}/tasks/main.yml
ansible-playbook ${ENV_WORKDIR}/test.yml -i ${ENV_WORKDIR}/inventory --syntax-check
ansible-playbook ${ENV_WORKDIR}/test.yml -i ${ENV_WORKDIR}/inventory --connection=local --become $(test -z ${TRAVIS} && echo '-vvvv')
ansible-playbook ${ENV_WORKDIR}/test.yml -i ${ENV_WORKDIR}/inventory --connection=local --become | grep -q 'changed=0.*failed=0' && (echo 'Idempotence test: pass' && exit 0) || (echo 'Idempotence test: fail' && exit 1)
TMPFILE=$(mktemp /tmp/${ENV_ROLE_NAME}_XXXXXX)
/usr/local/nginx/sbin/nginx -v > ${TMPFILE} 2>&1
REAL_NGINX_VERSION=$(cat ${TMPFILE} | awk -F '/' '{print $2}')
rm ${TMPFILE}
EXPECTED_NGINX_VERSION=$(awk '/custom_nginx_version/{print $2}' ${ENV_WORKDIR}/test.yml)
test "${REAL_NGINX_VERSION}" = "${EXPECTED_NGINX_VERSION}" && (echo 'nginx version test: pass' && exit 0) || (echo 'nginx version test: fail' && exit 1)
curl -Iso /dev/null http://localhost:80 && (echo 'nginx response test: pass' && exit 0) || (echo 'nginx response test: fail' && exit 1)
