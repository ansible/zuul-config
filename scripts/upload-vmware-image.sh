#!/bin/bash
set -eux
qcow2_image=$1
if [ -f  ${qcow2_image} ]; then
    final_name=$(basename -s .qcow2 ${qcow2_image})
    image_name=$(basename -s .qcow2 ${qcow2_image}-$(sha256sum ${qcow2_image}|cut -d' ' -f1))
    local_copy=${qcow2_image}
else
    last_modified=$(curl -s --fail --head https://s3.us-east-2.amazonaws.com/ansible-team-cloud-images/${qcow2_image}|awk '/^Last-Modified:/ {print $2" "$3" "$4" "$5" "$6}')
    timestamp=$(date -d "${last_modified}" +%Y%m%d)
    final_name=$(basename -s .qcow2 ${qcow2_image})
    image_name=$(basename -s .qcow2 ${qcow2_image})-${timestamp}
    local_copy=~/tmp/${image_name}.qcow2
    curl -L -o ${local_copy} https://s3.us-east-2.amazonaws.com/ansible-team-cloud-images/$qcow2_image
fi

function upload() {
    if [ $(openstack image list --tag ${image_name} -c Name -f value | grep ${final_name}) ]; then
        return
    fi

    property=""
    if [[ ${image_name} == *"VMware-VCSA-all"* ]]; then
        if [[ ${image_name} == *"6.7.0"* ]]; then
            property="--property hw_vif_model=e1000" 
        fi
    fi
    if [[ ${image_name} == *"esxi"* ]]; then
        hw_disk_bus="sata"
        if [[ ${image_name} == *"6.7.0"* ]]; then
            driver="e1000"
        else
            driver="e1000e"
        fi
        if [[ ${OS_CLOUD} == "limestone" ]]; then
            hw_disk_bus="ide"
        fi
    
        property="--property hw_disk_bus=sata --property hw_cpu_policy=dedicated --property img_config_drive=mandatory --property hw_cdrom_bus=ide --property hw_disk_bus=${hw_disk_bus=} --property hw_vif_model=${driver} --property hw_boot_menu=true --property hw_qemu_guest_agent=no"
    fi


    queued=$(openstack image list -f json| jq -r ".[]| select(.Status | contains(\"queued\"))| select(.Name | contains(\"${image_name}\")).ID")
    if [ ! "${queued}" = "" ]; then
        echo "Upload already queued. Cleaning them up."
        openstack image delete ${queued}
        exit 1
    fi

    openstack image create --progress --disk-format qcow2 --file ${local_copy} --property hw_qemu_guest_agent=no ${property} ${image_name} --tag ${image_name}
}

function enable() {
    echo "enabling"
    image_to_use=$(openstack image list --status active --tag ${image_name} --format json --limit 1|jq -r .[0].ID)
    current_name=$(openstack image show ${image_to_use} --format json| jq -r .name)
    if [ ! ${current_name} = ${final_name} ]; then
        echo "Rotating images"
        openstack image set ${final_name} --name ${final_name}-old || true
        openstack image set ${image_to_use} --name ${final_name}
    fi
}


OS_CLOUD=vexxhost OS_REGION_NAME=ams1 upload
OS_CLOUD=vexxhost OS_REGION_NAME=ca-ymq-1 upload
#OS_CLOUD=vexxhost OS_REGION_NAME=sjc1 upload
# Note: VMware images don't work on Limestone, the VCSA is too large and the ESXi 7.0.3 won't boot because there is no e1000e driver.
# [>                             ] 0%HttpException: 413: Client Error for url: https://api.us-slc.cloud.lstn.net:9292/v2/images/e7dc5593-d21f-4c86-a63d-2158e7bd19c7/file, Request Entity Too Large
#OS_CLOUD=limestone OS_REGION_NAME=us-slc upload
#OS_CLOUD=limestone OS_REGION_NAME=us-dfw-1 upload

OS_CLOUD=vexxhost OS_REGION_NAME=ams1 enable
OS_CLOUD=vexxhost OS_REGION_NAME=ca-ymq-1 enable
#OS_CLOUD=vexxhost OS_REGION_NAME=sjc1 enable
#OS_CLOUD=limestone OS_REGION_NAME=us-slc enable
#OS_CLOUD=limestone OS_REGION_NAME=us-dfw-1 enable
