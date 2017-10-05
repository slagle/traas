#!/bin/bash

set -eux

TAGS=${TAGS:-"overcloud-scripts,overcloud-deploy"}
CONFIG=${CONFIG:-"tripleo-root/tripleo-quickstart/config/general_config/featureset004.yml"}
NODES=${NODES:-"tripleo-root/tripleo-quickstart/config/nodes/1ctlr.yml"}

~/tripleo-root/tripleo-quickstart/quickstart.sh \
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
    127.0.0.2
