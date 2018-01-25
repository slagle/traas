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
export NODEPOOL_REGION=${NODEPOOL_REGION:-dfw}
export NODEPOOL_CLOUD=${NODEPOOL_CLOUD:-rax}
export PRIMARY_NODE_IP=${PRIMARY_NODE_IP:-""}
export SUB_NODE_IPS=${SUB_NODE_IPS:-""}
export TOCI_JOBTYPE=${TOCI_JOBTYPE:-""}
export SSH_OPTIONS=${SSH_OPTIONS:-'-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=Verbose -o PasswordAuthentication=no -o ConnectionAttempts=32 -i ~/.ssh/id_rsa'}
export ZUUL_CHANGES=${ZUUL_CHANGES:-""}
export ZUUL_BRANCH=${ZUUL_BRANCH:-""}
export TRIPLEO_CI_REMOTE=${TRIPLEO_CI_REMOTE:-https://github.com/slagle/tripleo-ci}
export TRIPLEO_CI_BRANCH=${TRIPLEO_CI_BRANCH:-traas}
export EXTRA_VARS=${EXTRA_VARS:-""}
export STABLE_RELEASE=${STABLE_RELEASE:-"master"}

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
sudo yum -y install patch wget
rpm -q git || sudo yum -y install git
rpm -q python-virtualenv || sudo yum -y install python-virtualenv

mkdir workspace
virtualenv workspace/.quickstart
set +u
source workspace/.quickstart/bin/activate
set -u
pip install pip --upgrade

CI_REFS=${CI_CHANGES//^/ }
ZUUL_REFS=${ZUUL_CHANGES//^/ }


if [ ! -d tripleo-ci ]; then
    git clone -b $TRIPLEO_CI_BRANCH $TRIPLEO_CI_REMOTE
fi

if [ ! -d tripleo-quickstart ]; then
    git clone https://git.openstack.org/openstack/tripleo-quickstart
fi

if [ ! -d tripleo-quickstart-extras ]; then
    git clone https://git.openstack.org/openstack/tripleo-quickstart-extras
fi

for PROJFULLREF in $CI_REFS ; do
    OLDIFS=$IFS
    IFS=: change=($PROJFULLREF)
    IFS=$OLDIFS
    echo ${change[*]}
    project=${change[0]}
    change=${change[1]}
    if [[ $project =~ openstack-infra/tripleo-ci|openstack/tripleo-quickstart|openstack/tripleo-quickstart-extras ]]; then
        curl https://review.openstack.org/changes/${change}/revisions/current/patch?download | \
            base64 -d | \
            sudo patch -f -d ./${project##*/} -p1
    else
        echo "Not proper repo, ci_changes must be used exclusively for:"
        echo " - tripleo-quickstart"
        echo " - tripleo-quickstart-extra"
        echo " - tripleo-ci"
        exit 1
    fi
done

pushd tripleo-quickstart-extras
pip install .
popd

if [ "$DO_SETUP_NODEPOOL_FILES" = "1" ]; then
    $TRIPLEO_ROOT/tripleo-ci/scripts/tripleo.sh --setup-nodepool-files
fi

set +u
deactivate
set -u

$TRIPLEO_ROOT/tripleo-ci/toci_gate_test.sh
