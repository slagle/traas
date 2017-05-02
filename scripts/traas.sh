#!/bin/bash

set -eux

export TRIPLEO_ROOT=$HOME/tripleo-root
mkdir -p $TRIPLEO_ROOT

LOGFILE=$TRIPLEO_ROOT/traas.log
exec > >(tee -a $LOGFILE)
exec 2>&1

cd $TRIPLEO_ROOT

export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
export TOCI_JOBTYPE=${TOCI_JOBTYPE:-"multinode-nonha-oooq"}
export MTU=1400
export DO_SETUP_NODEPOOL_FILES=${DO_SETUP_NODEPOOL_FILES:-"1"}
export PRIMARY_NODE_IP=${PRIMARY_NODE_IP:-""}
export SUB_NODE_IPS=${SUB_NODE_IPS:-""}
export TOCI_JOBTYPE=${TOCI_JOBTYPE:-""}
export SSH_OPTIONS=${SSH_OPTIONS:-'-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=Verbose -o PasswordAuthentication=no -o ConnectionAttempts=32 -i ~/.ssh/id_rsa'}
export ZUUL_CHANGES=${ZUUL_CHANGES:-""}
export TRIPLEO_CI_REMOTE=${TRIPLEO_CI_REMOTE:-https://github.com/slagle/tripleo-ci}
export TRIPLEO_CI_BRANCH=${TRIPLEO_CI_BRANCH:-traas}
export EXTRA_VARS=${EXTRA_VARS:-""}
EXTRA_VARS="$EXTRA_VARS --extra-vars vxlan_mtu=1400"


function check_var {
    local var_name=$1
    eval local value=\$$var_name

    if [ -z "$value" ]; then
        echo "Variable $var_name is not defined"
        exit 1
    fi
}

check_var PRIMARY_NODE_IP
check_var TOCI_JOBTYPE

# Update openssh before the test builds are installed by tripleo-ci
# See https://review.openstack.org/#/c/437683/
sudo yum -y update openssh

rpm -q git || sudo yum -y install git

ZUUL_CHANGES=${ZUUL_CHANGES//^/ }

if [ ! -d tripleo-ci ]; then
    git clone -b $TRIPLEO_CI_BRANCH $TRIPLEO_CI_REMOTE
    pushd tripleo-ci

    for PROJFULLREF in $ZUUL_CHANGES ; do
        IFS=: change=($PROJFULLREF)
        project=${change[0]}
        branch=${change[1]}
        ref=${change[2]}
        if [ "$project" = "openstack-infra/tripleo-ci" ]; then
            IFS=: change=($PROJFULLREF)
            project=${change[0]}
            branch=${change[1]}
            ref=${change[2]}
            git fetch https://git.openstack.org/openstack-infra/tripleo-ci $ref && git checkout FETCH_HEAD
        fi
    done

    popd
fi

if [ ! -d tripleo-quickstart ]; then
    git clone https://git.openstack.org/openstack/tripleo-quickstart
fi

if [ ! -d tripleo-quickstart-extras ]; then
    git clone https://git.openstack.org/openstack/tripleo-quickstart-extras
fi

if [ "$DO_SETUP_NODEPOOL_FILES" = "1" ]; then
    $TRIPLEO_ROOT/tripleo-ci/scripts/tripleo.sh --setup-nodepool-files
fi

$TRIPLEO_ROOT/tripleo-ci/toci_gate_test.sh
