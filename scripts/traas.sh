#!/bin/bash

set -eux

export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
export TRIPLEO_ROOT=$HOME/tripleo-root
export PRIMARY_NODE_IP=192.0.2.19
export SUB_NODE_IPS="192.0.2.20 192.0.2.18"
export TOCI_JOBTYPE="nonha"

mkdir -p $TRIPLEO_ROOT
cd $TRIPLEO_ROOT

sudo yum -y install git

if [ ! -d tripleo-ci ]; then
    git clone https://git.openstack.org/openstack-infra/tripleo-ci
fi

$TRIPLEO_ROOT/tripleo-ci/scripts/tripleo.sh --setup-nodepool-files

$TRIPLEO_ROOT/tripleo-ci/toci_instack_oooq_multinode.sh
