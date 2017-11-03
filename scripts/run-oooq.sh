#!/bin/bash

set -eux

TAGS=${TAGS:-"build,undercloud-setup,undercloud-scripts,undercloud-install,undercloud-post-install,tripleo-validations,overcloud-scripts,overcloud-prep-config,overcloud-prep-containers,overcloud-deploy,overcloud-upgrade,overcloud-validate"}
CONFIG=${CONFIG:-"tripleo-root/tripleo-quickstart/config/general_config/featureset004.yml"}
NODES=${NODES:-"tripleo-root/tripleo-quickstart/config/nodes/1ctlr.yml"}

cp ~/tripleo-root/tripleo-ci/toci-quickstart/config/testenv/osinfra_hosts ~/tripleo-root/workspace/.quickstart/hosts

set +e
~/tripleo-root/tripleo-quickstart/quickstart.sh \
    --bootstrap \
    --tags $TAGS \
    --no-clone \
    --working-dir ~/tripleo-root/workspace/.quickstart/ \
    --retain-inventory \
    --teardown none \
    --extra-vars tripleo_root=/home/$USER/tripleo-root \
    --extra-vars working_dir=/home/$USER \
    --extra-vars 'validation_args='\''--validation-errors-nonfatal'\''' \
    --release tripleo-ci/master \
    --nodes $NODES \
    --environment /home/$USER/tripleo-root/tripleo-ci/toci-quickstart/config/testenv/multinode.yml \
    --extra-vars @/home/$USER/tripleo-root/tripleo-quickstart/config/general_config/featureset-multinode-common.yml \
    --config $CONFIG \
    --extra-vars deploy_timeout=80 \
    --playbook multinode.yml \
    $@ \
    127.0.0.2

rc=$?
exit $rc
