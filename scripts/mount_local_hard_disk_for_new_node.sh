#!/bin/bash
#######################################################################
#                 MOUNT LOCAL HARD DISK FOR NEW NODES                 #
#######################################################################
# usage: mount_local_hard_disk_for_new_node.sh node
# else: mount_local_hard_disk_for_new_node.sh node_prefix[number_begin-number_end]

## Variables
# Some global variables
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_LIB_DIR="${PROJECT_ROOT_DIR}/lib"
PROJECT_ETC_DIR="${PROJECT_ROOT_DIR}/etc"
YAML_INTERPRETER="${PROJECT_LIB_DIR}/yaml_interpreter.py"
CLUSTER_CONFIG_FILE="${PROJECT_ETC_DIR}/cluster.yaml"
NODES_CONFIG_FILE="${PROJECT_ETC_DIR}/computeNodes.yaml"
NODES_INFO_FILE="${PROJECT_ETC_DIR}/$(python ${YAML_INTERPRETER} ${NODES_CONFIG_FILE} NODES_INFO_FILE)"
ARGUMENT="$1"

## Functions
# format local hard disk and mount to /tmp/localharddisk
# usage: FormatMountLocalHD $node_hostname
FormatMountLocalHD(){

local node="$1"

# print some information
echo -e "\nFormat and mount local hard disk for ${node} begin...\n"
# ssh to the node
ssh root@"${node}" 2>&1 << script_text

#print the node name
hostname

#rewrite the partition table
echo ';' | sfdisk /dev/sda

#make file system on the new partition
mkfs.ext4 /dev/sda1

#creat the local harddisk mount port
mkdir /tmp/localharddisk

#mount the local harddisk
mount /dev/sda1 /tmp/localharddisk/

#test the mount
df -h | grep /tmp/localharddisk
exit

script_text

}

# treat ARGUMENT
if [[ "${ARGUMENT}" == *"["* ]]; then
    IFS="[" read -ra argument_tmp <<< "${ARGUMENT}"
    node_prefix="${argument_tmp[0]}"
    argument_tmp_1="${argument_tmp[1]}"
    IFS="-" read -ra argument_tmp_2 <<< "${argument_tmp_1}"
    node_begin_number="${argument_tmp_2[0]}"
    node_end_number="$(echo ${argument_tmp_2[1]} | sed 's/]//g')"
    for i in $(seq $node_begin_number 1 $node_end_number); do
        FormatMountLocalHD "${node_prefix}$i"
    done
else
    node="${ARGUMENT}"
    FormatMountLocalHD "${node}"
fi
