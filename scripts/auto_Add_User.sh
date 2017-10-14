#!/bin/bash 
#######################################################################
#                       AUTO ADD NORMAL USER                          #
#######################################################################

## Variables
# Some global variables
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_LIB_DIR="${PROJECT_ROOT_DIR}/lib"
PROJECT_ETC_DIR="${PROJECT_ROOT_DIR}/etc"
YAML_INTERPRETER="${PROJECT_LIB_DIR}/yaml_interpreter.py"
SEND_MAIL_SCRIPT="${SCRIPT_DIR}/send_mail.sh"
CLUSTER_CONFIG_FILE="${PROJECT_ETC_DIR}/cluster.yaml"
USER_LIST_FILE="${PROJECT_ETC_DIR}/userList"
# Net work interface for log in.
InternetInterface="$(python ${YAML_INTERPRETER} ${CLUSTER_CONFIG_FILE} InternetInterface)"
LogInIPaddress=`ifconfig | grep ${InternetInterface} -A1 | awk '/inet/{print $2}'`
# Normal user limits
LimitConfigFile="$(python ${YAML_INTERPRETER} ${CLUSTER_CONFIG_FILE} LimitConfigFile)"
QuotaSoft="$(python ${YAML_INTERPRETER} ${CLUSTER_CONFIG_FILE} QuotaSoft)"
QuotaHard="$(python ${YAML_INTERPRETER} ${CLUSTER_CONFIG_FILE} QuotaHard)"
LimitRAM="$(python ${YAML_INTERPRETER} ${CLUSTER_CONFIG_FILE} LimitRAM)"
SlurmDefaultAccount="$(python ${YAML_INTERPRETER} ${CLUSTER_CONFIG_FILE}  SlurmDefaultAccount)"
## Functions
# Add a normal user and config its resources
AddNormalUser(){
    # local variable
    local username=$1
    local useremail=$2
    local password=${username}
    # print some information
	echo -e "\nUser ${username} will be added to the system...\n"
    # create a normal account
    adduser ${username}
    # add password
    echo ${password} | passwd --stdin ${username}
    # let user changes his password when the first login
    usermod -L ${username}
    chage -d 0 ${username}
    usermod -U ${username}

    # limit the hard disk space for the normal user
    quotacommand="xfs_quota -x -c \"limit -u bsoft=${QuotaSoft} bhard=${QuotaHard} ${username}\" /home"
    eval $quotacommand
    # limit other resources
    # limit virtual memory 4G/user
    if [[ -e /etc/security/limits.d/${LimitConfigFile} ]]; then
        echo -e "${username}     hard   as     ${LimitRAM}" >> /etc/security/limits.d/${LimitConfigFile}
    else
        touch /etc/security/limits.d/${LimitConfigFile}
        echo -e "${username}     hard   as     ${LimitRAM}" >> /etc/security/limits.d/${LimitConfigFile}
    fi
    # add user to the slurm accounting database
    sacctmgr add user name=${username} DefaultAccount=${SlurmDefaultAccount}
    # add user and email address to userlist file
    echo -e "${username} ${useremail}" >> ${USER_LIST_FILE}
    # generate informations of the new user
    printf -v new_user_info "Dear ${username}\nUser ${username}(Email: ${useremail}) has been added to the system! The initial password is ${username}. The login address is ${LogInIPaddress}.\n Enjoy it!"
    # send an email to the new user
    bash ${SEND_MAIL_SCRIPT} "${useremail}" "${new_user_info}" "You have been added to the system!"
}


## Program begin
# If the input variable is a file, create every users in the file. If not, create a user whose user name is the input variable  
if [[ -f $1 ]]; then
    usernamefile='./$1'
    while IFS=" " read -ra userinfo
    do
        username=${userinfo[0]}
        useremail=${userinfo[1]}
        AddNormalUser $username $useremail
    done < "${usernamefile}"
else
    AddNormalUser $1 $2
fi
# Synchronize the related files to all compute nodes
wwsh file resync passwd shadow group
# Print some information
echo -e "\nAll users have been added to the system!"
