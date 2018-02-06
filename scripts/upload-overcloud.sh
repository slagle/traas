#!/usr/bin/bash

set -eux

delete_existing_image()
{
    local name="${1}"
    if openstack image show $name -f value -c id | read id; then
        echo "Deleting ${name} ($id)"
        openstack image delete $id
    fi

}
# Usually more space there.
export TMPDIR=${TMPDIR:-/var/tmp}

OVERCLOUD_TAR_URL=${1?:'Please provide the overcloud tar url'}
OVERCLOUD_NAME=${2?:'Please provide the overcloud name prefix in glance'}

OVERCLOUD_TAR_NAME="$(basename ${OVERCLOUD_TAR_URL})"
TMP_DIR=$(mktemp -d)

curl -o ${TMP_DIR}/${OVERCLOUD_TAR_NAME} ${OVERCLOUD_TAR_URL}
(
    cd ${TMP_DIR}
    tar xf ${OVERCLOUD_TAR_NAME}

    echo "Handling overcloud-full.initrd"
    delete_existing_image ${OVERCLOUD_NAME}.initrd
    RAMDISK_ID=$(
        openstack image create \
                  --disk-format ari --container-format ari \
                  -f value -c id \
                  --file ./overcloud-full.initrd ${OVERCLOUD_NAME}.initrd
              )

    openstack image show $RAMDISK_ID
    echo "Handling overcloud-full.vmlinuz"
    delete_existing_image ${OVERCLOUD_NAME}.vmlinuz
    KERNEL_ID=$(
        openstack image create \
                  --disk-format aki --container-format aki \
                  -f value -c id \
                  --file ./overcloud-full.vmlinuz ${OVERCLOUD_NAME}.vmlinuz
           )

    openstack image show $KERNEL_ID
    echo "Handling overcloud-full.qcow2, maybe very long depending on your upload speed."
    delete_existing_image ${OVERCLOUD_NAME}
    OVERCLOUD_ID=$(openstack image create \
              --disk-format qcow2 --container-format bare \
              --file ./overcloud-full.qcow2 \
              -f value -c id \
              --property kernel_id=${KERNEL_ID} --property ramdisk_id=${RAMDISK_ID} \
              ${OVERCLOUD_NAME})

    openstack image show $OVERCLOUD_ID

    openstack image list

    echo "DONE"

)
