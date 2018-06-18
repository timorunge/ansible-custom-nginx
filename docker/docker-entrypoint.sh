#!/bin/sh
set -e

echo $'[defaults]\nroles_path=/etc/ansible/roles' > ansible.cfg
ansible-lint /etc/ansible/roles/${ENV_ROLE_NAME}/tasks/main.yml
ansible-playbook test.yml -i inventory --syntax-check
ansible-playbook test.yml -i inventory --connection=local --become -vvvv
ansible-playbook test.yml -i inventory --connection=local --become | grep -q 'changed=0.*failed=0' && (echo 'Idempotence test: pass' && exit 0) || (echo 'Idempotence test: fail' && exit 1)
REAL_NGINX_VERSION=$(/usr/local/nginx/sbin/nginx -v 2>&1) | awk -F '/' '{print $2}'
EXPECTED_NGINX_VERSION=$(awk '/custom_nginx_version/{print $2}' ${ENV_WORKDIR}/test.yml)
test "${REAL_NGINX_VERSION} == ${EXPECTED_NGINX_VERSION}" && (echo 'nginx version test: pass' && exit 0) || (echo 'nginx version test: fail' && exit 1)
curl -Iso /dev/null http://localhost:80 && (echo 'nginx response test: pass' && exit 0) || (echo 'nginx response test: fail' && exit 1)
