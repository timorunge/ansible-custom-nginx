#!/bin/sh
set -e

printf "[defaults]\nroles_path=/etc/ansible/roles\n" > /ansible/ansible.cfg

if [ ! -f /etc/ansible/lint.zip ]; then
  wget https://github.com/ansible/galaxy-lint-rules/archive/master.zip -O \
  /etc/ansible/lint.zip
  unzip /etc/ansible/lint.zip -d /etc/ansible/lint
fi

ansible-lint -c /etc/ansible/roles/${ansible_role}/.ansible-lint -r \
  /etc/ansible/lint/galaxy-lint-rules-master/rules \
  /etc/ansible/roles/${ansible_role}
ansible-lint -c /etc/ansible/roles/${ansible_role}/.ansible-lint -r \
  /etc/ansible/lint/galaxy-lint-rules-master/rules \
  /ansible/test.yml

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
  --become \
  -e "{ custom_nginx_version: ${custom_nginx_version} }" | \
  grep -q "changed=0.*failed=0" && \
  (echo "Idempotence test: pass" && exit 0) || \
  (echo "Idempotence test: fail" && exit 1)

tmpfile=$(mktemp /tmp/${ansible_role}_XXXXXX)
/usr/local/nginx/sbin/nginx -v > ${tmpfile} 2>&1
real_nginx_version=$(cat ${tmpfile} | awk -F "/" '{print $2}')
rm ${tmpfile}
test "${real_nginx_version}" = "${custom_nginx_version}" && \
  (echo "nginx version test: pass" && exit 0) || \
  (echo "nginx version test: fail" && exit 1)

curl -Iso /dev/null http://localhost:80 && \
  (echo "nginx response test: pass" && exit 0) || \
  (echo "nginx response test: fail" && exit 1)
