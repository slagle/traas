#!/usr/bin/bash

set -eux

. /etc/profile.d/traas.sh
set +u
. ~/tripleo-root/workspace/.quickstart/bin/activate
set -u
eval $(egrep -o 'export (OPT|SSH_CONFIG|ANSIBLE_CONFIG|ANSIBLE_INVENTORY|ANSIBLE_SSH_ARGS|ARA_DATABASE)[^ ]*' ~/tripleo-root/traas.log | \
           xargs -0)
CMD=$(egrep -o '/usr/bin/timeout --preserve-status.*( /home/.*/ansible-playbook.*)' ~/tripleo-root/traas.log | \
          cut -d' ' -f4- )

sudo yum remove -y openstack-tripleo-heat-templates
sudo yum -y --disablerepo="gating-repo" install python-tripleoclient instack-undercloud
env | sort > ~/traas-$$.log
nohup $CMD >> ~/traas-$$.log &
