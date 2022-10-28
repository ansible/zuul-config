#!/bin/bash
set -eux
qcow2_path=$1
image_name=$(basename -s .qcow2 ${qcow2_path})
property=""

function upload() {
    if [ $(openstack image list -c Name -f value | grep ${image_name}) ]; then
        return
    fi

    properties="--property hw_disk_bus=ide"
    if [[ ${image_name} == *"nexus9"* ]]; then
        properties="--property hw_vif_model=e1000 --property hw_disk_bus=sata --property hw_firmware_type=uefi"
    fi
    if [[ ${image_name} == *"c8000v-universalk9"* ]]; then
	# The appliance support virtio by default according to the documentation
	# https://www.cisco.com/c/en/us/td/docs/routers/C8000V/Configuration/c8000v-installation-configuration-guide.pdf
        properties=""
    fi

    openstack image create --progress --disk-format qcow2 --file ${image_name}.qcow2 ${properties} ${image_name}

}

OS_CLOUD=vexxhost OS_REGION_NAME=ca-ymq-1 upload
OS_CLOUD=vexxhost OS_REGION_NAME=ams1 upload
