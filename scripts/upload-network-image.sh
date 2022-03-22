#!/bin/bash
set -eux
qcow2_path=$1
image_name=$(basename -s .qcow2 ${qcow2_path})
property=""

function upload() {
    if [ $(openstack image list -c Name -f value | grep ${image_name}) ]; then
        return
    fi
    if [ ! -f ${image_name}.raw ]; then
        qemu-img convert -f qcow2 -O raw $qcow2_path ${image_name}.raw
    fi
    sha512sum $qcow2_path ${image_name}.raw
    openstack image create --disk-format raw --file ${image_name}.raw --property hw_disk_bus=ide ${property} ${image_name}
}

OS_CLOUD=limestone OS_REGION_NAME=us-slc upload
OS_CLOUD=limestone OS_REGION_NAME=us-dfw-1 upload
OS_CLOUD=vexxhost OS_REGION_NAME=ca-ymq-1 upload
OS_CLOUD=vexxhost OS_REGION_NAME=sjc1 upload
OS_CLOUD=vexxhost OS_REGION_NAME=ams1 upload

rm ${image_name}.raw
