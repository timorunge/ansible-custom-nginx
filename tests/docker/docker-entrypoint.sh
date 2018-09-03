#!/bin/sh
set -e

printf '[defaults]\nroles_path=/etc/ansible/roles' > ansible.cfg

ansible-lint /ansible/test.yml
ansible-lint /etc/ansible/roles/${ansible_role}/tasks/main.yml

ansible-playbook /ansible/test.yml \
  -i /ansible/inventory \
  --syntax-check \
  -e "{ custom_nginx_version: ${custom_nginx_version} }"

ansible-playbook /ansible/test.yml \
  -i /ansible/inventory \
  --connection=local \
  --become \
  -e "{ custom_nginx_version: ${custom_nginx_version} }" \
  $(test -z ${travis} && echo "-vvvv")

ansible-playbook /ansible/test.yml \
  -i /ansible/inventory \
  --connection=local \
  --become | \
  -e "{ custom_nginx_version: ${custom_nginx_version} }" \
  grep -q 'changed=0.*failed=0' && \
  (echo 'Idempotence test: pass' && exit 0) || \
  (echo 'Idempotence test: fail' && exit 1)

tmpfile=$(mktemp /tmp/${ansible_role}_XXXXXX)
/usr/local/nginx/sbin/nginx -v > ${tmpfile} 2>&1
real_nginx_version=$(cat ${tmpfile} | awk -F '/' '{print $2}')
rm ${tmpfile}
test "${real_nginx_version}" = "${custom_nginx_version}" && \
  (echo 'nginx version test: pass' && exit 0) || /
  (echo 'nginx version test: fail' && exit 1)

curl -Iso /dev/null http://localhost:80 && \
  (echo 'nginx response test: pass' && exit 0) || \
  (echo 'nginx response test: fail' && exit 1)
