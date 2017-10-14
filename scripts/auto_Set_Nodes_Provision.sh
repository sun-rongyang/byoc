#!/bin/bash
#######################################################################
#                     SET NODES PROVISION SCRIPT                      #
#######################################################################

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
ETH_INTERFACE="$(python ${YAML_INTERPRETER} ${NODES_CONFIG_FILE} ETH_INTERFACE)"


## Functions
# Add a node to warewurf system
# usage: AddNode hostname mac ip files eth_interface_name
AddNode(){

    # local variables
    local node_hostname="$1"
    local node_mac="$2"
    local node_ip="$3"
    local node_files="$4"
    local node_eth_interface="$5"

    # print some information
    echo -e "\nCompute node ${node_hostname} will be added to the provision system!\n"
    # add node
    wwsh -y node new "${node_hostname}" --ipaddr="${node_ip}" --hwaddr="${node_mac}" -D "${node_eth_interface}"
    wwsh -y provision set "${node_hostname}" --kargs "net.ifnames=1,biosdevname=1" --postnetdown=1 --vnfs=centos7.3 --bootstrap=`uname -r` --files="${node_files}"
    wwsh node print "${node_hostname}"
    # wait 3s
    sleep 3s
    # print some information
    echo -e "\nCompute node ${node_hostname} has been added to the provision system!\n"
}

## Program begin
# Import network interface name to warewurf system
# create a temporary file
echo "GATEWAYDEV=${ETH_INTERFACE}" > /tmp/network.$$
# import to warewurf system
wwsh file import /tmp/network.$$ --name network_interface
wwsh file set network_interface --path /etc/sysconfig/network --mode=0644 --uid=0
# wait 10s
sleep 10s

# Set nodes provision
# set files need to be imported
files_imported="dynamic_hosts,passwd,group,shadow,slurm.conf,munge.key,network_interface,path_config"
# Add nodes to provision system
while IFS=" " read -ra node_info
do
    hostname="${node_info[0]}"
    mac="${node_info[1]}"
    ip="${node_info[2]}"
    files="${node_info[3]}"
    AddNode "${hostname}" "${mac}" "${ip}" "${files}" "${ETH_INTERFACE}"
done < "${NODES_INFO_FILE}"

# Print some information
echo -e "\nAll nods have been added to the provision system!\n"
exit
